defmodule LLMUtils.MetricsTest do
  use ExUnit.Case, async: false

  alias LLMUtils.Metrics

  setup do
    Metrics.reset()
    :ok
  end

  describe "record/1 and get_stats/1" do
    test "records and retrieves stats for a provider" do
      Metrics.record(%{provider: "test_provider", status: "success", total_tokens: 100, latency_ms: 200})
      Metrics.record(%{provider: "test_provider", status: "success", total_tokens: 50, latency_ms: 100})

      stats = Metrics.get_stats("test_provider")

      assert stats.total_calls == 2
      assert stats.success_count == 2
      assert stats.error_count == 0
      assert stats.total_tokens == 150
      assert stats.avg_latency_ms == 150
    end

    test "counts errors separately" do
      Metrics.record(%{provider: "test_provider", status: "success", total_tokens: 100, latency_ms: 50})
      Metrics.record(%{provider: "test_provider", status: "error", total_tokens: 0, latency_ms: 1000})
      Metrics.record(%{provider: "test_provider", status: "error", total_tokens: 0, latency_ms: 500})

      stats = Metrics.get_stats("test_provider")

      assert stats.total_calls == 3
      assert stats.success_count == 1
      assert stats.error_count == 2
    end

    test "returns zero stats for unknown provider" do
      stats = Metrics.get_stats("unknown_provider")

      assert stats.total_calls == 0
      assert stats.success_count == 0
      assert stats.error_count == 0
      assert stats.total_tokens == 0
      assert stats.avg_latency_ms == 0
    end

    test "isolates stats per provider" do
      Metrics.record(%{provider: "alpha", status: "success", total_tokens: 10, latency_ms: 5})
      Metrics.record(%{provider: "beta", status: "error", total_tokens: 0, latency_ms: 100})

      alpha = Metrics.get_stats("alpha")
      beta = Metrics.get_stats("beta")

      assert alpha.total_calls == 1
      assert alpha.success_count == 1

      assert beta.total_calls == 1
      assert beta.error_count == 1
    end
  end

  describe "reset/0" do
    test "clears all metrics" do
      Metrics.record(%{provider: "test_provider", status: "success", total_tokens: 10, latency_ms: 5})
      assert Metrics.get_stats("test_provider").total_calls == 1

      Metrics.reset()
      assert Metrics.get_stats("test_provider").total_calls == 0
    end
  end
end
