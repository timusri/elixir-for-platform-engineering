# OTP: GenServer

## Overview

GenServer (Generic Server) is one of the most important OTP behaviors. It provides a standard way to build server processes that maintain state, handle requests, and recover from failures.

### What is OTP?

OTP (Open Telecom Platform) is a set of libraries and design principles for building robust, fault-tolerant systems. Despite the name, it's used far beyond telecom!

**OTP Behaviors** are templates for common patterns:
- **GenServer**: Server processes (most common)
- **Supervisor**: Monitors and restarts processes
- **Application**: Application lifecycle
- **GenStateMachine**: State machines
- **Task**: Async computation

## Why GenServer?

Instead of manual `spawn`, `send`, `receive`, GenServer provides:
- Standard interface for client/server communication
- Automatic message handling
- Built-in timeout handling
- Integration with supervision trees
- Debugging and introspection tools
- Code upgrade support

## Basic GenServer Structure

```elixir
defmodule MyServer do
  use GenServer

  # Client API (public interface)
  
  def start_link(initial_state) do
    GenServer.start_link(__MODULE__, initial_state, name: __MODULE__)
  end
  
  def get_state do
    GenServer.call(__MODULE__, :get_state)
  end
  
  # Server Callbacks (private implementation)
  
  @impl true
  def init(initial_state) do
    {:ok, initial_state}
  end
  
  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end
end
```

## Starting a GenServer

### start_link/3

```elixir
{:ok, pid} = GenServer.start_link(MyServer, initial_state)

# With name registration
GenServer.start_link(MyServer, initial_state, name: :my_server)
GenServer.start_link(MyServer, initial_state, name: MyServer)
```

## The init/1 Callback

Called when GenServer starts. Initialize state here.

```elixir
@impl true
def init(initial_args) do
  # Setup code
  state = process_args(initial_args)
  {:ok, state}
end

# Or return error
def init(_args) do
  {:stop, :initialization_failed}
end

# Or with timeout
def init(args) do
  {:ok, args, 5000}  # Send :timeout after 5 seconds
end
```

**DevOps Example**: Health checker initialization

```elixir
defmodule HealthChecker do
  use GenServer
  
  def start_link(urls) do
    GenServer.start_link(__MODULE__, urls, name: __MODULE__)
  end
  
  @impl true
  def init(urls) do
    # Schedule first check
    schedule_check()
    
    initial_state = %{
      urls: urls,
      statuses: %{},
      check_interval: 30_000
    }
    
    {:ok, initial_state}
  end
  
  defp schedule_check do
    Process.send_after(self(), :perform_check, 1000)
  end
end
```

## Synchronous Calls: handle_call/3

Use `call` for synchronous requests where you need a response.

```elixir
# Client
def get_status(server) do
  GenServer.call(server, :get_status)
end

# Server
@impl true
def handle_call(:get_status, _from, state) do
  {:reply, state.status, state}
end
```

**The response tuple**:
- `{:reply, reply, new_state}` - Send reply, update state
- `{:reply, reply, new_state, timeout}` - With timeout
- `{:noreply, new_state}` - Reply manually later
- `{:stop, reason, reply, new_state}` - Reply and stop
- `{:stop, reason, new_state}` - Stop without reply

**DevOps Example**: Configuration server

```elixir
defmodule ConfigServer do
  use GenServer
  
  # Client API
  
  def start_link(initial_config) do
    GenServer.start_link(__MODULE__, initial_config, name: __MODULE__)
  end
  
  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end
  
  def set(key, value) do
    GenServer.call(__MODULE__, {:set, key, value})
  end
  
  def get_all do
    GenServer.call(__MODULE__, :get_all)
  end
  
  # Server Callbacks
  
  @impl true
  def init(initial_config) do
    {:ok, initial_config}
  end
  
  @impl true
  def handle_call({:get, key}, _from, state) do
    value = Map.get(state, key)
    {:reply, value, state}
  end
  
  @impl true
  def handle_call({:set, key, value}, _from, state) do
    new_state = Map.put(state, key, value)
    {:reply, :ok, new_state}
  end
  
  @impl true
  def handle_call(:get_all, _from, state) do
    {:reply, state, state}
  end
end
```

## Asynchronous Casts: handle_cast/2

Use `cast` for fire-and-forget messages (no response expected).

```elixir
# Client
def update_status(server, new_status) do
  GenServer.cast(server, {:update_status, new_status})
end

# Server
@impl true
def handle_cast({:update_status, new_status}, state) do
  new_state = %{state | status: new_status}
  {:noreply, new_state}
end
```

**The response tuple**:
- `{:noreply, new_state}` - Update state
- `{:noreply, new_state, timeout}` - With timeout
- `{:stop, reason, new_state}` - Stop server

**DevOps Example**: Metrics collector

```elixir
defmodule MetricsCollector do
  use GenServer
  
  # Client API
  
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end
  
  def record(metric_name, value) do
    GenServer.cast(__MODULE__, {:record, metric_name, value})
  end
  
  def get_metrics do
    GenServer.call(__MODULE__, :get_metrics)
  end
  
  # Server Callbacks
  
  @impl true
  def init(_) do
    {:ok, %{}}
  end
  
  @impl true
  def handle_cast({:record, metric_name, value}, state) do
    new_state = Map.update(
      state,
      metric_name,
      [value],
      fn existing -> [value | existing] |> Enum.take(100) end
    )
    {:noreply, new_state}
  end
  
  @impl true
  def handle_call(:get_metrics, _from, state) do
    {:reply, state, state}
  end
end
```

## Handle Info: handle_info/2

Handle messages sent with `send` or system messages.

```elixir
@impl true
def handle_info(:scheduled_task, state) do
  perform_task()
  schedule_next_task()
  {:noreply, state}
end

@impl true
def handle_info({:DOWN, _ref, :process, _pid, _reason}, state) do
  # Handle monitored process crash
  {:noreply, state}
end
```

**DevOps Example**: Periodic health checker

```elixir
defmodule PeriodicHealthChecker do
  use GenServer
  require Logger
  
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  def get_status do
    GenServer.call(__MODULE__, :get_status)
  end
  
  @impl true
  def init(opts) do
    urls = Keyword.get(opts, :urls, [])
    interval = Keyword.get(opts, :interval, 30_000)
    
    # Schedule first check
    schedule_check(interval)
    
    state = %{
      urls: urls,
      interval: interval,
      statuses: %{}
    }
    
    {:ok, state}
  end
  
  @impl true
  def handle_info(:perform_check, state) do
    Logger.info("Performing health checks...")
    
    new_statuses = Enum.reduce(state.urls, %{}, fn url, acc ->
      status = check_url(url)
      Map.put(acc, url, status)
    end)
    
    # Schedule next check
    schedule_check(state.interval)
    
    {:noreply, %{state | statuses: new_statuses}}
  end
  
  @impl true
  def handle_call(:get_status, _from, state) do
    {:reply, state.statuses, state}
  end
  
  defp schedule_check(interval) do
    Process.send_after(self(), :perform_check, interval)
  end
  
  defp check_url(url) do
    case HTTPoison.get(url, [], timeout: 5000) do
      {:ok, %{status_code: 200}} -> :healthy
      {:ok, %{status_code: _}} -> :unhealthy
      {:error, _} -> :unreachable
    end
  end
end
```

## Timeouts

```elixir
@impl true
def init(state) do
  {:ok, state, 5000}  # Timeout after 5 seconds
end

@impl true
def handle_info(:timeout, state) do
  # Handle timeout
  {:noreply, state}
end
```

## Termination: terminate/2

Called before GenServer stops (cleanup).

```elixir
@impl true
def terminate(reason, state) do
  Logger.info("Shutting down: #{inspect(reason)}")
  cleanup_resources(state)
  :ok
end
```

**DevOps Example**: Close connections

```elixir
defmodule DatabasePool do
  use GenServer
  
  @impl true
  def init(opts) do
    connections = Enum.map(1..10, fn _ -> 
      {:ok, conn} = Database.connect(opts)
      conn
    end)
    {:ok, %{connections: connections}}
  end
  
  @impl true
  def terminate(_reason, state) do
    Enum.each(state.connections, &Database.close/1)
    :ok
  end
end
```

## Name Registration

```elixir
# Local name (atom)
GenServer.start_link(MyServer, [], name: MyServer)
GenServer.call(MyServer, :get_state)

# Via tuple (Registry)
GenServer.start_link(MyServer, [], name: {:via, Registry, {MyRegistry, "key"}})

# Global name (distributed)
GenServer.start_link(MyServer, [], name: {:global, :my_server})
```

## Real-World Example: Service Monitor

```elixir
defmodule ServiceMonitor do
  use GenServer
  require Logger
  
  defstruct [
    :services,
    :check_interval,
    :consecutive_failures,
    :max_failures
  ]
  
  # Client API
  
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  def add_service(name, url) do
    GenServer.call(__MODULE__, {:add_service, name, url})
  end
  
  def remove_service(name) do
    GenServer.call(__MODULE__, {:remove_service, name})
  end
  
  def get_status do
    GenServer.call(__MODULE__, :get_status)
  end
  
  def get_service_status(name) do
    GenServer.call(__MODULE__, {:get_service_status, name})
  end
  
  # Server Callbacks
  
  @impl true
  def init(opts) do
    check_interval = Keyword.get(opts, :check_interval, 30_000)
    max_failures = Keyword.get(opts, :max_failures, 3)
    
    schedule_check(check_interval)
    
    state = %__MODULE__{
      services: %{},
      check_interval: check_interval,
      consecutive_failures: %{},
      max_failures: max_failures
    }
    
    {:ok, state}
  end
  
  @impl true
  def handle_call({:add_service, name, url}, _from, state) do
    service = %{
      url: url,
      status: :unknown,
      last_check: nil,
      response_time: nil
    }
    
    new_services = Map.put(state.services, name, service)
    {:reply, :ok, %{state | services: new_services}}
  end
  
  @impl true
  def handle_call({:remove_service, name}, _from, state) do
    new_services = Map.delete(state.services, name)
    {:reply, :ok, %{state | services: new_services}}
  end
  
  @impl true
  def handle_call(:get_status, _from, state) do
    status = Enum.map(state.services, fn {name, service} ->
      {name, %{
        status: service.status,
        last_check: service.last_check,
        response_time: service.response_time
      }}
    end)
    |> Map.new()
    
    {:reply, status, state}
  end
  
  @impl true
  def handle_call({:get_service_status, name}, _from, state) do
    service = Map.get(state.services, name)
    {:reply, service, state}
  end
  
  @impl true
  def handle_info(:perform_check, state) do
    Logger.debug("Performing health checks")
    
    {new_services, new_failures} = 
      Enum.reduce(state.services, {%{}, state.consecutive_failures}, 
        fn {name, service}, {services_acc, failures_acc} ->
          {updated_service, updated_failures} = 
            check_service(name, service, failures_acc, state.max_failures)
          
          {
            Map.put(services_acc, name, updated_service),
            updated_failures
          }
        end
      )
    
    schedule_check(state.check_interval)
    
    {:noreply, %{state | 
      services: new_services,
      consecutive_failures: new_failures
    }}
  end
  
  # Private Functions
  
  defp schedule_check(interval) do
    Process.send_after(self(), :perform_check, interval)
  end
  
  defp check_service(name, service, failures, max_failures) do
    start_time = System.monotonic_time(:millisecond)
    
    case HTTPoison.get(service.url, [], timeout: 5000, recv_timeout: 5000) do
      {:ok, %{status_code: 200}} ->
        response_time = System.monotonic_time(:millisecond) - start_time
        
        updated_service = %{service |
          status: :healthy,
          last_check: DateTime.utc_now(),
          response_time: response_time
        }
        
        # Reset failure count
        updated_failures = Map.put(failures, name, 0)
        
        Logger.info("#{name} is healthy (#{response_time}ms)")
        {updated_service, updated_failures}
        
      {:ok, %{status_code: code}} ->
        handle_failure(name, service, failures, max_failures, {:bad_status, code})
        
      {:error, %{reason: reason}} ->
        handle_failure(name, service, failures, max_failures, reason)
    end
  end
  
  defp handle_failure(name, service, failures, max_failures, reason) do
    current_failures = Map.get(failures, name, 0) + 1
    updated_failures = Map.put(failures, name, current_failures)
    
    status = if current_failures >= max_failures, do: :critical, else: :degraded
    
    updated_service = %{service |
      status: status,
      last_check: DateTime.utc_now(),
      response_time: nil
    }
    
    Logger.warn("#{name} check failed (#{current_failures}/#{max_failures}): #{inspect(reason)}")
    
    if status == :critical do
      Logger.error("#{name} is CRITICAL")
      # Could trigger alerts here
    end
    
    {updated_service, updated_failures}
  end
end

# Usage
{:ok, _pid} = ServiceMonitor.start_link(check_interval: 30_000, max_failures: 3)
ServiceMonitor.add_service("api", "http://api.example.com/health")
ServiceMonitor.add_service("web", "http://web.example.com/health")
ServiceMonitor.get_status()
```

## Best Practices

1. **Separate client and server**: Clear public API
2. **Use `@impl true`**: Documents callbacks
3. **Keep callbacks fast**: Don't block the GenServer
4. **Use `cast` when possible**: Async is faster
5. **Handle all messages**: Catch-all `handle_info`
6. **Name your processes**: Easier debugging
7. **Use structs for state**: Better documentation

## Common Patterns

### Request with Timeout

```elixir
def get_data(server, timeout \\ 5000) do
  GenServer.call(server, :get_data, timeout)
end
```

### Background Tasks

```elixir
@impl true
def handle_info(:background_task, state) do
  Task.start(fn -> expensive_operation() end)
  schedule_next()
  {:noreply, state}
end
```

### Caching

```elixir
@impl true
def handle_call({:get, key}, _from, state) do
  case Map.get(state.cache, key) do
    nil ->
      value = fetch_from_source(key)
      new_cache = Map.put(state.cache, key, value)
      {:reply, value, %{state | cache: new_cache}}
    value ->
      {:reply, value, state}
  end
end
```

## Exercises

1. Build a simple key-value store GenServer
2. Create a rate limiter GenServer
3. Implement a GenServer that batches requests
4. Build a connection pool GenServer

## Key Takeaways

1. **GenServer**: Standard for stateful processes
2. **call**: Synchronous, returns response
3. **cast**: Asynchronous, no response
4. **handle_info**: For all other messages
5. **init**: Setup and return initial state
6. **terminate**: Cleanup before shutdown

## What's Next?

Now let's learn about supervision trees for fault tolerance:
- [OTP: Supervisors & Applications](03-otp-supervisor.md)

## Additional Resources

- [GenServer Documentation](https://hexdocs.pm/elixir/GenServer.html)
- [Elixir School - OTP Concurrency](https://elixirschool.com/en/lessons/advanced/otp_concurrency)
- [Learn You Some Erlang - GenServer](http://learnyousomeerlang.com/clients-and-servers)

