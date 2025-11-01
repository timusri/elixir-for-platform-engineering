# Health Check Aggregator

A production-ready service monitoring system built with Elixir and OTP. This project demonstrates concurrent health checking, fault tolerance through supervision, and real-time metrics aggregation.

## 🎯 Learning Objectives

By completing this project, you will learn:

- Building concurrent systems with GenServer
- Designing supervision trees for fault tolerance
- Implementing periodic tasks with Process messages
- Exposing HTTP APIs with Plug/Cowboy
- Collecting and exporting Prometheus metrics
- Testing concurrent systems with ExUnit

## 🏗️ Architecture

```
Application
    └── Supervisor (one_for_one)
            ├── HealthCheckAggregator.Registry
            ├── HealthCheckAggregator.MetricsStore
            ├── HealthCheckAggregator.CheckerSupervisor (Dynamic)
            │       ├── HealthChecker (service-1)
            │       ├── HealthChecker (service-2)
            │       └── HealthChecker (service-N)
            └── HealthCheckAggregator.WebServer (Plug/Cowboy)
```

## 🚀 Features

- ✅ Concurrent health checking of multiple services
- ✅ Configurable check intervals per service
- ✅ Automatic retry with exponential backoff
- ✅ Supervision tree for fault tolerance
- ✅ HTTP API for querying status
- ✅ Prometheus-compatible metrics export
- ✅ Real-time status updates
- ✅ Service discovery and dynamic registration

## 📋 Prerequisites

- Elixir 1.15+ and Erlang/OTP 26+
- Basic understanding of GenServer and Supervisors
- Completed intermediate-level documentation

## 🔧 Installation

```bash
cd projects/health_check_aggregator

# Get dependencies
mix deps.get

# Compile
mix compile

# Run tests
mix test

# Start the application
mix run --no-halt
```

## 📖 Usage

### Starting the Application

```elixir
# Start with default configuration
mix run --no-halt

# Or start in IEx
iex -S mix
```

### Adding Services to Monitor

```elixir
# Add a service
HealthCheckAggregator.add_service(
  "my-api",
  "http://localhost:8080/health",
  interval: 30_000  # Check every 30 seconds
)

# Add multiple services
services = [
  {"github", "https://github.com", [interval: 60_000]},
  {"google", "https://google.com", [interval: 30_000]}
]

Enum.each(services, fn {name, url, opts} ->
  HealthCheckAggregator.add_service(name, url, opts)
end)
```

### Querying Status

```elixir
# Get all service statuses
HealthCheckAggregator.get_all_statuses()

# Get specific service status
HealthCheckAggregator.get_status("my-api")

# Remove a service
HealthCheckAggregator.remove_service("my-api")
```

### HTTP API

The application exposes an HTTP API on port 4000:

```bash
# Get all statuses
curl http://localhost:4000/status

# Get specific service
curl http://localhost:4000/status/my-api

# Get Prometheus metrics
curl http://localhost:4000/metrics

# Health check endpoint
curl http://localhost:4000/health
```

### API Responses

```json
// GET /status
{
  "services": {
    "my-api": {
      "status": "healthy",
      "last_check": "2024-11-01T10:30:00Z",
      "response_time_ms": 45,
      "consecutive_failures": 0
    },
    "other-api": {
      "status": "unhealthy",
      "last_check": "2024-11-01T10:30:15Z",
      "response_time_ms": null,
      "consecutive_failures": 3
    }
  }
}

// GET /metrics (Prometheus format)
# TYPE health_check_status gauge
health_check_status{service="my-api"} 1
health_check_status{service="other-api"} 0

# TYPE health_check_response_time_ms gauge
health_check_response_time_ms{service="my-api"} 45
```

## 🎓 Exercises

Work through these exercises to deepen your understanding:

### Exercise 1: Alert on Failures (Beginner)

Add functionality to send alerts when a service fails 3 consecutive times.

**Hints:**
- Modify `HealthChecker` to track consecutive failures
- Add an `AlertManager` GenServer
- Send a message when threshold is reached

### Exercise 2: Health Score (Intermediate)

Calculate a health score (0-100) based on recent check history.

**Requirements:**
- Keep last 10 check results
- Score = (successes / total) * 100
- Expose via API

### Exercise 3: Service Groups (Intermediate)

Add support for grouping services (e.g., "frontend", "backend").

**Requirements:**
- Services belong to one or more groups
- Query status by group
- Calculate group health percentage

### Exercise 4: Custom Check Types (Advanced)

Support different check types (HTTP, TCP, DNS).

**Requirements:**
- Abstract check behavior
- Implement multiple checker types
- Configure type per service

### Exercise 5: Distributed Monitoring (Advanced)

Make the system distributed across multiple nodes.

**Requirements:**
- Use distributed Erlang
- Coordinate checks across nodes
- Avoid duplicate checks
- Handle node failures

## 🧪 Testing

```bash
# Run all tests
mix test

# Run with coverage
mix test --cover

# Run specific test
mix test test/health_check_aggregator_test.exs

# Run in watch mode (requires mix_test_watch)
mix test.watch
```

### Test Structure

```elixir
# Unit tests for individual modules
test/health_checker_test.exs
test/metrics_store_test.exs

# Integration tests
test/integration/full_system_test.exs

# Test helpers
test/support/test_server.ex
```

## 📊 Metrics

The application exposes the following Prometheus metrics:

- `health_check_status` - Current status (1 = healthy, 0 = unhealthy)
- `health_check_response_time_ms` - Last response time in milliseconds
- `health_check_total_checks` - Total number of checks performed
- `health_check_failures_total` - Total number of failures

## 🔍 Debugging

### Observer

Start Observer to visualize the supervision tree:

```elixir
iex -S mix
iex> :observer.start()
```

### Process Information

```elixir
# List all health checkers
DynamicSupervisor.which_children(HealthCheckAggregator.CheckerSupervisor)

# Count active processes
DynamicSupervisor.count_children(HealthCheckAggregator.CheckerSupervisor)

# Get process state
:sys.get_state(pid)
```

## 🏆 Success Criteria

You've successfully completed this project when:

- [ ] All tests pass
- [ ] Application starts without errors
- [ ] Can add/remove services dynamically
- [ ] Health checks run concurrently
- [ ] HTTP API returns correct data
- [ ] Metrics are exported properly
- [ ] System recovers from crashes
- [ ] Completed at least 2 exercises

## 🚀 Next Steps

After completing this project:

1. Build the [Log Stream Processor](../log_stream_processor/)
2. Explore [Advanced OTP Patterns](../../docs/03-advanced/01-advanced-otp.md)
3. Learn about [Distribution & Clustering](../../docs/03-advanced/02-distribution.md)

## 📚 Additional Resources

- [GenServer Documentation](https://hexdocs.pm/elixir/GenServer.html)
- [Supervisor Documentation](https://hexdocs.pm/elixir/Supervisor.html)
- [Plug Documentation](https://hexdocs.pm/plug/)
- [Prometheus Best Practices](https://prometheus.io/docs/practices/naming/)

## 💡 Tips

- Use `:observer.start()` to visualize your supervision tree
- Test with services that randomly fail to verify fault tolerance
- Monitor memory usage with many services
- Use `:timer.tc()` to measure performance

## 🐛 Troubleshooting

**Application crashes on startup:**
- Check Elixir and Erlang versions
- Ensure all dependencies are installed

**Health checks not running:**
- Verify services are added correctly
- Check process is alive: `Process.alive?(pid)`
- Look for supervisor restarts in logs

**High memory usage:**
- Limit stored check history
- Clean up old metrics
- Monitor process count

## 📝 License

This learning project is part of the Elixir for DevOps guide.

