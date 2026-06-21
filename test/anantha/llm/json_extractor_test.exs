defmodule Anantha.LLM.JsonExtractorTest do
  use ExUnit.Case, async: true

  alias Anantha.LLM.JsonExtractor

  describe "extract/1" do
    test "extracts JSON from markdown code blocks with json language tag" do
      content = """
      Here's the response:

      ```json
      {"key": "value", "number": 42}
      ```
      """

      assert JsonExtractor.extract(content) == "{\"key\": \"value\", \"number\": 42}"
    end

    test "extracts JSON from markdown code blocks without language tag" do
      content = """
      ```
      {"name": "test"}
      ```
      """

      assert JsonExtractor.extract(content) == "{\"name\": \"test\"}"
    end

    test "extracts JSON from markdown with JSON language (case insensitive)" do
      content = "```JSON\n{\"key\": 1}\n```"
      assert JsonExtractor.extract(content) == "{\"key\": 1}"
    end

    test "returns trimmed content when no markdown blocks" do
      content = "  {\"key\": \"value\"}  "
      assert JsonExtractor.extract(content) == "{\"key\": \"value\"}"
    end

    test "handles nil input" do
      assert JsonExtractor.extract(nil) == ""
    end

    test "handles empty string" do
      assert JsonExtractor.extract("") == ""
    end

    test "handles non-string input" do
      assert JsonExtractor.extract(123) == ""
      assert JsonExtractor.extract(%{}) == ""
    end

    test "handles multiline JSON within markdown" do
      content = """
      ```json
      {
        "name": "John",
        "age": 30,
        "items": [1, 2, 3]
      }
      ```
      """

      # Note: extract trims trailing newlines
      expected = """
      {
        "name": "John",
        "age": 30,
        "items": [1, 2, 3]
      }
      """

      assert JsonExtractor.extract(content) == String.trim(expected)
    end

    test "handles JSON without trailing newlines in markdown" do
      content = "```json\n{\"key\": \"value\"}```"
      assert JsonExtractor.extract(content) == "{\"key\": \"value\"}"
    end

    test "extracts JSON from content preceded by thinking text" do
      thinking_content = """
      The user wants a workflow named Important Messages.

      We need to generate a short workflow ID.

      {"ant_ir": {"workflow_id": "important_messages"}}
      """

      result = JsonExtractor.extract(thinking_content)

      # Should extract the JSON part only
      assert Jason.decode(result) ==
               {:ok, %{"ant_ir" => %{"workflow_id" => "important_messages"}}}
    end

    test "extracts last JSON object when multiple exist in text" do
      content = ~s({"first": 1} Some text {"second": 2} More text {"last": true})
      result = JsonExtractor.extract(content)

      assert Jason.decode(result) == {:ok, %{"last" => true}}
    end

    test "handles JSON with double closing braces (}} suffix)" do
      # LLM providers sometimes emit an extra trailing } at end of JSON.
      # Balanced brace matching should extract only up to the first matching brace.
      content = ~s({"key": "value", "nested": {"inner": 1}}})
      expected = ~s({"key": "value", "nested": {"inner": 1}})
      assert JsonExtractor.extract(content) == expected
      assert Jason.decode(JsonExtractor.extract(content)) ==
               {:ok, %{"key" => "value", "nested" => %{"inner" => 1}}}
    end

    test "handles JSON with double braces after thinking text" do
      # Real-world scenario: LLM response has text before JSON with }}
      content = """
      Here is your evaluation:

      {"quality_score": 5, "title_quality": 5, "is_noise": false, "recommendation": "approve", "reasoning": "Some reasoning here", "improvements": "None required", "suggested_title": "A good title", "is_duplicate_of": null}}
      """

      result = JsonExtractor.extract(content)
      # Verify the extracted JSON parses correctly (single } at end, not double)
      assert {:ok, decoded} = Jason.decode(result)
      assert decoded["quality_score"] == 5
      assert decoded["recommendation"] == "approve"
      assert decoded["is_duplicate_of"] == nil
    end
  end

  describe "extract_last_json_object/1" do
    test "extracts last valid JSON object" do
      content = "Some text before {\"key\": \"value\", \"nested\": {\"a\": 1}}"

      assert {:ok, json} = JsonExtractor.extract_last_json_object(content)
      assert Jason.decode(json) == {:ok, %{"key" => "value", "nested" => %{"a" => 1}}}
    end

    test "returns error when no JSON found" do
      assert {:error, _} = JsonExtractor.extract_last_json_object("No JSON here")
    end

    test "handles nested JSON objects" do
      content = ~s({"outer": {"inner": {"deep": "value"}}})

      assert {:ok, json} = JsonExtractor.extract_last_json_object(content)
      assert json == content
    end
  end
end
