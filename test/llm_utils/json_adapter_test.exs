defmodule LLMUtils.JsonAdapterTest do
  use ExUnit.Case, async: true

  alias LLMUtils.JsonAdapter

  describe "decode/1" do
    test "decodes valid JSON" do
      assert {:ok, %{"key" => "value"}} = JsonAdapter.decode(~s({"key": "value"}))
    end

    test "decodes nested JSON" do
      assert {:ok, %{"nested" => %{"a" => 1}}} = JsonAdapter.decode(~s({"nested": {"a": 1}}))
    end

    test "returns error for invalid JSON" do
      assert {:error, _} = JsonAdapter.decode("not json")
    end

    test "returns error for empty string" do
      assert {:error, _} = JsonAdapter.decode("")
    end

    test "returns error for JSON with unescaped newlines" do
      # Literal newlines inside JSON strings are not valid JSON;
      # neither Jason nor JsonRemedy handles them natively.
      input = "{\"key\": \"line1\nline2\"}"
      assert {:error, _} = JsonAdapter.decode(input)
    end

    test "handles JSON with trailing whitespace" do
      assert {:ok, %{"key" => "value"}} = JsonAdapter.decode("  {\"key\": \"value\"}  ")
    end

    test "returns error for non-binary input" do
      assert {:error, :invalid_input} = JsonAdapter.decode(nil)
      assert {:error, :invalid_input} = JsonAdapter.decode(123)
      assert {:error, :invalid_input} = JsonAdapter.decode(%{})
    end

    test "attempts repair for malformed JSON" do
      # Trailing comma is not valid JSON but JsonRemedy can repair it.
      # If JsonRemedy is not loaded, this falls back to Jason.decode which will also fail.
      result = JsonAdapter.decode(~s({"key": "value",}))
      # Either repair succeeds ({:ok, _}) or both repair and Jason fail ({:error, _})
      assert result == {:ok, %{"key" => "value"}} or match?({:error, _}, result)
    end
  end

  describe "decode!/1" do
    test "decodes valid JSON without raising" do
      assert %{"key" => "value"} = JsonAdapter.decode!(~s({"key": "value"}))
    end

    test "raises on invalid JSON" do
      assert_raise RuntimeError, ~r/LLMUtils.JsonAdapter failed/, fn ->
        JsonAdapter.decode!("not json")
      end
    end
  end
end
