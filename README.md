# LlmUtils — LLM Utilities

LLM utility toolkit for Elixir: JSON extraction, defensive decoding, response parsing, and more.

Extracts JSON objects and arrays from LLM markdown responses, provides
defensive JSON decoding with automated repair via `json_remedy`, and
offers a full response parser for structured LLM output.

## Installation

```elixir
def deps do
  [
    {:llm_utils, "~> 0.1.0"}
  ]
end
```

## Modules

### JsonExtractor — extract JSON from LLM output

```elixir
LLMUtils.JsonExtractor.extract("""
Here is the result:

```json
{"key": "value"}
```
""")
# => "{\"key\": \"value\"}"

LLMUtils.JsonExtractor.extract_array("```json\\n[1, 2, 3]\\n```")
# => "[1, 2, 3]"

LLMUtils.JsonExtractor.extract_all_objects(~s({"a": 1} {"b": 2}))
# => ["{\"a\": 1}", "{\"b\": 2}"]
```

### JsonAdapter — defensive JSON decode

```elixir
LLMUtils.JsonAdapter.decode(~s({"key": "value"}))
# => {:ok, %{"key" => "value"}}

LLMUtils.JsonAdapter.decode(~s({"key": "value",}))
# => {:ok, %{"key" => "value"}}

LLMUtils.JsonAdapter.decode!("not json")
# => ** (RuntimeError) JsonAdapter failed: ...
```

### ResponseParser — full LLM response parsing

```elixir
LLMUtils.ResponseParser.parse(~s({"key": "value"}))
# => {:ok, %{"key" => "value"}}

LLMUtils.ResponseParser.parse_and_extract(~s({"name": "Alice"}), "name")
# => {:ok, "Alice"}

LLMUtils.ResponseParser.parse_first_with_key(~s({"a": 1} {"name": "Bob"}), "name")
# => {:ok, %{"name" => "Bob"}}
```

## Dependencies

- `jason` — fast JSON parsing
- `json_remedy` — automated JSON repair (optional; silent fallback if unavailable)
