defmodule LLMUtils.CircuitBreakerTest do
  use ExUnit.Case, async: false

  alias LLMUtils.CircuitBreaker

  setup do
    # Reset circuit breaker state — create table if needed, clear entries
    create_table_if_needed()
    :ets.delete(:circuit_breaker_table, :test_circuit)
    :ets.delete(:circuit_breaker_table, :test_circuit_cooldown)
    :ok
  end

  defp create_table_if_needed do
    case :ets.info(:circuit_breaker_table, :name) do
      :undefined -> :ets.new(:circuit_breaker_table, [:set, :public, :named_table])
      _ -> :ok
    end
  end

  describe "call/3" do
    test "passes through successful calls" do
      assert CircuitBreaker.call(:test_circuit, fn -> {:ok, "success"} end) == {:ok, "success"}
    end

    test "passes through failure calls" do
      assert CircuitBreaker.call(:test_circuit, fn -> {:error, "fail"} end) == {:error, "fail"}
    end

    test "opens after reaching failure threshold" do
      opts = [failure_threshold: 3]

      for _ <- 1..3 do
        CircuitBreaker.call(:test_circuit, fn -> {:error, "fail"} end, opts)
      end

      assert CircuitBreaker.call(:test_circuit, fn -> {:ok, "should not reach"} end, opts) ==
               {:error, :circuit_open}
    end

    test "resets failure count on success" do
      opts = [failure_threshold: 3]

      CircuitBreaker.call(:test_circuit, fn -> {:error, "fail"} end, opts)
      CircuitBreaker.call(:test_circuit, fn -> {:ok, "success"} end, opts)
      CircuitBreaker.call(:test_circuit, fn -> {:error, "fail"} end, opts)

      # Only 2 failures, should still pass
      assert CircuitBreaker.call(:test_circuit, fn -> {:ok, "ok"} end, opts) == {:ok, "ok"}
    end

    test "handles exceptions by recording failure" do
      opts = [failure_threshold: 1]

      result = CircuitBreaker.call(:test_circuit, fn -> raise "boom" end, opts)
      assert match?({:error, {:exception, _}}, result)

      # Circuit should now be open
      assert CircuitBreaker.call(:test_circuit, fn -> {:ok, "nope"} end, opts) ==
               {:error, :circuit_open}
    end
  end
end
