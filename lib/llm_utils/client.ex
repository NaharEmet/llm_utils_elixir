defmodule LLMUtils.Client do
  @moduledoc """
  Core LLM HTTP client for OpenAI-compatible chat completion APIs.

  Handles:
  - Provider config resolution (by string ID or config map)
  - API key resolution from env or override
  - Request body construction with model, messages, temperature, json_mode, tools
  - Rate limiting via `LLMUtils.RateLimiter` (configurable)
  - Circuit breaking via `LLMUtils.CircuitBreaker` (configurable)
  - HTTP execution via Req.post
  - Response normalization (content extraction, tool calls, error handling)
  - Provider-specific handling (thinking tags, system→user conversion, reasoning content)
  - Metrics collection via `LLMUtils.Metrics` (configurable)
  - Structured logging via `LLMUtils.Logging` (configurable)
  - Fallback to alternative providers on failure

  ## Override callbacks

  All stateful features use ETS-based defaults but can be overridden:

      LLMUtils.Client.chat_completion(messages, "openai",
        circuit_breaker: MyApp.CircuitBreaker,
        metrics_collector: MyApp.Metrics,
        rate_limiter: MyApp.RateLimiter,
        logger: MyApp.Logging
      )
  """

  alias LLMUtils.Provider
  alias LLMUtils.Providers

  require Logger

  @default_temperature 0.0

  @doc """
  Send a chat completion request.

  ## Parameters
  - `messages` — List of message maps with `role` and `content` keys
  - `provider` — Provider string ID (e.g. "openai") or a provider config map
  - `opts` — Keyword options

  ## Options
  - `:model` — Model override (default: provider's default_model)
  - `:api_key` — API key override (default: from env via `Provider.get_api_key/1`)
  - `:temperature` — Temperature override (default: 0.0)
  - `:json_mode` — Force JSON response format (default: from provider config)
  - `:tools` — List of tool definitions for function calling
  - `:timeout` — Request timeout in ms (default: 60_000)
  - `:max_tokens` — Max tokens in response (default: nil = no limit)
  - `:suppress_thinking` — Disable thinking/reasoning (default: from provider config)
  - `:fallback` — List of fallback provider IDs to try on failure
  - `:enable_circuit_breaker` — Enable circuit breaker (default: true)
  - `:enable_rate_limiter` — Enable rate limiting (default: true)
  - `:enable_metrics` — Enable metrics collection (default: true)
  - `:enable_logging` — Enable structured logging (default: false)
  - `:circuit_breaker` — Custom circuit breaker module (default: `LLMUtils.CircuitBreaker`)
  - `:metrics_collector` — Custom metrics module (default: `LLMUtils.Metrics`)
  - `:logger` — Custom logger module (default: `LLMUtils.Logging`)
  - `:rate_limiter` — Custom rate limiter module (default: `LLMUtils.RateLimiter`)

  ## Returns
  - `{:ok, %{content: String.t(), usage: %{...}}}`
  - `{:ok, %{tool_calls: [...]}}`
  - `{:error, {:rate_limited, msg, retry_after}}`
  - `{:error, {:unauthorized, msg}}`
  - `{:error, {:server_error, status, msg}}`
  - `{:error, {:client_error, status, msg}}`
  - `{:error, {:precondition_failed, msg}}`
  - `{:error, :missing_api_key}`
  - `{:error, :unknown_provider}`
  - `{:error, :empty_response}`
  - `{:error, :timeout}`
  - `{:error, :service_unavailable}`
  - `{:error, :circuit_open}`
  - `{:error, reason}` (catch-all)
  """
  @spec chat_completion(list(map()), String.t() | map(), keyword()) ::
    {:ok, map()} | {:error, term()}
  def chat_completion(messages, provider, opts \\ [])

  def chat_completion(messages, provider_id, opts) when is_binary(provider_id) do
    config = Providers.get(provider_id)

    if is_nil(config) do
      {:error, :unknown_provider}
    else
      do_chat_completion(messages, config, opts)
    end
  end

  def chat_completion(messages, %{} = config, opts) do
    do_chat_completion(messages, config, opts)
  end

  # ── Core execution ──────────────────────────────────────────────────────

  defp do_chat_completion(messages, config, opts) do
    api_key = resolve_api_key(config, opts)

    if is_nil(api_key) or api_key == "" do
      {:error, :missing_api_key}
    else
      rate_limiter = opts[:rate_limiter] || LLMUtils.RateLimiter
      enable_ratelimit = Keyword.get(opts, :enable_rate_limiter, true)

      rate_check =
        if enable_ratelimit and config.rate_limit do
          rate_limiter.check(config.id, config.rate_limit, config.rate_window_ms)
        else
          :ok
        end

      case rate_check do
        :rate_limited ->
          {:error, {:rate_limited, "Rate limit reached for #{config.id}", nil}}

        :ok ->
          circuit_breaker = opts[:circuit_breaker] || LLMUtils.CircuitBreaker
          circuit_name = :"llm_circuit_#{config.id}"
          enable_cb = Keyword.get(opts, :enable_circuit_breaker, true)

          call_fn = fn ->
            do_request(messages, config, api_key, opts)
          end

          result =
            if enable_cb do
              circuit_breaker.call(circuit_name, call_fn, timeout: opts[:timeout] || 60_000)
            else
              call_fn.()
            end

          metrics_collector = opts[:metrics_collector] || LLMUtils.Metrics
          enable_metrics = Keyword.get(opts, :enable_metrics, true)

          if enable_metrics do
            case result do
              {:ok, response} ->
                metrics_collector.record(%{
                  provider: config.id,
                  model: opts[:model] || config.default_model,
                  tokens_in: Map.get(response, :tokens_in, 0),
                  tokens_out: Map.get(response, :tokens_out, 0),
                  total_tokens: Map.get(response, :total_tokens, 0),
                  status: "success",
                  latency_ms: Map.get(response, :latency_ms, 0)
                })

              {:error, reason} ->
                metrics_collector.record(%{
                  provider: config.id,
                  model: opts[:model] || config.default_model,
                  tokens_in: 0,
                  tokens_out: 0,
                  total_tokens: 0,
                  status: "error",
                  error: reason
                })
            end
          end

          if match?({:error, _}, result) and opts[:fallback] do
            try_fallback(messages, config, opts, opts[:fallback], [{config.id, result}])
          else
            logger = opts[:logger] || LLMUtils.Logging
            enable_logging = Keyword.get(opts, :enable_logging, false)

            if enable_logging do
              logger.log(:info, "LLM call to #{config.id}/#{config.default_model}", result: result)
            end

            result
          end
      end
    end
  end

  # ── Request execution ────────────────────────────────────────────────────

  defp do_request(messages, config, api_key, opts) do
    model = opts[:model] || config.default_model
    base_url = opts[:base_url] || config.base_url
    headers = Provider.auth_headers(config.auth_type, api_key)
    timeout = opts[:timeout] || 60_000

    transformed =
      if config.supports_system_role do
        messages
      else
        transform_system_to_user(messages)
      end

    body = build_request_body(model, transformed, config, opts)

    http_start = System.monotonic_time(:millisecond)

    result =
      Req.post(
        url: "#{base_url}/chat/completions",
        headers: headers,
        json: body,
        receive_timeout: timeout,
        connect_options: [timeout: 10_000]
      )

    http_time = System.monotonic_time(:millisecond) - http_start

    case result do
      {:ok, response} ->
        handle_http_response(response, http_time)

      {:error, %{reason: :timeout}} ->
        {:error, :timeout}

      {:error, reason} ->
        {:error, {:api_error, inspect(reason)}}
    end
  end

  defp handle_http_response(%{status: _status} = response, http_time) do
    result =
      response
      |> handle_response()
      |> case do
        {:ok, parsed} ->
          usage = normalize_usage(response.body)
          {:ok, Map.merge(parsed, %{latency_ms: http_time, usage: usage})}

        error ->
          error
      end

    result
  end

  # ── Request body builder ─────────────────────────────────────────────────

  defp build_request_body(model, messages, config, opts) do
    json_mode = Keyword.get(opts, :json_mode, config.supports_json_mode)
    temperature = opts[:temperature] || @default_temperature

    body = %{
      model: model,
      messages: messages,
      temperature: temperature
    }

    body =
      if opts[:max_tokens] do
        Map.put(body, :max_tokens, opts[:max_tokens])
      else
        body
      end

    body =
      if Keyword.get(opts, :suppress_thinking, config[:suppress_thinking] || false) do
        Map.put(body, :thinking, %{type: "disabled"})
      else
        body
      end

    body =
      if json_mode do
        Map.put(body, :response_format, %{type: "json_object"})
      else
        body
      end

    if opts[:tools] do
      Map.put(body, :tools, opts[:tools])
    else
      body
    end
  end

  # ── Message transformation ──────────────────────────────────────────────

  defp transform_system_to_user(messages) when is_list(messages) do
    Enum.map(messages, fn
      %{"role" => "system"} = msg -> Map.put(msg, "role", "user")
      msg -> msg
    end)
  end

  # ── Response handling ────────────────────────────────────────────────────
  # Handles provider-specific response formats:
  # - Standard OpenAI: choices[].message.content
  # - Tool calls: choices[].message.tool_calls
  # - Text field: choices[].message.text (some providers)
  # - Reasoning: choices[].reasoning or message.reasoning_content

  defp handle_response(%{status: 200, body: body}) do
    choices = body["choices"] || body[:choices] || []

    case choices do
      [first_choice | _] when is_map(first_choice) ->
        handle_choice(first_choice)

      _ ->
        {:error, :no_choices}
    end
  end

  defp handle_response(%{status: 401, body: body}) do
    {:error, {:unauthorized, extract_error_message(body)}}
  end

  defp handle_response(%{status: 412, body: body}) do
    {:error, {:precondition_failed, extract_error_message(body)}}
  end

  defp handle_response(%{status: 429, body: body} = response) do
    retry_after = get_retry_after(response.headers)
    {:error, {:rate_limited, extract_error_message(body), retry_after}}
  end

  defp handle_response(%{status: status, body: body}) when status >= 500 do
    {:error, {:server_error, status, extract_error_message(body)}}
  end

  defp handle_response(%{status: status, body: body}) when status >= 400 do
    {:error, {:client_error, status, extract_error_message(body)}}
  end

  defp handle_response(response) do
    {:error, {:api_error, inspect(response)}}
  end

  defp handle_choice(choice) do
    message = choice["message"] || choice[:message] || %{}

    cond do
      has_tool_calls?(message) ->
        {:ok, %{tool_calls: parse_tool_calls(message["tool_calls"])}}

      content = message["content"] || message[:content] ->
        extract_and_parse_content(content)

      reasoning = message["reasoning_content"] || choice["reasoning"] || choice[:reasoning] ->
        extract_and_parse_content(reasoning)

      text = message["text"] || message[:text] ->
        extract_and_parse_content(text)

      true ->
        {:error, :empty_response}
    end
  end

  defp has_tool_calls?(%{"tool_calls" => calls}) when is_list(calls), do: true
  defp has_tool_calls?(%{tool_calls: calls}) when is_list(calls), do: true
  defp has_tool_calls?(_), do: false

  # ── Content extraction ───────────────────────────────────────────────────
  # 1. Strip <thinking>...</thinking> tags (used by reasoning models)
  # 2. Try to parse as JSON via ResponseParser
  # 3. If that fails, try raw JSON decode
  # 4. If that also fails, return raw trimmed content

  defp extract_and_parse_content(content) when is_binary(content) do
    cleaned = strip_thinking_tags(content)

    case LLMUtils.ResponseParser.parse(cleaned) do
      {:ok, decoded} ->
        {:ok, %{content: decoded}}

      {:error, _} ->
        case Jason.decode(cleaned) do
          {:ok, decoded} -> {:ok, %{content: decoded}}
          {:error, _} -> {:ok, %{content: String.trim(cleaned)}}
        end
    end
  end

  defp extract_and_parse_content(_), do: {:error, :empty_response}

  defp strip_thinking_tags(content) do
    content
    |> String.replace(~r/<thinking>[\s\S]*?<\/thinking>/i, "")
    |> String.trim()
  end

  # ── Error message extraction ─────────────────────────────────────────────

  defp extract_error_message(%{"error" => %{"message" => msg}}) when is_binary(msg), do: msg
  defp extract_error_message(%{error: %{message: msg}}) when is_binary(msg), do: msg
  defp extract_error_message(body) when is_map(body), do: inspect(body)
  defp extract_error_message(body), do: inspect(body)

  # ── Token usage normalization ────────────────────────────────────────────

  defp normalize_usage(body) do
    usage = body["usage"] || body[:usage] || %{}

    tokens_in = usage["prompt_tokens"] || usage["input_tokens"] || 0
    tokens_out = usage["completion_tokens"] || usage["output_tokens"] || 0
    total = usage["total_tokens"] || tokens_in + tokens_out

    %{
      tokens_in: tokens_in,
      tokens_out: tokens_out,
      total_tokens: total,
      prompt_tokens: tokens_in,
      completion_tokens: tokens_out
    }
  end

  # ── Tool call parsing ────────────────────────────────────────────────────

  defp parse_tool_calls(tool_calls) when is_list(tool_calls) do
    tool_calls
    |> Enum.map(&parse_single_tool_call/1)
    |> Enum.reject(&is_nil/1)
  end

  defp parse_single_tool_call(%{"function" => %{"name" => name, "arguments" => args}})
       when is_binary(args) do
    case Jason.decode(args) do
      {:ok, parsed_args} -> %{"tool" => name, "args" => parsed_args}
      {:error, _} -> nil
    end
  end

  defp parse_single_tool_call(%{"function" => %{"name" => name, "arguments" => args}})
       when is_map(args) do
    %{"tool" => name, "args" => args}
  end

  defp parse_single_tool_call(_), do: nil

  # ── Retry-After header extraction ────────────────────────────────────────

  defp get_retry_after(headers) when is_list(headers) do
    case List.keyfind(headers, "retry-after", 0) do
      {_, value} ->
        case Integer.parse(value) do
          {n, _} -> n
          :error -> nil
        end

      nil -> nil
    end
  end

  defp get_retry_after(_), do: nil

  # ── API key resolution ──────────────────────────────────────────────────

  defp resolve_api_key(config, opts) do
    opts[:api_key] || config[:api_key] || Provider.get_api_key(config.id)
  end

  # ── Fallback handling ────────────────────────────────────────────────────

  defp try_fallback(_messages, _config, _opts, [], errors) do
    {:error, {:all_providers_failed, errors}}
  end

  defp try_fallback(messages, original_config, opts, [fallback_id | rest], errors) do
    case Providers.get(fallback_id) do
      nil ->
        try_fallback(messages, original_config, opts, rest, [{fallback_id, :unknown_provider} | errors])

      fallback_config ->
        case do_chat_completion(messages, fallback_config, opts) do
          {:ok, _} = success -> success
          {:error, reason} -> try_fallback(messages, original_config, opts, rest, [{fallback_id, reason} | errors])
        end
    end
  end
end
