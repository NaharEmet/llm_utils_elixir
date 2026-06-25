# Agent Instructions — llm_utils

This is the `:llm_utils` Hex package — LLM utility functions for JSON extraction,
response parsing, provider configuration, HTTP client, rate limiting, circuit
breaking, metrics, and logging.

Package: `:llm_utils`
Module prefix: `LLMUtils.*`

## Before Working on This Package

Load the development skill:

```
skill(name: "llm-utils")
```

Or read the skill directly: `agents/SKILL.md`

## Key Rules

1. **Standalone** — zero dependencies on `Anantha.*`, `Acs.*`, or project internals. Must be publishable to Hex standalone.
2. **Pure functions for stateless modules** — JSON processing modules are pure with no GenServers
3. **ETS with module callbacks for stateful modules** — RateLimiter, CircuitBreaker, Metrics, Logging use ETS tables with overridable callbacks, not GenServers
4. **Guard clauses** on all entry points — guard against nil, non-binary, empty string, unknown provider
5. **Changelog** — every change must add entry in `CHANGELOG.md`
6. **Push submodule** — after changes, commit and push from `lib/anantha_json/`, then update pointer in root repo:
   ```
   cd lib/anantha_json
   git add . && git commit -m "feat: ..."
   git push
   cd ../..
   git add lib/anantha_json && git commit -m "chore: bump llm_utils submodule"
   ```
7. **Push BEFORE publishing** to Hex — remote repo must be up to date

## Package Contents

| File / Dir | Purpose |
|------------|---------|
| `AGENTS.md` | This file — agent instructions (you are here) |
| `agents/SKILL.md` | Development skill for AI agents |
| `GUIDE.md` | Internal architecture guide for contributors |
| `README.md` | User-facing docs with API reference |
| `CHANGELOG.md` | Version history |
| `lib/llm_utils/` | Source code (11 modules under `LLMUtils.*`) |
| `test/llm_utils/` | Tests (47) |

### Source Modules

| Module | Type | Description |
|--------|------|-------------|
| `JsonExtractor` | Pure | Extract JSON from LLM markdown |
| `JsonAdapter` | Pure | Defensive JSON decode with json_remedy fallback |
| `ResponseParser` | Pure | Compose Extractor + Adapter for end-to-end parsing |
| `Provider` | Pure | Provider configuration behaviour |
| `Providers` | Pure | Provider registry (9 providers) |
| `Client` | Function | Core HTTP client with chat_completion/3 |
| `RateLimiter` | ETS | Sliding window rate limiter |
| `CircuitBreaker` | ETS | 3-state circuit breaker |
| `Metrics` | ETS | In-memory metrics collector |
| `Logging` | ETS | Toggleable structured logger |

## Quick Start

```bash
# Run tests
cd lib/anantha_json && mix test

# Push submodule after changes
cd lib/anantha_json
git add . && git commit -m "feat: ..."
git push
cd ../..
git add lib/anantha_json && git commit -m "chore: bump llm_utils submodule"

# Publish to Hex
cd lib/anantha_json && mix hex.publish
```