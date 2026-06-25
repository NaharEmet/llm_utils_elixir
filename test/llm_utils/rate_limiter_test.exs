defmodule LLMUtils.RateLimiterTest do
  use ExUnit.Case, async: false

  alias LLMUtils.RateLimiter

  setup do
    RateLimiter.reset("test_provider")
    RateLimiter.reset("other_provider")
    :ok
  end

  describe "check/3" do
    test "allows first request" do
      assert RateLimiter.check("test_provider", 5, 60_000) == :ok
    end

    test "allows requests under the limit" do
      for _ <- 1..3 do
        assert RateLimiter.check("test_provider", 5, 60_000) == :ok
      end
    end

    test "rate_limited when over limit" do
      for _ <- 1..5 do
        RateLimiter.check("test_provider", 5, 60_000)
      end

      assert RateLimiter.check("test_provider", 5, 60_000) == :rate_limited
    end

    test "different providers have independent limits" do
      for _ <- 1..5 do
        RateLimiter.check("test_provider", 5, 60_000)
      end

      assert RateLimiter.check("other_provider", 5, 60_000) == :ok
    end
  end

  describe "reset/1" do
    test "clears rate limiter state" do
      for _ <- 1..6 do
        RateLimiter.check("test_provider", 5, 60_000)
      end

      assert RateLimiter.check("test_provider", 5, 60_000) == :rate_limited

      RateLimiter.reset("test_provider")
      assert RateLimiter.check("test_provider", 5, 60_000) == :ok
    end
  end
end
