defmodule LLMUtils.RateLimiter do
  @moduledoc """
  In-memory ETS-based sliding window rate limiter.

  ## Usage

      LLMUtils.RateLimiter.check("nim", 40, 60_000)
      # => :ok | :rate_limited

  Override by passing a module implementing `check/3` in Client options.
  """

  @doc """
  Check if a request is within rate limits.

  - `provider_id` — Provider identifier (used as ETS table name)
  - `max_requests` — Maximum number of requests in the window
  - `window_ms` — Window duration in milliseconds

  Returns `:ok` if under limit, `:rate_limited` if at/over limit.
  """
  @spec check(String.t(), non_neg_integer(), pos_integer()) :: :ok | :rate_limited
  def check(provider_id, max_requests, window_ms) do
    table_name = :"#{provider_id}_rate_tracker"
    ensure_table(table_name)

    now = System.monotonic_time(:millisecond)
    cutoff = now - window_ms

    :ets.select_delete(table_name, [{{:_, :"$1"}, [{:<, :"$1", cutoff}], [true]}])

    timestamps = :ets.select(table_name, [{{:_, :"$1"}, [{:>, :"$1", cutoff}], [:"$1"]}])

    if length(timestamps) >= max_requests do
      :rate_limited
    else
      :ets.insert(table_name, {make_ref(), now})
      :ok
    end
  end

  @doc "Reset rate limiter state for a provider."
  @spec reset(String.t()) :: :ok
  def reset(provider_id) do
    table_name = :"#{provider_id}_rate_tracker"

    if :ets.info(table_name, :name) != :undefined do
      :ets.delete_all_objects(table_name)
    end

    :ok
  end

  defp ensure_table(table_name) do
    case :ets.info(table_name, :name) do
      :undefined ->
        try do
          :ets.new(table_name, [:set, :public, :named_table])
        rescue
          ArgumentError -> :ok
        end

      _ ->
        :ok
    end
  end
end
