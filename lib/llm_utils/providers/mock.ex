defmodule LLMUtils.Providers.Mock do
  @moduledoc """
  Mock provider for testing purposes.

  Uses no authentication and connects to localhost.
  JSON mode is disabled since mock responses are predefined.
  """
  @behaviour LLMUtils.Provider

  @impl true
  def config do
    %{
      id: "mock",
      name: "Mock",
      base_url: "http://localhost:4000/mock",
      default_model: "mock",
      auth_type: :none,
      api_key_env: "LLM_API_KEY",
      supports_json_mode: false,
      supports_system_role: true,
      rate_limit: nil,
      rate_window_ms: 60_000,
      models: ["mock"],
      suppress_thinking: false
    }
  end

  @impl true
  def api_key, do: LLMUtils.Provider.get_api_key("mock")

  @impl true
  def headers(_api_key), do: []

  @impl true
  def handle_response(response), do: {:ok, response}

  @impl true
  def supports_system_role?, do: true
end
