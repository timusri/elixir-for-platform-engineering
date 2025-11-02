# Telemetry & Observability

## Overview

Building observable systems is crucial for production environments. Elixir's Telemetry library provides a standard way to emit and handle metrics, logs, and traces.

## Telemetry Basics

### Installation

```elixir
# mix.exs
def deps do
  [
    {:telemetry, "~> 1.2"},
    {:telemetry_metrics, "~> 0.6"},
    {:telemetry_poller, "~> 1.0"}
  ]
end
```

### Emitting Events

```elixir
:telemetry.execute(
  [:my_app, :request, :stop],
  %{duration: duration_ms},
  %{path: "/api/users", method: "GET"}
)
```

### Handling Events

```elixir
:telemetry.attach(
  "my-handler",
  [:my_app, :request, :stop],
  fn event_name, measurements, metadata, config ->
    IO.puts("Request to #{metadata.path} took #{measurements.duration}ms")
  end,
  nil
)
```

## Platform Engineering Monitoring Example

```elixir
defmodule MyApp.Telemetry do
  use Supervisor

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def init(_arg) do
    children = [
      # Poller for VM metrics
      {:telemetry_poller, measurements: periodic_measurements(), period: 10_000}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp periodic_measurements do
    [
      # VM metrics
      {__MODULE__, :dispatch_vm_metrics, []},
      
      # Custom metrics
      {__MODULE__, :dispatch_custom_metrics, []}
    ]
  end

  def dispatch_vm_metrics do
    :telemetry.execute(
      [:vm, :memory],
      %{
        total: :erlang.memory(:total),
        processes: :erlang.memory(:processes),
        binary: :erlang.memory(:binary)
      },
      %{}
    )

    :telemetry.execute(
      [:vm, :system],
      %{
        process_count: :erlang.system_info(:process_count),
        port_count: :erlang.system_info(:port_count)
      },
      %{}
    )
  end

  def dispatch_custom_metrics do
    # Your custom metrics
    active_connections = count_active_connections()
    
    :telemetry.execute(
      [:my_app, :connections],
      %{active: active_connections},
      %{}
    )
  end

  defp count_active_connections do
    # Implementation
    0
  end
end
```

## Prometheus Integration

```elixir
# mix.exs
{:prom_ex, "~> 1.8"}

# lib/my_app/prom_ex.ex
defmodule MyApp.PromEx do
  use PromEx, otp_app: :my_app

  @impl true
  def plugins do
    [
      # Built-in plugins
      PromEx.Plugins.Application,
      PromEx.Plugins.Beam,
      
      # Custom plugin
      MyApp.PromEx.CustomMetrics
    ]
  end

  @impl true
  def dashboard_assigns do
    [
      datasource_id: "prometheus",
      default_selected_interval: "30s"
    ]
  end

  @impl true
  def dashboards do
    [
      {:prom_ex, "application.json"},
      {:prom_ex, "beam.json"}
    ]
  end
end

# lib/my_app/prom_ex/custom_metrics.ex
defmodule MyApp.PromEx.CustomMetrics do
  use PromEx.Plugin

  @impl true
  def event_metrics(_opts) do
    [
      counter(
        [:my_app, :http, :requests, :total],
        event_name: [:my_app, :request, :stop],
        tags: [:method, :path, :status]
      ),

      distribution(
        [:my_app, :http, :request, :duration, :milliseconds],
        event_name: [:my_app, :request, :stop],
        measurement: :duration,
        unit: {:native, :millisecond},
        tags: [:method, :path]
      ),

      last_value(
        [:my_app, :db, :connections, :active],
        event_name: [:my_app, :db, :connections],
        measurement: :active
      )
    ]
  end
end
```

## Structured Logging

```elixir
# config/config.exs
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :user_id, :service]

# Usage
Logger.info("User logged in",
  user_id: user.id,
  ip_address: conn.remote_ip
)

Logger.error("Database connection failed",
  error: inspect(error),
  service: "postgres",
  attempt: retry_count
)
```

## Distributed Tracing

```elixir
# Add OpenTelemetry
{:opentelemetry, "~> 1.3"},
{:opentelemetry_exporter, "~> 1.6"}

# config/config.exs
config :opentelemetry,
  resource: [
    service: [
      name: "my_app",
      namespace: "production"
    ]
  ]

# Trace requests
defmodule MyApp.TracedWorker do
  require OpenTelemetry.Tracer, as: Tracer

  def process(item) do
    Tracer.with_span "process_item" do
      Tracer.set_attributes([
        {"item.id", item.id},
        {"item.type", item.type}
      ])

      result = do_process(item)

      Tracer.add_event("processing_complete", [
        {"result", inspect(result)}
      ])

      result
    end
  end
end
```

## Health Check Endpoint

```elixir
defmodule MyApp.HealthPlug do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    health = check_health()

    status = if health.status == :healthy, do: 200, else: 503

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(health))
  end

  defp check_health do
    checks = %{
      database: check_database(),
      cache: check_cache(),
      external_api: check_external_api()
    }

    status = if Enum.all?(checks, fn {_, v} -> v == :ok end) do
      :healthy
    else
      :unhealthy
    end

    %{
      status: status,
      checks: checks,
      version: Application.spec(:my_app, :vsn),
      uptime: System.monotonic_time(:second)
    }
  end
end
```

## Key Metrics to Track

### Application Metrics
- Request count and duration
- Error rates
- Response status codes
- Queue lengths

### VM Metrics
- Memory usage
- Process count
- Scheduler utilization
- Garbage collection

### Business Metrics
- Active users
- Transactions
- SLA compliance
- Feature usage

## Key Takeaways

1. **Telemetry**: Standard event system
2. **Prometheus**: Industry-standard metrics
3. **Structured logs**: Machine-readable
4. **Distributed tracing**: Request flow
5. **Health checks**: Operational status

## Additional Resources

- [Telemetry Documentation](https://hexdocs.pm/telemetry/)
- [PromEx Documentation](https://hexdocs.pm/prom_ex/)
- [OpenTelemetry Erlang](https://opentelemetry.io/docs/instrumentation/erlang/)

