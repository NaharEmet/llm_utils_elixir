# AnanthaJson

JSON extraction and defensive decoding utilities for LLM output.

Extracts JSON objects and arrays from LLM markdown responses, and provides
defensive JSON decoding with automated repair via `json_remedy`.

## Installation

```elixir
def deps do
  [
    {:anantha_json, "~> 0.1.0"}
  ]
end
```

## Usage

### JsonExtractor — extract JSON from LLM output

```elixir
# Extract JSON from markdown code blocks
AnanthaJson.JsonExtractor.extract("""
Here is the result:

```json
{"key": "value"}
```
""")
# => "{\"key\": \"value\"}"

# Extract arrays
AnanthaJson.JsonExtractor.extract_array("```json\n[1, 2, 3]\n```")
# => "[1, 2, 3]"

# Get all valid JSON objects
AnanthaJson.JsonExtractor.extract_all_objects(~s({"a": 1} {"b": 2}))
# => ["{\"a\": 1}", "{\"b\": 2}"]
```

### JsonAdapter — defensive JSON decode

```elixir
# Decodes valid JSON normally
AnanthaJson.JsonAdapter.decode(~s({"key": "value"}))
# => {:ok, %{"key" => "value"}}

# Attempts repair for malformed JSON via json_remedy
AnanthaJson.JsonAdapter.decode(~s({"key": "value",}))
# => {:ok, %{"key" => "value"}}

# Raises on failure
AnanthaJson.JsonAdapter.decode!("not json")
# => ** (RuntimeError) JsonAdapter failed: ...
```

## Dependencies

- `jason` — fast JSON parsing
- `json_remedy` — automated JSON repair (optional; silent fallback if unavailable)
