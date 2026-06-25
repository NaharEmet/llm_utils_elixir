# LlmUtils — LLM Utilities

LLM utility toolkit for Elixir: JSON extraction, defensive decoding, response parsing,
LLM provider configurations, HTTP client with rate limiting, circuit breaking, metrics,
and toggleable logging.

## Installation

```elixir
def deps do
  [
    {:llm_utils, "~> 0.4.0"}
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

LLMUtils.JsonExtractor.extract_array("```json\n[1, 2, 3]\n```")
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

### Provider — provider configuration behaviour

Defines a standard `config/0` callback returning provider metadata (id, name, api_key env var,
auth type, rate limit, capabilities). Provides helpers:

```elixir
LLMUtils.Provider.auth_headers(provider_id, api_key)
# => [{"Authorization", "Bearer sk-..."}]

LLMUtils.Provider.env_key(provider_id)
# => "OPENAI_API_KEY"

LLMUtils.Provider.get_api_key(provider_id, opts)
# => "sk-..." or {:error, :missing_api_key}
```

### Providers — provider registry

Registry of all supported LLM providers:

```elixir
LLMUtils.Providers.all()
# => [%{id: :openai, name: "OpenAI", ...}, ...]

LLMUtils.Providers.get(:openai)
# => %{id: :openai, name: "OpenAI", ...}

LLMUtils.Providers.exists?(:openai)
# => true
```

Supported providers: `openai`, `nim`, `groq`, `grok`, `sarvam`, `fireworks`, `mimo`, `minimax`, `mock`.

### Client — LLM HTTP client

Chat completion with fallback, rate limiting, circuit breaking, and metrics:

```elixir
LLMUtils.Client.chat_completion(:openai, messages, opts)
# => {:ok, %{content: "...", model: "gpt-4", ...}}
```

Handles:
- Provider-specific auth and request formatting
- Response normalization (thinking tags, system→user, reasoning content, tool calls)
- Fallback to next provider on failure
- Rate limiting, circuit breaking, metrics recording
- Toggleable structured logging

### RateLimiter — ETS-based sliding window

```elixir
LLMUtils.RateLimiter.check(:openai, 40, 60_000)
# => :allow
```

Sliding window rate limiter. Configurable max requests per time window.

### CircuitBreaker — ETS-based 3-state

States: `:closed` (normal), `:open` (failing), `:half_open` (testing recovery).

```elixir
LLMUtils.CircuitBreaker.state(:openai)
# => :closed
```

Auto-transitions after configurable reset timeout.

### Metrics — in-memory collector

ETS-based counters for requests, successes, failures, and latency:

```elixir
LLMUtils.Metrics.increment(:openai, :requests)
LLMUtils.Metrics.record_latency(:openai, 1_200)
LLMUtils.Metrics.report(:openai)
# => %{requests: 10, successes: 8, failures: 2, ...}
```

All stateful features use public ETS tables with overridable module callbacks —
consumer apps can inject custom implementations.

### Logging — toggleable structured logger

```elixir
LLMUtils.Logging.configure(enabled: true, level: :info)
LLMUtils.Logging.log(:info, "Request sent", provider: :openai, model: "gpt-4")
```

## Dependencies

- `jason` — fast JSON parsing
- `json_remedy` — automated JSON repair (optional; silent fallback if unavailable)
- `req` — HTTP client
