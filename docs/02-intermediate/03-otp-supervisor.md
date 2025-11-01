# OTP: Supervisors & Applications

## Overview

Supervisors are the heart of fault-tolerant Elixir systems. They monitor processes and restart them when they crash, creating self-healing applications.

## The Supervision Tree

A supervision tree is a hierarchical structure of supervisors and workers:

```
Application
    └── Supervisor
            ├── Worker 1 (GenServer)
            ├── Worker 2 (GenServer)
            └── Supervisor
                    ├── Worker 3
                    └── Worker 4
```

## Why Supervisors?

- **Automatic Recovery**: Restart crashed processes
- **Isolation**: Failures don't cascade
- **Predictability**: Clear error handling strategy
- **Observability**: Built-in monitoring

## Creating a Supervisor

```elixir
defmodule MyApp.Supervisor do
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      {Worker1, arg1},
      {Worker2, arg2}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
```

## Restart Strategies

### :one_for_one

Restart only the failed child.

```
Before:  [W1] [W2] [W3]
W2 crashes
After:   [W1] [W2'] [W3]
```

**Use case**: Independent workers

```elixir
Supervisor.init(children, strategy: :one_for_one)
```

### :one_for_all

Restart all children when one fails.

```
Before:  [W1] [W2] [W3]
W2 crashes
After:   [W1'] [W2'] [W3']
```

**Use case**: Dependent workers that need to restart together

```elixir
Supervisor.init(children, strategy: :one_for_all)
```

### :rest_for_one

Restart the failed child and all children started after it.

```
Before:  [W1] [W2] [W3]
W2 crashes
After:   [W1] [W2'] [W3']
```

**Use case**: Pipeline where later workers depend on earlier ones

```elixir
Supervisor.init(children, strategy: :rest_for_one)
```

## Child Specification

### Full Format

```elixir
children = [
  %{
    id: MyWorker,
    start: {MyWorker, :start_link, [arg]},
    restart: :permanent,
    shutdown: 5000,
    type: :worker
  }
]
```

### Shorthand (using `use GenServer`)

```elixir
children = [
  {MyWorker, arg}
]
```

### Child Spec Options

- **id**: Unique identifier
- **start**: `{module, function, args}` to start process
- **restart**: `:permanent` | `:temporary` | `:transient`
- **shutdown**: Timeout or `:brutal_kill`
- **type**: `:worker` | `:supervisor`

## Restart Values

```elixir
# :permanent - Always restart (default)
restart: :permanent

# :temporary - Never restart
restart: :temporary

# :transient - Restart only if crash is abnormal
restart: :transient
```

## DevOps Example: Service Monitor

```elixir
defmodule ServiceMonitor.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Config server - must be first
      {ServiceMonitor.Config, []},
      
      # Health checkers
      {ServiceMonitor.HealthChecker, [name: :api_checker, url: "http://api/health"]},
      {ServiceMonitor.HealthChecker, [name: :web_checker, url: "http://web/health"]},
      
      # Metrics collector
      {ServiceMonitor.MetricsCollector, []},
      
      # Alert manager
      {ServiceMonitor.AlertManager, []},
      
      # HTTP API
      {Plug.Cowboy, scheme: :http, plug: ServiceMonitor.Router, options: [port: 4000]}
    ]

    opts = [strategy: :one_for_one, name: ServiceMonitor.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

## Dynamic Supervisors

For dynamically starting and stopping children.

```elixir
defmodule JobSupervisor do
  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
  
  # Start a child dynamically
  def start_job(job_params) do
    child_spec = {Job, job_params}
    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end
  
  # Stop a child
  def stop_job(pid) do
    DynamicSupervisor.terminate_child(__MODULE__, pid)
  end
end
```

**DevOps Example**: Dynamic worker pool

```elixir
defmodule DeploymentManager do
  use DynamicSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_deployment(service, version) do
    spec = {DeploymentWorker, %{service: service, version: version}}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def list_deployments do
    DynamicSupervisor.which_children(__MODULE__)
  end
end
```

## Task Supervisor

Special supervisor for supervised tasks.

```elixir
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      {Task.Supervisor, name: MyApp.TaskSupervisor}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end

# Use it
Task.Supervisor.start_child(MyApp.TaskSupervisor, fn ->
  perform_background_work()
end)

# Async with await
task = Task.Supervisor.async(MyApp.TaskSupervisor, fn ->
  expensive_computation()
end)
result = Task.await(task)
```

## Applications

An Application is the top-level unit of organization.

### Defining an Application

```elixir
defmodule MyApp.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # List of workers/supervisors
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

### In mix.exs

```elixir
def application do
  [
    extra_applications: [:logger, :httpoison],
    mod: {MyApp.Application, []}
  ]
end
```

## Real-World Example: Complete Application

```elixir
# lib/infra_monitor/application.ex
defmodule InfraMonitor.Application do
  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    Logger.info("Starting InfraMonitor...")

    children = [
      # Configuration
      {InfraMonitor.Config, Application.get_env(:infra_monitor, :config, %{})},
      
      # Task supervisor for background jobs
      {Task.Supervisor, name: InfraMonitor.TaskSupervisor},
      
      # Dynamic supervisor for health checkers
      {DynamicSupervisor, name: InfraMonitor.CheckerSupervisor, strategy: :one_for_one},
      
      # Core services
      {InfraMonitor.MetricsStore, []},
      {InfraMonitor.AlertManager, []},
      
      # Service discovery
      {InfraMonitor.ServiceRegistry, []},
      
      # Periodic tasks
      {InfraMonitor.PeriodicChecker, interval: 30_000},
      
      # Web interface
      InfraMonitor.Web.Endpoint
    ]

    opts = [
      strategy: :one_for_one,
      name: InfraMonitor.Supervisor,
      max_restarts: 10,
      max_seconds: 5
    ]

    case Supervisor.start_link(children, opts) do
      {:ok, pid} ->
        start_health_checkers()
        {:ok, pid}
        
      {:error, reason} ->
        Logger.error("Failed to start application: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp start_health_checkers do
    services = InfraMonitor.Config.get(:services, [])
    
    Enum.each(services, fn service ->
      spec = {InfraMonitor.HealthChecker, service}
      DynamicSupervisor.start_child(InfraMonitor.CheckerSupervisor, spec)
    end)
  end
end

# lib/infra_monitor/health_checker.ex
defmodule InfraMonitor.HealthChecker do
  use GenServer, restart: :transient
  require Logger

  def start_link(service) do
    GenServer.start_link(__MODULE__, service, name: via_tuple(service.name))
  end

  @impl true
  def init(service) do
    schedule_check(0)  # Check immediately
    {:ok, %{service: service, failures: 0, status: :unknown}}
  end

  @impl true
  def handle_info(:check, state) do
    case perform_check(state.service.url) do
      {:ok, response_time} ->
        InfraMonitor.MetricsStore.record(state.service.name, :healthy, response_time)
        schedule_check(state.service.interval)
        {:noreply, %{state | failures: 0, status: :healthy}}
        
      {:error, reason} ->
        new_failures = state.failures + 1
        
        if new_failures >= 3 do
          Logger.error("Service #{state.service.name} is down: #{inspect(reason)}")
          InfraMonitor.AlertManager.alert(state.service.name, :down, reason)
        end
        
        schedule_check(state.service.interval)
        {:noreply, %{state | failures: new_failures, status: :unhealthy}}
    end
  end

  defp perform_check(url) do
    start = System.monotonic_time(:millisecond)
    
    case HTTPoison.get(url, [], timeout: 5000) do
      {:ok, %{status_code: 200}} ->
        {:ok, System.monotonic_time(:millisecond) - start}
      {:ok, %{status_code: code}} ->
        {:error, {:bad_status, code}}
      {:error, %{reason: reason}} ->
        {:error, reason}
    end
  end

  defp schedule_check(delay) do
    Process.send_after(self(), :check, delay)
  end

  defp via_tuple(name) do
    {:via, Registry, {InfraMonitor.Registry, name}}
  end
end
```

## Supervisor Utilities

```elixir
# Which children are running?
Supervisor.which_children(MySupervisor)

# Count children
Supervisor.count_children(MySupervisor)

# Stop a child
Supervisor.terminate_child(MySupervisor, child_id)

# Restart a child
Supervisor.restart_child(MySupervisor, child_id)

# Delete child spec
Supervisor.delete_child(MySupervisor, child_id)
```

## Best Practices

1. **Let It Crash**: Don't be defensive, use supervision
2. **Fail Fast**: Don't hide errors
3. **One Supervisor Per Level**: Clear hierarchy
4. **Restart Strategically**: Choose appropriate restart strategy
5. **Name Your Processes**: Easier debugging
6. **Limit Restarts**: Set `max_restarts` and `max_seconds`

## Common Patterns

### Service with Supervision

```elixir
defmodule MyService do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    children = [
      {MyService.Worker, []},
      {MyService.Cache, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
```

### Worker Pool

```elixir
defmodule WorkerPool do
  use Supervisor

  def start_link(size) do
    Supervisor.start_link(__MODULE__, size, name: __MODULE__)
  end

  def init(size) do
    children = Enum.map(1..size, fn i ->
      Supervisor.child_spec({Worker, []}, id: {Worker, i})
    end)

    Supervisor.init(children, strategy: :one_for_one)
  end
end
```

## Key Takeaways

1. **Supervisors**: Monitor and restart processes
2. **Strategies**: :one_for_one, :one_for_all, :rest_for_one
3. **Applications**: Top-level organizational unit
4. **Dynamic Supervisors**: For runtime children
5. **Let it crash**: Embrace failure, use supervision

## What's Next?

- [Mix Projects & Dependencies](04-mix-projects.md)
- [Testing with ExUnit](05-testing.md)

## Additional Resources

- [Supervisor Documentation](https://hexdocs.pm/elixir/Supervisor.html)
- [Application Documentation](https://hexdocs.pm/elixir/Application.html)
- [Learn You Some Erlang - Supervisors](http://learnyousomeerlang.com/supervisors)

