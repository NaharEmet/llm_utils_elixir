defmodule LLMUtils.Providers.Minimax do
  @moduledoc """
  Provider implementation for MiniMax API.

  Rate limited to 40 requests/minute.
  """
  @behaviour LLMUtils.Provider

  @impl true
  def config do
    %{
      id: "minimax",
      name: "MiniMax",
      base_url: "https://api.minimax.io/v1",
      default_model: "minimax-m2.7",
      auth_type: :bearer,
      api_key_env: "MINIMAX_API_KEY",
      supports_json_mode: true,
      supports_system_role: true,
      rate_limit: 40,
      rate_window_ms: 60_000,
      models: ["minimax-m2.7"],
      suppress_thinking: false
    }
  end

  @impl true
  def api_key, do: LLMUtils.Provider.get_api_key("minimax")

  @impl true
  def headers(api_key), do: LLMUtils.Provider.auth_headers(:bearer, api_key)

  @impl true
  def handle_response(response), do: {:ok, response}

  @impl true
  def supports_system_role?, do: true
end
