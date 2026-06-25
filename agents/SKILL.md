---
name: llm-utils
description: Work on llm_utils (LLMUtils.*) package development. Use when modifying lib/anantha_json/.
---

# llm-utils Development Skill

## When to Use
When modifying anything in `lib/anantha_json/` — the `:llm_utils` Hex package.

## Package Structure
```
lib/anantha_json/
├── lib/llm_utils/
│   ├── json_extractor.ex    # JSON extraction from LLM markdown
│   ├── json_adapter.ex      # Defensive JSON decode
│   └── response_parser.ex   # End-to-end response parsing
├── test/llm_utils/          # 26 tests
├── mix.exs                  # Hex-ready config
├── AGENTS.md                # Agent instructions
├── agents/SKILL.md          # This skill file
├── GUIDE.md                 # Internal development guide
├── CHANGELOG.md             # Version history
├── README.md                # User-facing docs
```

All modules use `LLMUtils.*` prefix (e.g., `LLMUtils.JsonExtractor`, `LLMUtils.JsonAdapter`, `LLMUtils.ResponseParser`).

## Key Modules

### JsonExtractor (LLMUtils.JsonExtractor)
Extracts JSON strings from LLM markdown output. Core extraction logic — everything else builds on this.

Functions:
- `extract/1` — first JSON object from markdown (```json blocks or raw text)
- `extract_array/1` — first JSON array
- `extract_all_objects/1` — all JSON objects (concatenated or line-delimited)
- `extract_all_arrays/1` — all JSON arrays
- Internally: regex scanning for ```json blocks, then balanced brace/bracket matching

### JsonAdapter (LLMUtils.JsonAdapter)
Defensive JSON decode with automated repair.

Functions:
- `decode/1` — tries Jason.decode, falls back to json_remedy, returns {:ok, map} or {:error, term}
- `decode!/1` — same but raises RuntimeError on failure
- `valid_json?/1` — boolean check
- Internally: graceful degradation — json_remedy repairs trailing commas, unquoted keys, etc.

### ResponseParser (LLMUtils.ResponseParser)
End-to-end LLM response parsing. Composes JsonExtractor + JsonAdapter.

Functions:
- `parse/1` — extract + decode in one step
- `parse_and_extract/2` — parse then extract specific key
- `parse_array/1` — extract + decode JSON array
- `parse_relaxed/1` — extracts first valid JSON object from any text (no markdown required)
- `parse_first_with_key/2` — finds first JSON object containing a specific key

## Golden Rules
- **Standalone** — zero dependencies on `Anantha.*`, `Acs.*`, project modules, or project config
- **Pure functions** — no GenServers, no side effects, no process dependencies
- **Guard clauses** on all entry points (nil, non-binary, empty string)
- **Changelog** — every change must add entry in `CHANGELOG.md`
- **Push subtree** — after changes, remind user: `git subtree push --prefix=lib/anantha_json llm-utils main`

## Testing
```bash
cd lib/anantha_json && mix test
```
26 tests, all pure function tests (no mocks, no GenServers).

## Hex Publishing
```bash
# Push subtree first
git subtree push --prefix=lib/anantha_json llm-utils main

# Then publish
cd lib/anantha_json && mix hex.publish
```

## Common Pitfalls
- **Don't** import project modules — breaks standalone publishing
- **Don't** add GenServers or processes — keep it a data-processing library
- **Don't** forget CHANGELOG — it's the release history for consumers
