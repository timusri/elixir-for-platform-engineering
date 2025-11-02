# HealthCheckAggregator

A fault-tolerant platform service monitoring system built with Elixir and OTP. Perfect for platform health dashboards, service catalogs, and platform observability.

## Platform Engineering Value

This project demonstrates key platform engineering patterns:
- Concurrent monitoring of multiple platform services
- Fault-tolerant architecture for platform reliability
- Platform API for service discovery and health status
- Metrics export for platform observability and SLOs

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `health_check_aggregator` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:health_check_aggregator, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/health_check_aggregator>.

