defmodule LLMUtils.Providers.Sarvam do
  @moduledoc """
  Provider implementation for Sarvam AI API.

  Uses subscription key authentication instead of bearer token.
  """
  @behaviour LLMUtils.Provider

  @impl true
  def config do
    %{
      id: "sarvam",
      name: "Sarvam AI",
      base_url: "https://api.sarvam.ai/v1",
      default_model: "sarvam-30b",
      auth_type: :subscription_key,
      api_key_env: "SARVAM_API_KEY",
      supports_json_mode: true,
      supports_system_role: true,
      rate_limit: nil,
      rate_window_ms: 60_000,
      models: ["sarvam-30b"],
      suppress_thinking: false
    }
  end

  @impl true
  def api_key, do: LLMUtils.Provider.get_api_key("sarvam")

  @impl true
  def headers(api_key), do: LLMUtils.Provider.auth_headers(:subscription_key, api_key)

  @impl true
  def handle_response(response), do: {:ok, response}

  @impl true
  def supports_system_role?, do: true
end
