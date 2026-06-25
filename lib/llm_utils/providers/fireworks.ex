defmodule LLMUtils.Providers.Fireworks do
  @moduledoc """
  Provider implementation for Fireworks AI API.

  Note: Fireworks does not support `response_format: %{type: "json_object"}`.
  JSON mode should be disabled for this provider.
  """
  @behaviour LLMUtils.Provider

  @impl true
  def config do
    %{
      id: "fireworks",
      name: "Fireworks AI",
      base_url: "https://api.fireworks.ai/inference/v1",
      default_model: "accounts/fireworks/models/llama-v3p3-70b-instruct",
      auth_type: :bearer,
      api_key_env: "FIREWORKS_API_KEY",
      supports_json_mode: false,
      supports_system_role: true,
      rate_limit: nil,
      rate_window_ms: 60_000,
      models: ["accounts/fireworks/models/llama-v3p3-70b-instruct"],
      suppress_thinking: false
    }
  end

  @impl true
  def api_key, do: LLMUtils.Provider.get_api_key("fireworks")

  @impl true
  def headers(api_key), do: LLMUtils.Provider.auth_headers(:bearer, api_key)

  @impl true
  def handle_response(response), do: {:ok, response}

  @impl true
  def supports_system_role?, do: true
end
