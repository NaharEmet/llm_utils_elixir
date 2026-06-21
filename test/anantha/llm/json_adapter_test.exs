defmodule Anantha.LLM.JsonAdapterTest do
  use ExUnit.Case, async: true

  alias Anantha.LLM.JsonAdapter

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
  end

  describe "decode!/1" do
    test "decodes valid JSON without raising" do
      assert %{"key" => "value"} = JsonAdapter.decode!(~s({"key": "value"}))
    end

    test "raises on invalid JSON" do
      assert_raise RuntimeError, ~r/JsonAdapter failed/, fn ->
        JsonAdapter.decode!("not json")
      end
    end
  end
end
