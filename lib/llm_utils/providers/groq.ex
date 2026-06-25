defmodule LLMUtils.Providers.Groq do
  @moduledoc """
  Provider implementation for Groq API.
  """
  @behaviour LLMUtils.Provider

  @impl true
  def config do
    %{
      id: "groq",
      name: "Groq",
      base_url: "https://api.groq.com/openai/v1",
      default_model: "llama-3.3-70b-versatile",
      auth_type: :bearer,
      api_key_env: "GROQ_API_KEY",
      supports_json_mode: true,
      supports_system_role: true,
      rate_limit: nil,
      rate_window_ms: 60_000,
      models: ["llama-3.3-70b-versatile", "llama-3.1-70b-versatile"],
      suppress_thinking: false
    }
  end

  @impl true
  def api_key, do: LLMUtils.Provider.get_api_key("groq")

  @impl true
  def headers(api_key), do: LLMUtils.Provider.auth_headers(:bearer, api_key)

  @impl true
  def handle_response(response), do: {:ok, response}

  @impl true
  def supports_system_role?, do: true
end
