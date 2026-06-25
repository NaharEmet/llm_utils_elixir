defmodule LLMUtils.Metrics do
  @moduledoc """
  In-memory ETS-based metrics collector for LLM calls.

  ## Usage

      LLMUtils.Metrics.record(%{provider: "openai", tokens_in: 100, ...})
      LLMUtils.Metrics.get_stats("openai")

  Override by passing a module implementing `record/1` and `get_stats/1` in Client options.
  """

  @doc "Record a call metric."
  @spec record(map()) :: :ok
  def record(metrics) when is_map(metrics) do
    ensure_table()
    :ets.insert(:llm_metrics_table, {make_ref(), System.monotonic_time(:millisecond), metrics})
    :ok
  end

  @doc "Get aggregated stats for a provider."
  @spec get_stats(String.t()) :: map()
  def get_stats(provider_id) do
    ensure_table()

    all_metrics =
      :ets.select(:llm_metrics_table, [{{:_, :"$1", :"$2"}, [], [{{:"$1", :"$2"}}]}])

    provider_metrics = Enum.filter(all_metrics, fn {_ts, m} -> m[:provider] == provider_id end)

    total_calls = length(provider_metrics)
    total_tokens = Enum.reduce(provider_metrics, 0, fn {_ts, m}, acc -> acc + (m[:total_tokens] || 0) end)
    success_count = Enum.count(provider_metrics, fn {_ts, m} -> m[:status] == "success" end)
    error_count = Enum.count(provider_metrics, fn {_ts, m} -> m[:status] == "error" end)

    avg_latency =
      if total_calls > 0 do
        total_latency = Enum.reduce(provider_metrics, 0, fn {_ts, m}, acc -> acc + (m[:latency_ms] || 0) end)
        div(total_latency, total_calls)
      else
        0
      end

    %{
      provider: provider_id,
      total_calls: total_calls,
      success_count: success_count,
      error_count: error_count,
      total_tokens: total_tokens,
      avg_latency_ms: avg_latency
    }
  end

  @doc "Reset all metrics."
  @spec reset() :: :ok
  def reset do
    if :ets.info(:llm_metrics_table, :name) != :undefined do
      :ets.delete_all_objects(:llm_metrics_table)
    end

    :ok
  end

  defp ensure_table do
    case :ets.info(:llm_metrics_table, :name) do
      :undefined ->
        try do
          :ets.new(:llm_metrics_table, [:set, :public, :named_table])
        rescue
          ArgumentError -> :ok
        end

      _ ->
        :ok
    end
  end
end
