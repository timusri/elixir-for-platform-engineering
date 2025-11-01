# Fault-Tolerant System Design

## Overview

Building systems that never stop is the hallmark of Elixir/OTP. This chapter covers strategies for designing and implementing truly fault-tolerant systems.

## The "Let It Crash" Philosophy

Instead of defensive programming, embrace failure and recovery:

```elixir
# Don't do this
def risky_operation(data) do
  try do
    validate(data)
    process(data)
    save(data)
  rescue
    e -> Logger.error("Failed: #{inspect(e)}")
           {:error, e}
  end
end

# Do this instead
def risky_operation(data) do
  validate!(data)    # Let it crash if invalid
  process!(data)     # Let it crash if processing fails
  save!(data)        # Let it crash if save fails
end
# Supervisor will restart the process
```

## Supervision Strategies

### Restart Intensity

Limit how many restarts are allowed:

```elixir
Supervisor.init(children,
  strategy: :one_for_one,
  max_restarts: 3,      # Max 3 restarts
  max_seconds: 5        # Within 5 seconds
)
# If exceeded, supervisor itself terminates
```

### Multiple Supervision Layers

```elixir
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      # Critical services - restart always
      {MyApp.Database, []},
      
      # Worker supervisor
      {MyApp.WorkerSupervisor, []},
      
      # API supervisor
      {MyApp.APISupervisor, []}
    ]

    Supervisor.start_link(children,
      strategy: :one_for_one,
      max_restarts: 10,
      max_seconds: 60
    )
  end
end

defmodule MyApp.WorkerSupervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_) do
    children = [
      # Workers with more lenient restart policy
      {MyApp.Worker, restart: :transient}
    ]

    Supervisor.init(children,
      strategy: :one_for_one,
      max_restarts: 5,
      max_seconds: 10
    )
  end
end
```

## Circuit Breakers

Protect failing external services:

```elixir
defmodule CircuitBreaker do
  use GenServer

  defstruct [:service, :state, :failures, :last_failure, :threshold, :timeout]

  # States: :closed, :open, :half_open

  def call(service, request) do
    GenServer.call(via(service), {:request, request})
  end

  def init(opts) do
    state = %__MODULE__{
      service: opts[:service],
      state: :closed,
      failures: 0,
      threshold: opts[:threshold] || 5,
      timeout: opts[:timeout] || 60_000
    }
    {:ok, state}
  end

  def handle_call({:request, req}, _from, %{state: :open} = state) do
    if should_try_again?(state) do
      {:reply, :retry, %{state | state: :half_open}}
    else
      {:reply, {:error, :circuit_open}, state}
    end
  end

  def handle_call({:request, req}, _from, state) do
    case perform_request(req) do
      {:ok, result} ->
        {:reply, {:ok, result}, %{state | failures: 0, state: :closed}}
      
      {:error, reason} ->
        new_failures = state.failures + 1
        
        if new_failures >= state.threshold do
          schedule_retry(state.timeout)
          {:reply, {:error, :circuit_open},
           %{state | state: :open, failures: new_failures}}
        else
          {:reply, {:error, reason},
           %{state | failures: new_failures}}
        end
    end
  end

  defp should_try_again?(state) do
    System.monotonic_time(:millisecond) - state.last_failure > state.timeout
  end
end
```

## Graceful Degradation

System continues with reduced functionality:

```elixir
defmodule ResilientService do
  def get_data(id) do
    case Database.fetch(id) do
      {:ok, data} -> {:ok, data}
      {:error, _} -> 
        # Fallback to cache
        case Cache.get(id) do
          {:ok, cached} -> {:ok, cached, :from_cache}
          {:error, _} -> {:ok, default_data(id), :default}
        end
    end
  end

  defp default_data(id) do
    %{id: id, status: :unknown, message: "Service degraded"}
  end
end
```

## Health Checks

Comprehensive health monitoring:

```elixir
defmodule HealthCheck do
  def check_system do
    checks = [
      check_database(),
      check_redis(),
      check_external_api(),
      check_disk_space(),
      check_memory()
    ]

    status = if Enum.all?(checks, &match?({:ok, _}, &1)) do
      :healthy
    else
      :degraded
    end

    %{
      status: status,
      checks: format_checks(checks),
      timestamp: DateTime.utc_now()
    }
  end

  defp check_database do
    case Ecto.Adapters.SQL.query(MyApp.Repo, "SELECT 1") do
      {:ok, _} -> {:ok, :database}
      {:error, e} -> {:error, {:database, e}}
    end
  end

  defp check_memory do
    memory = :erlang.memory(:total)
    limit = 1_000_000_000  # 1GB
    
    if memory < limit do
      {:ok, {:memory, memory}}
    else
      {:error, {:memory, :high, memory}}
    end
  end
end
```

## Bulkheads

Isolate failures using separate process pools:

```elixir
defmodule BulkheadPattern do
  def start_link do
    children = [
      # Separate pools for different operations
      {Task.Supervisor, name: :critical_pool},
      {Task.Supervisor, name: :normal_pool},
      {Task.Supervisor, name: :background_pool}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  def critical_task(fun) do
    Task.Supervisor.async_nolink(:critical_pool, fun)
  end

  def normal_task(fun) do
    Task.Supervisor.async_nolink(:normal_pool, fun)
  end

  def background_task(fun) do
    Task.Supervisor.async_nolink(:background_pool, fun)
  end
end
```

## Backpressure

Handle overload gracefully:

```elixir
defmodule RateLimitedWorker do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def process(item) do
    GenServer.call(__MODULE__, {:process, item})
  end

  def init(opts) do
    max_queue = opts[:max_queue] || 1000
    {:ok, %{queue: :queue.new(), processing: 0, max_queue: max_queue}}
  end

  def handle_call({:process, item}, from, state) do
    if :queue.len(state.queue) >= state.max_queue do
      {:reply, {:error, :overloaded}, state}
    else
      new_queue = :queue.in({item, from}, state.queue)
      send(self(), :process_next)
      {:noreply, %{state | queue: new_queue}}
    end
  end

  def handle_info(:process_next, state) do
    case :queue.out(state.queue) do
      {{:value, {item, from}}, new_queue} ->
        result = do_process(item)
        GenServer.reply(from, result)
        {:noreply, %{state | queue: new_queue}}
      
      {:empty, _} ->
        {:noreply, state}
    end
  end
end
```

## Key Takeaways

1. **Let it crash**: Supervisor handles recovery
2. **Multiple layers**: Supervision hierarchies
3. **Circuit breakers**: Protect failing services
4. **Graceful degradation**: Maintain functionality
5. **Bulkheads**: Isolate failures
6. **Backpressure**: Handle overload

## Additional Resources

- [Designing for Scalability with Erlang/OTP](https://www.oreilly.com/library/view/designing-for-scalability/9781449361556/)
- [Release It!](https://pragprog.com/titles/mnee2/release-it-second-edition/)

