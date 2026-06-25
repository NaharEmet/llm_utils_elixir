# LlmUtils — Development Guide

## Architecture

Three modules, pure functions, zero side effects:

- **AnanthaJson.JsonExtractor** — Extracts JSON strings from LLM markdown output
  - `extract/1` — first JSON object from markdown (```json blocks or raw text)
  - `extract_array/1` — first JSON array
  - `extract_all_objects/1` — all JSON objects (concatenated or line-delimited)
  - `extract_all_arrays/1` — all JSON arrays
  - Internally: regex scanning for ```json blocks, then balanced brace/bracket matching

- **LLMUtils.JsonAdapter** — Defensive JSON decode with automated repair
  - `decode/1` — tries Jason.decode, falls back to json_remedy, returns {:ok, map} or {:error, term}
  - `decode!/1` — same but raises RuntimeError on failure
  - `valid_json?/1` — boolean check
  - Internally: graceful degradation — json_remedy repairs trailing commas, unquoted keys, etc.

- **AnanthaJson.ResponseParser** — End-to-end LLM response parsing
  - `parse/1` — extract + decode in one step
  - `parse_and_extract/2` — parse then extract specific key
  - `parse_array/1` — extract + decode JSON array
  - `parse_relaxed/1` — extracts first valid JSON object from any text (no markdown required)
  - `parse_first_with_key/2` — finds first JSON object containing a specific key
  - Internally: combines JsonExtractor + JsonAdapter, tries multiple extraction strategies

### Extension Patterns

- **New extraction strategy**: Add function to JsonExtractor, expose through ResponseParser
- **New decode strategy**: Add to JsonAdapter, keep decode/1 as the safe entry point
- **New response format**: Add function to ResponseParser that composes existing primitives

### Code Philosophy

1. **Pure functions only** — no GenServers, no side effects, no process dependencies
2. **Parse at boundary** — accept raw strings, return structured data or error tuples
3. **Fail fast** — decode! raises with descriptive message, decode returns {:error, ...}
4. **Guard clauses** — all entry points guard against nil, non-binary, empty string
5. **Minimum dependencies** — Jason + json_remedy only. Keep it light.

### Testing

- Location: `test/anantha_json/`
- Run: `mix test` from `lib/anantha_json/`
- 26 tests covering: markdown-wrapped JSON, malformed JSON, empty input, edge cases
- Key patterns: test extraction from ```json blocks, test decode with trailing commas, test response parser with multi-object responses
