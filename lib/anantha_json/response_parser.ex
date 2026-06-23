defmodule AnanthaJson.ResponseParser do
  @moduledoc """
  Single entry point for all LLM JSON parsing.

  Uses `JsonRemedy.repair/1` as the **only** decoding path. It handles:
  - Markdown code fence extraction (```json, ```, etc.)
  - Malformed JSON repair (unquoted keys, single quotes, trailing commas)
  - Plain text detection
  - Structural repair (missing braces, brackets)
  - Concatenated JSON detection (multiple JSON objects merged together)
  """

  alias AnanthaJson.JsonExtractor

  # ────────────────────────────────────
  #  PUBLIC API
  # ────────────────────────────────────

  @doc """
  Parses LLM response content and returns the first complete JSON object.

  Handles markdown wrapping, plain JSON, and concatenated JSON.
  Returns `{:ok, map}` for valid JSON objects, or `{:error, atom}` on failure.
  """
  @spec parse(String.t()) :: {:ok, map()} | {:error, atom()}
  def parse(""), do: {:error, :empty_content}

  def parse(content) when is_binary(content) do
    case JsonRemedy.repair(content) do
      {:ok, result} when is_map(result) ->
        {:ok, result}

      {:ok, list} when is_list(list) ->
        case List.last(list) do
          %{} = last_map -> {:ok, last_map}
          _ -> {:error, :no_json_found}
        end

      {:ok, _} ->
        {:error, :no_json_found}

      {:error, _reason} ->
        {:error, :no_json_found}
    end
  end

  def parse(_), do: {:error, :invalid_content}

  @doc """
  Parses LLM response and extracts a specific key value.
  """
  @spec parse_and_extract(String.t(), String.t()) :: {:ok, any()} | {:error, atom()}
  def parse_and_extract(content, key) when is_binary(content) and is_binary(key) do
    case parse(content) do
      {:ok, map} -> {:ok, Map.get(map, key)}
      {:error, _} = err -> err
    end
  end

  def parse_and_extract(_content, _key), do: {:error, :invalid_content}

  @doc """
  Parses LLM response and returns a decoded JSON array.

  Uses `JsonRemedy.repair/1` to decode the content. If the result is a list,
  returns it as `{:ok, list}`. Otherwise returns `{:error, :not_an_array}`.
  """
  @spec parse_array(String.t()) :: {:ok, list()} | {:error, atom()}
  def parse_array(content) when is_binary(content) do
    case JsonRemedy.repair(content) do
      {:ok, list} when is_list(list) -> {:ok, list}
      _ -> {:error, :not_an_array}
    end
  end

  def parse_array(_), do: {:error, :invalid_content}

  @doc """
  Parses LLM content with relaxed JSON handling.

  Uses `JsonRemedy.repair/1` which handles unquoted keys, single quotes,
  trailing commas, and other common LLM output issues natively.
  Returns `{:ok, result}` for any valid parsed result (map or list).
  """
  @spec parse_relaxed(String.t()) :: {:ok, map() | list()} | {:error, atom()}
  def parse_relaxed(content) when is_binary(content) do
    case JsonRemedy.repair(content) do
      {:ok, result} when is_map(result) or is_list(result) ->
        {:ok, result}

      {:ok, _} ->
        {:error, :no_json_found}

      {:error, _reason} ->
        {:error, :no_json_found}
    end
  end

  def parse_relaxed(_), do: {:error, :invalid_content}

  @doc """
  Finds the first JSON object in content that contains the specified key.

  Uses `JsonExtractor.extract_all_objects/1` to locate all JSON strings within
  the content, decodes each one with `JsonRemedy.repair/1`, and returns the
  first decoded object that contains the given key.
  """
  @spec parse_first_with_key(String.t(), String.t()) :: {:ok, map()} | {:error, atom()}
  def parse_first_with_key(content, key) when is_binary(content) and is_binary(key) do
    content
    |> JsonExtractor.extract_all_objects()
    |> Enum.reduce_while(:not_found, fn json_str, _acc ->
      case JsonRemedy.repair(json_str) do
        {:ok, %{} = map} ->
          if Map.has_key?(map, key), do: {:halt, {:ok, map}}, else: {:cont, :not_found}

        _ ->
          {:cont, :not_found}
      end
    end)
    |> case do
      {:ok, _} = result -> result
      :not_found -> {:error, :key_not_found}
    end
  end

  def parse_first_with_key(_content, _key), do: {:error, :invalid_content}
end
