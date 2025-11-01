# API Gateway with Rate Limiting

A production-grade API gateway built with Phoenix featuring per-client rate limiting, circuit breakers, request routing, and comprehensive observability.

## 🎯 Learning Objectives

- Build high-performance HTTP servers
- Implement rate limiting with ETS
- Add circuit breakers for resilience
- Create request routing logic
- Integrate telemetry and metrics
- Handle WebSocket connections
- Implement authentication middleware

## 🏗️ Architecture

```
Client Request
    │
    ├──> Authentication
    │       │
    ├──> Rate Limiter (ETS)
    │       │
    ├──> Circuit Breaker
    │       │
    ├──> Router
    │       ├──> Service A
    │       ├──> Service B
    │       └──> Service C
    │
    └──> Telemetry/Metrics
```

## 🚀 Features

- ✅ Per-client rate limiting
- ✅ Circuit breakers for upstream services
- ✅ Dynamic routing rules
- ✅ Request/response transformation
- ✅ Authentication & authorization
- ✅ WebSocket proxy
- ✅ Prometheus metrics
- ✅ Request logging and tracing
- ✅ Health checks

## 📋 Core Concepts

### Rate Limiting with ETS

```elixir
defmodule RateLimiter do
  def check(client_id, limit, window_seconds) do
    table = :rate_limiter
    now = System.system_time(:second)
    window_start = now - window_seconds

    case :ets.lookup(table, client_id) do
      [] ->
        :ets.insert(table, {client_id, now, 1})
        {:ok, 1, limit}

      [{^client_id, last_reset, count}] when last_reset < window_start ->
        :ets.insert(table, {client_id, now, 1})
        {:ok, 1, limit}

      [{^client_id, last_reset, count}] when count < limit ->
        :ets.update_counter(table, client_id, {3, 1})
        {:ok, count + 1, limit}

      [{^client_id, _, count}] ->
        {:error, :rate_limit_exceeded, count, limit}
    end
  end
end
```

### Circuit Breaker

```elixir
defmodule CircuitBreaker do
  # States: :closed, :open, :half_open

  def call(service, request) do
    case get_state(service) do
      :closed -> execute_request(service, request)
      :open -> {:error, :circuit_open}
      :half_open -> try_request(service, request)
    end
  end

  defp execute_request(service, request) do
    case HTTPoison.get(service.url <> request.path) do
      {:ok, response} ->
        record_success(service)
        {:ok, response}
      {:error, reason} ->
        record_failure(service)
        maybe_open_circuit(service)
        {:error, reason}
    end
  end
end
```

### Request Routing

```elixir
defmodule Router do
  use Plug.Router

  plug :match
  plug :authenticate
  plug :rate_limit
  plug :dispatch

  forward "/api/users", to: UserServiceProxy
  forward "/api/posts", to: PostServiceProxy
  forward "/api/comments", to: CommentServiceProxy

  match _ do
    send_resp(conn, 404, "Not Found")
  end

  defp authenticate(conn, _opts) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] -> verify_token(conn, token)
      _ -> send_resp(conn, 401, "Unauthorized") |> halt()
    end
  end

  defp rate_limit(conn, _opts) do
    client_id = get_client_id(conn)
    
    case RateLimiter.check(client_id, 100, 60) do
      {:ok, _, _} -> conn
      {:error, :rate_limit_exceeded, _, _} ->
        conn
        |> put_resp_header("retry-after", "60")
        |> send_resp(429, "Too Many Requests")
        |> halt()
    end
  end
end
```

### Telemetry Integration

```elixir
defmodule Gateway.Telemetry do
  def attach do
    events = [
      [:gateway, :request, :start],
      [:gateway, :request, :stop],
      [:gateway, :rate_limit, :exceeded],
      [:gateway, :circuit_breaker, :open]
    ]

    :telemetry.attach_many("gateway-metrics", events, &handle_event/4, nil)
  end

  def handle_event([:gateway, :request, :stop], measurements, metadata, _) do
    :telemetry.execute(
      [:prometheus, :counter],
      %{value: 1},
      %{
        metric: "http_requests_total",
        labels: %{
          method: metadata.method,
          path: metadata.path,
          status: metadata.status
        }
      }
    )

    :telemetry.execute(
      [:prometheus, :histogram],
      %{value: measurements.duration},
      %{metric: "http_request_duration_milliseconds"}
    )
  end
end
```

## 🎓 Exercises

### Exercise 1: Token Bucket (Intermediate)
Implement token bucket algorithm for smoother rate limiting.

### Exercise 2: Weighted Routing (Intermediate)
Add weighted routing for canary deployments.

### Exercise 3: Request Caching (Advanced)
Cache responses with TTL and invalidation.

### Exercise 4: gRPC Support (Advanced)
Add gRPC protocol support alongside HTTP.

### Exercise 5: Service Mesh (Expert)
Implement service mesh features (mTLS, tracing, retries).

## 📊 Key Patterns

**Rate Limiting**: Protect from abuse
**Circuit Breakers**: Prevent cascading failures
**Load Balancing**: Distribute traffic
**Observability**: Monitor everything

## 🧪 Testing Strategy

- Unit tests for rate limiter
- Integration tests for routing
- Load tests for performance
- Chaos tests for resilience

## 📈 Success Criteria

- [ ] Handle 10,000+ req/sec
- [ ] Rate limiting works per client
- [ ] Circuit breakers prevent cascades
- [ ] <10ms p95 latency overhead
- [ ] Comprehensive metrics

## 🚀 Next Steps

After completing all projects:
1. Deploy to production
2. Build your own DevOps tools
3. Contribute to open source
4. Share your learnings

## 📚 Resources

- Phoenix Documentation
- Plug Guide
- Rate Limiting Algorithms
- Circuit Breaker Pattern
- API Gateway Patterns

