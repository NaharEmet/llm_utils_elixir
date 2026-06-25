defmodule LLMUtils.Logging do
  @moduledoc """
  Toggleable structured logger for LLM calls.

  ## Usage

      LLMUtils.Logging.enable()
      LLMUtils.Logging.log(:info, "message", provider: "openai")
      LLMUtils.Logging.disable()

  Override by passing a module with the same interface in Client options.

  Note: Call `require LLMUtils.Logging` before using `log/3` in modules
  that don't already `require Logger`.
  """

  require Logger

  @doc "Enable logging."
  @spec enable() :: :ok
  def enable do
    set_enabled(true)
  end

  @doc "Disable logging."
  @spec disable() :: :ok
  def disable do
    set_enabled(false)
  end

  @doc "Check if logging is enabled."
  @spec enabled?() :: boolean()
  def enabled? do
    :persistent_term.get(:llm_logging_enabled, false) == true
  end

  @doc "Log a message if logging is enabled."
  @spec log(Logger.level(), String.t(), keyword()) :: :ok
  def log(level, message, metadata \\ [])

  def log(level, message, metadata) do
    if enabled?() do
      Logger.log(level, "[LLMUtils] #{message}", metadata)
    end

    :ok
  end

  defp set_enabled(val) do
    :persistent_term.put(:llm_logging_enabled, val)
  end
end
