defmodule LLMUtils.LoggingTest do
  use ExUnit.Case, async: true

  alias LLMUtils.Logging

  setup do
    Logging.disable()
    :ok
  end

  describe "enable/disable" do
    test "starts disabled" do
      assert Logging.enabled?() == false
    end

    test "enable/1 toggles on" do
      Logging.enable()
      assert Logging.enabled?() == true
    end

    test "disable/1 toggles off" do
      Logging.enable()
      Logging.disable()
      assert Logging.enabled?() == false
    end
  end

  describe "log/3" do
    test "does not raise when disabled" do
      assert Logging.log(:info, "test message") == :ok
    end

    test "does not raise when enabled" do
      Logging.enable()
      assert Logging.log(:info, "test message", provider: :openai, model: "gpt-4") == :ok
    end
  end
end
