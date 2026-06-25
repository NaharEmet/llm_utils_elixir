# Changelog

## 0.4.0 (2026-06-25)

- `LLMUtils.Provider` — Provider configuration behaviour (config/0, auth_headers/2, env_key/1, get_api_key/1)
- `LLMUtils.Providers` — Provider registry with 9 supported providers (openai, nim, groq, grok, sarvam, fireworks, mimo, minimax, mock)
- `LLMUtils.Client` — Core HTTP client with chat_completion/3, fallback support, response normalization
- `LLMUtils.RateLimiter` — ETS-based sliding window rate limiter
- `LLMUtils.CircuitBreaker` — ETS-based 3-state circuit breaker (closed/open/half-open)
- `LLMUtils.Metrics` — In-memory ETS metrics collector
- `LLMUtils.Logging` — Toggleable structured logger
- Dependencies: added `req` HTTP client

## 0.3.0 (2026-06-25)

- `LLMUtils.JsonExtractor` and `LLMUtils.ResponseParser` — Renamed from `AnanthaJson.*` to match the `:llm_utils` package namespace

## 0.2.0 (2026-06-24)

- Add GUIDE.md — internal development guide for contributors

## 0.1.0 (2026-06-24)

- Initial release
- `LLMUtils.JsonExtractor` — Extract JSON from LLM markdown output
- `LLMUtils.JsonAdapter` — Defensive JSON decode with json_remedy fallback
- `LLMUtils.JsonAdapter` — Renamed from `AnanthaJson.JsonAdapter` to match the `:llm_utils` package namespace
- `LLMUtils.ResponseParser` — Parse and extract JSON from structured LLM responses
