defmodule LLMUtils.Providers.OpenAI do
  @moduledoc """
  Provider implementation for OpenAI API.
  """
  @behaviour LLMUtils.Provider

  @impl true
  def config do
    %{
      id: "openai",
      name: "OpenAI",
      base_url: "https://api.openai.com/v1",
      default_model: "gpt-4o",
      auth_type: :bearer,
      api_key_env: "OPENAI_API_KEY",
      supports_json_mode: true,
      supports_system_role: true,
      rate_limit: nil,
      rate_window_ms: 60_000,
      models: ["gpt-4o", "gpt-4o-mini", "gpt-4-turbo"],
      suppress_thinking: false
    }
  end

  @impl true
  def api_key, do: LLMUtils.Provider.get_api_key("openai")

  @impl true
  def headers(api_key), do: LLMUtils.Provider.auth_headers(:bearer, api_key)

  @impl true
  def handle_response(response), do: {:ok, response}

  @impl true
  def supports_system_role?, do: true
end
