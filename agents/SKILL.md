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
│   ├── json_extractor.ex      # JSON extraction from LLM markdown
│   ├── json_adapter.ex        # Defensive JSON decode
│   ├── response_parser.ex     # End-to-end response parsing
│   ├── provider.ex            # Provider configuration behaviour
│   ├── providers.ex           # Provider registry
│   ├── providers/             # 9 provider modules
│   │   ├── openai.ex
│   │   ├── nim.ex
│   │   ├── groq.ex
│   │   ├── grok.ex
│   │   ├── sarvam.ex
│   │   ├── fireworks.ex
│   │   ├── mimo.ex
│   │   ├── minimax.ex
│   │   └── mock.ex
│   ├── client.ex              # Core HTTP client
│   ├── rate_limiter.ex        # Sliding window rate limiter
│   ├── circuit_breaker.ex     # 3-state circuit breaker
│   ├── metrics.ex             # In-memory metrics collector
│   └── logging.ex             # Toggleable logger
├── test/llm_utils/            # 46 tests
│   ├── json_adapter_test.exs
│   ├── json_extractor_test.exs
│   ├── rate_limiter_test.exs
│   ├── circuit_breaker_test.exs
│   ├── metrics_test.exs
│   └── logging_test.exs
├── mix.exs                    # Hex-ready config
├── AGENTS.md                  # Agent instructions
├── agents/SKILL.md            # This skill file
├── GUIDE.md                   # Internal development guide
├── CHANGELOG.md               # Version history
├── README.md                  # User-facing docs
```

All modules use `LLMUtils.*` prefix (e.g., `LLMUtils.JsonExtractor`, `LLMUtils.Provider`, `LLMUtils.Client`).

## Key Modules

### JSON Processing (pure, stateless)

#### JsonExtractor (LLMUtils.JsonExtractor)
Extracts JSON strings from LLM markdown output. Core extraction logic — everything else builds on this.

Functions:
- `extract/1` — first JSON object from markdown (```json blocks or raw text)
- `extract_array/1` — first JSON array
- `extract_all_objects/1` — all JSON objects (concatenated or line-delimited)
- `extract_all_arrays/1` — all JSON arrays
- Internally: regex scanning for ```json blocks, then balanced brace/bracket matching

#### JsonAdapter (LLMUtils.JsonAdapter)
Defensive JSON decode with automated repair.

Functions:
- `decode/1` — tries Jason.decode, falls back to json_remedy, returns {:ok, map} or {:error, term}
- `decode!/1` — same but raises RuntimeError on failure
- `valid_json?/1` — boolean check
- Internally: graceful degradation — json_remedy repairs trailing commas, unquoted keys, etc.

#### ResponseParser (LLMUtils.ResponseParser)
End-to-end LLM response parsing. Composes JsonExtractor + JsonAdapter.

Functions:
- `parse/1` — extract + decode in one step
- `parse_and_extract/2` — parse then extract specific key
- `parse_array/1` — extract + decode JSON array
- `parse_relaxed/1` — extracts first valid JSON object from any text (no markdown required)
- `parse_first_with_key/2` — finds first JSON object containing a specific key

### Provider Infrastructure (stateless)

#### Provider (LLMUtils.Provider)
Behaviour for provider configuration. Each provider module implements `config/0`.
Provides helper functions:
- `auth_headers/2` — generate auth headers for provider
- `env_key/1` — get environment variable name for API key
- `get_api_key/1` — resolve API key from env or opts

#### Providers (LLMUtils.Providers)
Registry of all supported providers:
- `all/0` — list all provider configs
- `get/1` — get single provider by ID
- `get_module/1` — get provider module
- `exists?/1` — check if provider ID is registered

### Stateful Infrastructure (ETS, overridable)

#### Client (LLMUtils.Client)
Core HTTP client. `chat_completion/3` orchestrates:
1. Rate limit check → RateLimiter
2. Circuit breaker check → CircuitBreaker
3. API key resolution → Provider
4. Request body building → provider-specific
5. HTTP request → Req
6. Response normalization → strip thinking tags, extract reasoning, parse tool calls
7. Metrics recording → Metrics
8. Logging → Logging (if enabled)

All stateful modules accept override opts for custom implementations.

#### RateLimiter (LLMUtils.RateLimiter)
ETS-based sliding window. `check/3` returns `:ok` or `:rate_limited`.
`reset/1` clears state for a provider.

#### CircuitBreaker (LLMUtils.CircuitBreaker)
ETS-based 3-state (closed/open/half-open). `call/3` executes a function with automatic
state transitions on success/failure. Configurable failure threshold and cooldown.

#### Metrics (LLMUtils.Metrics)
ETS-based counters per provider. `record/1` stores call metrics with provider, status,
tokens, and latency. `get_stats/1` returns aggregated snapshot. `reset/0` clears all.

#### Logging (LLMUtils.Logging)
Toggleable logger. `enable/0`, `disable/0`, `enabled?/0` control state. `log/3` outputs
structured metadata only when enabled.

## Golden Rules
- **Standalone** — zero dependencies on `Anantha.*`, `Acs.*`, project modules, or project config
- **Pure where possible** — JSON processing modules are pure functions
- **ETS with callbacks for state** — no GenServers, side effects managed via overridable module callbacks
- **Guard clauses** on all entry points (nil, non-binary, empty string, unknown provider)
- **Changelog** — every change must add entry in `CHANGELOG.md`
- **Push submodule** — commit + push from `lib/anantha_json/`, then update pointer in root repo

## Testing
```bash
cd lib/anantha_json && mix test
```
46 tests covering:
- JSON extraction, JSON decode, response parsing
- Rate limiting (sliding window, per-provider isolation, reset)
- Circuit breaking (threshold, auto-open, close-on-success, exception handling)
- Metrics (recording, aggregation, per-provider isolation, reset)
- Logging (enable/disable toggle, no-op when disabled)

Stateful module tests run with `async: false` (shared ETS tables).
Pure function tests run with `async: true`.

## Hex Publishing
```bash
# Push submodule first
cd lib/anantha_json
git add . && git commit -m "feat: ..." && git push
cd ../..
git add lib/anantha_json && git commit -m "chore: bump llm_utils submodule"

# Then publish
cd lib/anantha_json && mix hex.publish
```

## Common Pitfalls
- **Don't** import project modules — breaks standalone publishing
- **Don't** add GenServers — use ETS with module callbacks instead
- **Don't** forget CHANGELOG — it's the release history for consumers
- **Don't** use `git subtree push` — llm_utils is now a git submodule, push from within the directory
- **Don't** use `async: true` for stateful module tests — shared ETS tables require sequential access