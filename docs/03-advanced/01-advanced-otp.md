# Advanced OTP Patterns

## Overview

Beyond GenServer and Supervisor, OTP provides several specialized behaviors for common patterns. This chapter explores Agent, Task, GenStateMachine, and advanced supervision strategies.

## Agent

Agent provides a simple abstraction for managing state.

### When to Use Agent

- Simple state storage (no complex logic)
- Shared configuration
- Caching
- Counters and accumulators

### Basic Usage

```elixir
# Start an agent
{:ok, agent} = Agent.start_link(fn -> %{} end)

# Get state
Agent.get(agent, fn state -> state end)

# Update state
Agent.update(agent, fn state -> Map.put(state, :key, "value") end)

# Get and update in one operation
Agent.get_and_update(agent, fn state ->
  {state.counter, %{state | counter: state.counter + 1}}
end)
```

### DevOps Example: Configuration Cache

```elixir
defmodule ConfigCache do
  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def put(key, value) do
    Agent.update(__MODULE__, &Map.put(&1, key, value))
  end

  def get(key, default \\ nil) do
    Agent.get(__MODULE__, &Map.get(&1, key, default))
  end

  def get_all do
    Agent.get(__MODULE__, & &1)
  end

  def clear do
    Agent.update(__MODULE__, fn _ -> %{} end)
  end
end
```

## Task

Task provides abstractions for async computation.

### Task.async/await

```elixir
task = Task.async(fn ->
  # Expensive computation
  HTTPoison.get("https://api.example.com/data")
end)

result = Task.await(task, 5000)
```

### Parallel Processing

```elixir
urls = ["url1", "url2", "url3"]

results = urls
|> Enum.map(&Task.async(fn -> fetch(&1) end))
|> Enum.map(&Task.await(&1, 10_000))
```

### DevOps Example: Concurrent Deployment Checks

```elixir
defmodule DeploymentChecker do
  def check_all_environments(service, version) do
    environments = ["dev", "staging", "prod"]
    
    tasks = Enum.map(environments, fn env ->
      Task.async(fn ->
        {env, check_deployment(service, version, env)}
      end)
    end)
    
    Enum.map(tasks, &Task.await(&1, 30_000))
  end
  
  defp check_deployment(service, version, env) do
    url = "https://#{env}.example.com/#{service}/version"
    
    case HTTPoison.get(url) do
      {:ok, %{body: ^version}} -> :match
      {:ok, %{body: other}} -> {:mismatch, other}
      {:error, reason} -> {:error, reason}
    end
  end
end
```

### Task.Supervisor

For supervised tasks that might fail:

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
Task.Supervisor.async_nolink(MyApp.TaskSupervisor, fn ->
  risky_operation()
end)
```

## GenStateMachine

For complex state machines with explicit states and transitions.

### Basic Structure

```elixir
defmodule Deployment do
  use GenStateMachine

  # States: :idle, :deploying, :verifying, :completed, :failed

  def start_link(opts) do
    GenStateMachine.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, :idle, %{attempts: 0}}
  end

  @impl true
  def handle_event({:call, from}, :deploy, :idle, data) do
    # Start deployment
    send(self(), :do_deploy)
    {:next_state, :deploying, data, [{:reply, from, :ok}]}
  end

  def handle_event(:info, :do_deploy, :deploying, data) do
    case perform_deploy() do
      :ok ->
        send(self(), :verify)
        {:next_state, :verifying, data}
      {:error, _} ->
        {:next_state, :failed, data}
    end
  end

  def handle_event(:info, :verify, :verifying, data) do
    case verify_deployment() do
      :ok -> {:next_state, :completed, data}
      {:error, _} -> {:next_state, :failed, data}
    end
  end
end
```

### DevOps Example: Circuit Breaker

```elixir
defmodule CircuitBreaker do
  use GenStateMachine
  
  # States: :closed (normal), :open (failing), :half_open (testing)

  defstruct [
    :service,
    :failure_threshold,
    :timeout,
    :failures,
    :last_failure_time
  ]

  def start_link(opts) do
    GenStateMachine.start_link(__MODULE__, opts, name: via(opts[:service]))
  end

  def call(service, request) do
    GenStateMachine.call(via(service), {:request, request})
  end

  @impl true
  def init(opts) do
    state = %__MODULE__{
      service: opts[:service],
      failure_threshold: opts[:threshold] || 5,
      timeout: opts[:timeout] || 60_000,
      failures: 0,
      last_failure_time: nil
    }
    
    {:ok, :closed, state}
  end

  @impl true
  def handle_event({:call, from}, {:request, request}, :closed, data) do
    case perform_request(data.service, request) do
      {:ok, result} ->
        {:keep_state, %{data | failures: 0}, [{:reply, from, {:ok, result}}]}
      {:error, reason} ->
        new_failures = data.failures + 1
        
        if new_failures >= data.failure_threshold do
          schedule_half_open(data.timeout)
          {:next_state, :open, 
            %{data | failures: new_failures, last_failure_time: now()},
            [{:reply, from, {:error, :circuit_open}}]}
        else
          {:keep_state, %{data | failures: new_failures},
            [{:reply, from, {:error, reason}}]}
        end
    end
  end

  def handle_event({:call, from}, {:request, _}, :open, data) do
    {:keep_state_and_data, [{:reply, from, {:error, :circuit_open}}]}
  end

  def handle_event({:call, from}, {:request, request}, :half_open, data) do
    case perform_request(data.service, request) do
      {:ok, result} ->
        {:next_state, :closed, %{data | failures: 0},
          [{:reply, from, {:ok, result}}]}
      {:error, reason} ->
        schedule_half_open(data.timeout)
        {:next_state, :open, %{data | last_failure_time: now()},
          [{:reply, from, {:error, :circuit_open}}]}
    end
  end

  def handle_event(:info, :try_half_open, :open, data) do
    {:next_state, :half_open, data}
  end

  defp schedule_half_open(timeout) do
    Process.send_after(self(), :try_half_open, timeout)
  end

  defp now, do: System.system_time(:millisecond)
  defp via(name), do: {:via, Registry, {CircuitBreaker.Registry, name}}
end
```

## ETS (Erlang Term Storage)

In-memory database for high-performance lookups.

### Basic Usage

```elixir
# Create table
:ets.new(:my_table, [:set, :public, :named_table])

# Insert
:ets.insert(:my_table, {"key", "value"})

# Lookup
:ets.lookup(:my_table, "key")

# Delete
:ets.delete(:my_table, "key")
```

### DevOps Example: Rate Limiter

```elixir
defmodule RateLimiter do
  def start_link do
    :ets.new(__MODULE__, [:set, :public, :named_table])
    {:ok, self()}
  end

  def check_rate(identifier, limit, window_seconds) do
    now = System.system_time(:second)
    window_start = now - window_seconds
    
    case :ets.lookup(__MODULE__, identifier) do
      [] ->
        :ets.insert(__MODULE__, {identifier, [{now, 1}]})
        {:ok, 1}
      
      [{^identifier, requests}] ->
        recent_requests = Enum.filter(requests, fn {ts, _} -> 
          ts > window_start 
        end)
        
        count = Enum.sum(Enum.map(recent_requests, fn {_, c} -> c end))
        
        if count >= limit do
          {:error, :rate_limit_exceeded, count}
        else
          :ets.insert(__MODULE__, {identifier, [{now, count + 1} | recent_requests]})
          {:ok, count + 1}
        end
    end
  end
end
```

## Registry

Process registry for dynamic process naming.

```elixir
# Start registry
{:ok, _} = Registry.start_link(keys: :unique, name: MyApp.Registry)

# Register process
{:ok, _} = Registry.register(MyApp.Registry, "my_key", [])

# Lookup
Registry.lookup(MyApp.Registry, "my_key")

# Via tuple for GenServer
GenServer.start_link(MyWorker, args, 
  name: {:via, Registry, {MyApp.Registry, "worker_1"}})
```

## DynamicSupervisor Advanced Patterns

### Worker Pool

```elixir
defmodule WorkerPool do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    pool_size = Keyword.get(opts, :size, 10)
    
    children = [
      {DynamicSupervisor, name: WorkerPool.Supervisor, strategy: :one_for_one}
    ]
    
    Supervisor.init(children, strategy: :one_for_one)
  end

  def checkout do
    # Get least loaded worker
    workers = DynamicSupervisor.which_children(WorkerPool.Supervisor)
    
    workers
    |> Enum.map(fn {_, pid, _, _} -> {pid, get_load(pid)} end)
    |> Enum.min_by(fn {_, load} -> load end)
    |> elem(0)
  end

  defp get_load(pid) do
    {:message_queue_len, len} = Process.info(pid, :message_queue_len)
    len
  end
end
```

## Key Takeaways

1. **Agent**: Simple state management
2. **Task**: Async computations
3. **GenStateMachine**: Complex state machines
4. **ETS**: High-performance in-memory storage
5. **Registry**: Dynamic process naming
6. **Circuit Breaker**: Protect failing services

## What's Next?

- [Distribution & Clustering](02-distribution.md)
- [Metaprogramming & Macros](03-metaprogramming.md)

## Additional Resources

- [Agent Documentation](https://hexdocs.pm/elixir/Agent.html)
- [Task Documentation](https://hexdocs.pm/elixir/Task.html)
- [GenStateMachine](https://hexdocs.pm/gen_state_machine/)
- [ETS Guide](http://erlang.org/doc/man/ets.html)

