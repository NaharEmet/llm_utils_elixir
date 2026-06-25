# Agent Instructions — llm_utils

This is the `:llm_utils` Hex package — LLM utility functions for JSON extraction and response parsing.

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
2. **Pure functions only** — no GenServers, no side effects, no process dependencies
3. **Guard clauses** on all entry points — guard against nil, non-binary, empty string
4. **Changelog** — every change must add entry in `CHANGELOG.md`
5. **Push subtree** — after changes, remind user: `git subtree push --prefix=lib/anantha_json llm-utils main`
6. **Push BEFORE publishing** to Hex — remote repo must be up to date

## Package Contents

| File / Dir | Purpose |
|------------|---------|
| `AGENTS.md` | This file — agent instructions (you are here) |
| `agents/SKILL.md` | Development skill for AI agents |
| `GUIDE.md` | Internal architecture guide for contributors |
| `README.md` | User-facing docs with API reference |
| `CHANGELOG.md` | Version history |
| `lib/llm_utils/` | Source code (3 modules under `LLMUtils.*`) |
| `test/llm_utils/` | Tests (26) |

## Quick Start

```bash
# Run tests
cd lib/anantha_json && mix test

# Push subtree after changes
git subtree push --prefix=lib/anantha_json llm-utils main

# Publish to Hex
cd lib/anantha_json && mix hex.publish
```
