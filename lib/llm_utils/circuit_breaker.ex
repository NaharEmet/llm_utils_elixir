defmodule LLMUtils.CircuitBreaker do
  @moduledoc """
  In-memory ETS-based 3-state circuit breaker.

  States: closed → open → half-open → closed
  - Closed: Normal operation, requests pass through
  - Open: Failing, requests are rejected immediately
  - Half-open: Testing if service recovered

  ## Usage

      LLMUtils.CircuitBreaker.call(:my_service, fn -> my_request() end)

  Override by passing a module implementing `call/3` in Client options.
  """

  @defaults %{
    failure_threshold: 5,
    cooldown_ms: 30_000,
    half_open_max_requests: 1
  }

  @doc """
  Execute a function with circuit breaking.

  ## Parameters
  - `name` — Circuit identifier (atom)
  - `fun` — Zero-arity function to execute
  - `opts` — Options (failure_threshold, cooldown_ms)
  """
  @spec call(atom(), function(), keyword()) :: {:ok, any()} | {:error, term()}
  def call(name, fun, opts \\ []) do
    ensure_table()
    state = get_state(name)

    case state.status do
      :open ->
        if cooldown_expired?(state, opts) do
          set_state(name, :half_open, state.failures, System.monotonic_time(:millisecond))
          execute_with_protection(name, fun, opts)
        else
          {:error, :circuit_open}
        end

      :half_open ->
        execute_with_protection(name, fun, opts)

      _ ->
        execute_with_protection(name, fun, opts)
    end
  end

  defp execute_with_protection(name, fun, opts) do
    result = fun.()

    case result do
      {:ok, _} ->
        set_state(name, :closed, 0, nil)
        result

      {:error, _reason} ->
        record_failure(name, opts)
        result
    end
  rescue
    e ->
      record_failure(name, opts)
      {:error, {:exception, Exception.message(e)}}
  end

  defp get_state(name) do
    case :ets.lookup(:circuit_breaker_table, name) do
      [{^name, status, failures, last_failure_time}] ->
        %{status: status, failures: failures, last_failure_time: last_failure_time}

      [] ->
        %{status: :closed, failures: 0, last_failure_time: nil}
    end
  end

  defp set_state(name, status, failures, last_failure_time) do
    :ets.insert(:circuit_breaker_table, {name, status, failures, last_failure_time})
  end

  defp record_failure(name, opts) do
    state = get_state(name)
    threshold = opts[:failure_threshold] || @defaults[:failure_threshold]
    new_failures = state.failures + 1

    if new_failures >= threshold do
      set_state(name, :open, new_failures, System.monotonic_time(:millisecond))
    else
      set_state(name, state.status, new_failures, state.last_failure_time)
    end
  end

  defp cooldown_expired?(state, opts) do
    cooldown = opts[:cooldown_ms] || @defaults[:cooldown_ms]
    now = System.monotonic_time(:millisecond)
    is_integer(state.last_failure_time) and (now - state.last_failure_time) > cooldown
  end

  defp ensure_table do
    case :ets.info(:circuit_breaker_table, :name) do
      :undefined ->
        try do
          :ets.new(:circuit_breaker_table, [:set, :public, :named_table])
        rescue
          ArgumentError -> :ok
        end

      _ ->
        :ok
    end
  end
end
