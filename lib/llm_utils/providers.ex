defmodule LLMUtils.Providers do
  @moduledoc """
  Registry of all supported LLM providers.

  Provides functions to list, look up, and verify provider configurations.
  All provider modules implement `LLMUtils.Provider` behaviour.
  """

  @provider_modules [
    LLMUtils.Providers.OpenAI,
    LLMUtils.Providers.Grok,
    LLMUtils.Providers.Sarvam,
    LLMUtils.Providers.Groq,
    LLMUtils.Providers.Fireworks,
    LLMUtils.Providers.NIM,
    LLMUtils.Providers.Minimax,
    LLMUtils.Providers.Mimo,
    LLMUtils.Providers.Mock
  ]

  @doc "List all provider configs."
  def all, do: Enum.map(@provider_modules, & &1.config())

  @doc "Get a provider config by string ID (e.g. \"openai\"). Returns nil if not found."
  def get(id) do
    Enum.find(all(), fn p -> p.id == id end)
  end

  @doc "Get the provider module by string ID."
  def get_module(id) do
    Enum.find(@provider_modules, fn mod -> mod.config().id == id end)
  end

  @doc "List all provider IDs."
  def ids, do: Enum.map(all(), & &1.id)

  @doc "Check if a provider ID exists."
  def exists?(id), do: get(id) != nil
end
