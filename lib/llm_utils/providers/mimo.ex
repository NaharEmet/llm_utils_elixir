defmodule LLMUtils.Providers.Mimo do
  @moduledoc """
  Provider implementation for Xiaomi Mimo API.

  Rate limited to 100 requests/minute and suppresses thinking/reasoning by default.
  """
  @behaviour LLMUtils.Provider

  @impl true
  def config do
    %{
      id: "mimo",
      name: "Xiaomi Mimo",
      base_url: "https://token-plan-sgp.xiaomimimo.com/v1",
      default_model: "mimo-v2.5",
      auth_type: :bearer,
      api_key_env: "MIMO_API_KEY",
      supports_json_mode: true,
      supports_system_role: true,
      rate_limit: 100,
      rate_window_ms: 60_000,
      models: ["mimo-v2.5", "mimo-v2.5-pro", "mimo-v2-omni"],
      suppress_thinking: true
    }
  end

  @impl true
  def api_key, do: LLMUtils.Provider.get_api_key("mimo")

  @impl true
  def headers(api_key), do: LLMUtils.Provider.auth_headers(:bearer, api_key)

  @impl true
  def handle_response(response), do: {:ok, response}

  @impl true
  def supports_system_role?, do: true
end
