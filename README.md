# AnanthaJson — LLM Utilities

LLM utility toolkit for Elixir: JSON extraction, defensive decoding, response parsing, and more.

Extracts JSON objects and arrays from LLM markdown responses, provides
defensive JSON decoding with automated repair via `json_remedy`, and
offers a full response parser for structured LLM output.

## Installation

```elixir
def deps do
  [
    {:anantha_llm_utils, "~> 0.1.0"}
  ]
end
```

## Modules

### JsonExtractor — extract JSON from LLM output

```elixir
AnanthaJson.JsonExtractor.extract("""
Here is the result:

```json
{"key": "value"}
```
""")
# => "{\"key\": \"value\"}"

AnanthaJson.JsonExtractor.extract_array("```json\\n[1, 2, 3]\\n```")
# => "[1, 2, 3]"

AnanthaJson.JsonExtractor.extract_all_objects(~s({"a": 1} {"b": 2}))
# => ["{\"a\": 1}", "{\"b\": 2}"]
```

### JsonAdapter — defensive JSON decode

```elixir
AnanthaJson.JsonAdapter.decode(~s({"key": "value"}))
# => {:ok, %{"key" => "value"}}

AnanthaJson.JsonAdapter.decode(~s({"key": "value",}))
# => {:ok, %{"key" => "value"}}

AnanthaJson.JsonAdapter.decode!("not json")
# => ** (RuntimeError) JsonAdapter failed: ...
```

### ResponseParser — full LLM response parsing

```elixir
AnanthaJson.ResponseParser.parse(~s({"key": "value"}))
# => {:ok, %{"key" => "value"}}

AnanthaJson.ResponseParser.parse_and_extract(~s({"name": "Alice"}), "name")
# => {:ok, "Alice"}

AnanthaJson.ResponseParser.parse_first_with_key(~s({"a": 1} {"name": "Bob"}), "name")
# => {:ok, %{"name" => "Bob"}}
```

## Dependencies

- `jason` — fast JSON parsing
- `json_remedy` — automated JSON repair (optional; silent fallback if unavailable)
