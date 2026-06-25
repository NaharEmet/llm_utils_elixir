defmodule LLMUtils.Provider do
  @moduledoc """
  Behaviour for LLM provider implementations.

  Provider modules define config, API key resolution, headers, response handling,
  and capabilities.
  """

  @type config :: %{
    id: String.t(),
    name: String.t(),
    base_url: String.t(),
    default_model: String.t(),
    auth_type: :bearer | :subscription_key | :none,
    api_key_env: String.t(),
    supports_json_mode: boolean(),
    supports_system_role: boolean(),
    rate_limit: non_neg_integer() | nil,
    rate_window_ms: pos_integer(),
    models: [String.t()],
    suppress_thinking: boolean()
  }

  @callback config() :: config()
  @callback api_key() :: String.t() | nil
  @callback headers(String.t()) :: [{String.t(), String.t()}]
  @callback handle_response(map()) :: {:ok, map()} | {:error, atom()}
  @callback supports_system_role?() :: boolean()

  @doc """
  Build auth headers based on auth type.
  """
  def auth_headers(:bearer, key), do: [{"authorization", "Bearer #{key}"}]
  def auth_headers(:subscription_key, key), do: [{"api-subscription-key", key}]
  def auth_headers(_, _), do: []

  @doc """
  Resolve API key from environment for a provider.
  Falls back to `LLM_API_KEY` if provider-specific env var not set.
  """
  def get_api_key(provider_id) do
    env_var = get_provider_env(provider_id)
    System.get_env(env_var) || System.get_env("LLM_API_KEY")
  end

  defp get_provider_env("openai"), do: "OPENAI_API_KEY"
  defp get_provider_env("grok"), do: "GROK_API_KEY"
  defp get_provider_env("sarvam"), do: "SARVAM_API_KEY"
  defp get_provider_env("groq"), do: "GROQ_API_KEY"
  defp get_provider_env("fireworks"), do: "FIREWORKS_API_KEY"
  defp get_provider_env("nim"), do: "NIM_API_KEY"
  defp get_provider_env("minimax"), do: "MINIMAX_API_KEY"
  defp get_provider_env("mimo"), do: "MIMO_API_KEY"
  defp get_provider_env(_), do: "LLM_API_KEY"
end
