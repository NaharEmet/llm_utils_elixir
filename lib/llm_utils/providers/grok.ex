defmodule LLMUtils.Providers.Grok do
  @moduledoc """
  Provider implementation for xAI Grok API.
  """
  @behaviour LLMUtils.Provider

  @impl true
  def config do
    %{
      id: "grok",
      name: "xAI Grok",
      base_url: "https://api.x.ai/v1",
      default_model: "grok-2",
      auth_type: :bearer,
      api_key_env: "GROK_API_KEY",
      supports_json_mode: true,
      supports_system_role: true,
      rate_limit: nil,
      rate_window_ms: 60_000,
      models: ["grok-2"],
      suppress_thinking: false
    }
  end

  @impl true
  def api_key, do: LLMUtils.Provider.get_api_key("grok")

  @impl true
  def headers(api_key), do: LLMUtils.Provider.auth_headers(:bearer, api_key)

  @impl true
  def handle_response(response), do: {:ok, response}

  @impl true
  def supports_system_role?, do: true
end
