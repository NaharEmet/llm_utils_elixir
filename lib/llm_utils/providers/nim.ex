defmodule LLMUtils.Providers.NIM do
  @moduledoc """
  Provider implementation for NVIDIA NIM API.

  Note: NIM does not support system role. System messages are converted
  to user messages by the client.
  """
  @behaviour LLMUtils.Provider

  @impl true
  def config do
    %{
      id: "nim",
      name: "NVIDIA NIM",
      base_url: "https://integrate.api.nvidia.com/v1",
      default_model: "meta/llama-3.3-70b-instruct",
      auth_type: :bearer,
      api_key_env: "NIM_API_KEY",
      supports_json_mode: true,
      supports_system_role: false,
      rate_limit: 40,
      rate_window_ms: 60_000,
      models: ["meta/llama-3.3-70b-instruct"],
      suppress_thinking: false
    }
  end

  @impl true
  def api_key, do: LLMUtils.Provider.get_api_key("nim")

  @impl true
  def headers(api_key), do: LLMUtils.Provider.auth_headers(:bearer, api_key)

  @impl true
  def handle_response(response), do: {:ok, response}

  @impl true
  def supports_system_role?, do: false
end
