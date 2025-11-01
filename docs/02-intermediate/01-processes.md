# Processes & Message Passing

## Overview

Processes are the foundation of concurrency in Elixir. Unlike OS processes or threads, BEAM processes are lightweight, isolated, and communicate only through message passing. You can create millions of them on a single machine!

## What are Processes?

- **Lightweight**: Each process takes only ~2KB of memory
- **Isolated**: Processes don't share memory
- **Concurrent**: Run independently, scheduled by the BEAM VM
- **Fault-tolerant**: A crashing process doesn't affect others
- **Message-based**: Communicate through asynchronous messages

### Processes vs Threads

| Feature | BEAM Process | OS Thread |
|---------|--------------|-----------|
| Memory | ~2KB | ~1-2MB |
| Creation Time | 1-2 microseconds | Milliseconds |
| Context Switch | Minimal | Expensive |
| Isolation | Complete | Shared memory |
| Crash Impact | Isolated | Can crash app |

## Creating Processes

### spawn/1

```elixir
iex> spawn(fn -> IO.puts("Hello from process!") end)
Hello from process!
#PID<0.108.0>
```

The function runs in a new process and returns a Process ID (PID).

**DevOps Example**: Concurrent health checks

```elixir
defmodule HealthChecker do
  def check_services(urls) do
    Enum.each(urls, fn url ->
      spawn(fn ->
        case HTTP.get(url) do
          {:ok, %{status: 200}} -> 
            IO.puts("✓ #{url} is healthy")
          _ -> 
            IO.puts("✗ #{url} is down")
        end
      end)
    end)
  end
end

# Check 100 services concurrently
HealthChecker.check_services([
  "http://api-1/health",
  "http://api-2/health",
  # ... 98 more
])
```

### spawn/3

```elixir
iex> spawn(IO, :puts, ["Hello"])
Hello
#PID<0.110.0>

# spawn(module, function, arguments)
```

## Message Passing

Processes communicate by sending messages.

### send and receive

```elixir
iex> self()
#PID<0.106.0>

iex> send(self(), {:hello, "world"})
{:hello, "world"}

iex> receive do
...>   {:hello, msg} -> "Received: #{msg}"
...> end
"Received: world"
```

**How it works**:
1. `send(pid, message)` - Puts message in process mailbox
2. `receive` - Pattern matches against mailbox messages
3. If no match, process waits (blocks)

### Simple Example

```elixir
defmodule Echo do
  def start do
    spawn(fn -> loop() end)
  end
  
  defp loop do
    receive do
      {:echo, message, sender} ->
        send(sender, {:ok, message})
        loop()  # Keep listening
        
      :stop ->
        IO.puts("Stopping")
        # Don't loop - process ends
    end
  end
end

# Usage
iex> pid = Echo.start()
#PID<0.112.0>

iex> send(pid, {:echo, "hello", self()})
{:echo, "hello", #PID<0.106.0>}

iex> receive do
...>   {:ok, msg} -> IO.puts("Got: #{msg}")
...> end
Got: hello
:ok
```

**DevOps Example**: Status collector

```elixir
defmodule StatusCollector do
  def start do
    spawn(fn -> loop(%{}) end)
  end
  
  defp loop(statuses) do
    receive do
      {:report, service, status} ->
        new_statuses = Map.put(statuses, service, status)
        IO.puts("#{service}: #{status}")
        loop(new_statuses)
        
      {:get_all, caller} ->
        send(caller, {:statuses, statuses})
        loop(statuses)
        
      :stop ->
        IO.puts("Collector stopping")
    end
  end
end

# Usage
iex> collector = StatusCollector.start()
iex> send(collector, {:report, "api", :healthy})
api: healthy

iex> send(collector, {:get_all, self()})
iex> receive do
...>   {:statuses, s} -> s
...> end
%{"api" => :healthy}
```

## Process Links

Linked processes crash together (useful for fault tolerance).

### spawn_link/1

```elixir
iex> spawn_link(fn -> raise "Oops!" end)
** (EXIT from #PID<0.106.0>) an exception was raised:
    ** (RuntimeError) Oops!
```

The parent process also crashes!

### trap_exit

Convert crashes into messages:

```elixir
defmodule Supervisor do
  def start do
    Process.flag(:trap_exit, true)
    worker = spawn_link(fn -> loop() end)
    supervise(worker)
  end
  
  defp supervise(worker) do
    receive do
      {:EXIT, ^worker, reason} ->
        IO.puts("Worker crashed: #{inspect(reason)}")
        IO.puts("Restarting...")
        new_worker = spawn_link(fn -> loop() end)
        supervise(new_worker)
    end
  end
  
  defp loop do
    # Worker logic
    receive do
      :crash -> raise "Intentional crash"
      msg -> 
        IO.puts("Processing: #{inspect(msg)}")
        loop()
    end
  end
end
```

## Process Monitors

Like links, but one-directional (only monitor knows about the link).

```elixir
iex> pid = spawn(fn -> :timer.sleep(1000) end)
iex> Process.monitor(pid)
#Reference<...>

iex> receive do
...>   {:DOWN, _ref, :process, _pid, reason} -> 
...>     IO.puts("Process exited: #{reason}")
...> end
Process exited: normal
```

**DevOps Example**: Monitor worker processes

```elixir
defmodule WorkerMonitor do
  def start_workers(count) do
    Enum.each(1..count, fn i ->
      pid = spawn(fn -> worker_loop(i) end)
      Process.monitor(pid)
    end)
    
    monitor_loop()
  end
  
  defp monitor_loop do
    receive do
      {:DOWN, _ref, :process, _pid, reason} ->
        IO.puts("Worker died: #{inspect(reason)}")
        # Could restart here
        monitor_loop()
    end
  end
  
  defp worker_loop(id) do
    IO.puts("Worker #{id} working...")
    :timer.sleep(1000)
    worker_loop(id)
  end
end
```

## Process Registry

Register processes with names:

```elixir
iex> pid = spawn(fn -> :timer.sleep(10000) end)
iex> Process.register(pid, :my_process)
true

iex> Process.whereis(:my_process)
#PID<...>

iex> send(:my_process, :message)
:message
```

**DevOps Example**: Named health checker

```elixir
defmodule HealthChecker do
  def start_link do
    pid = spawn_link(fn -> loop() end)
    Process.register(pid, :health_checker)
    {:ok, pid}
  end
  
  def check(service) do
    send(:health_checker, {:check, service, self()})
    receive do
      {:result, status} -> status
    after
      5000 -> {:error, :timeout}
    end
  end
  
  defp loop do
    receive do
      {:check, service, caller} ->
        status = perform_check(service)
        send(caller, {:result, status})
        loop()
    end
  end
  
  defp perform_check(service) do
    # Check logic
    :healthy
  end
end
```

## Process Information

```elixir
# Get current process PID
iex> self()
#PID<0.106.0>

# Check if process is alive
iex> Process.alive?(pid)
true

# Get process info
iex> Process.info(self())
[
  current_function: {:erl_eval, :do_apply, 6},
  initial_call: {:erlang, :apply, 2},
  status: :running,
  message_queue_len: 0,
  # ... more
]

# Get specific info
iex> Process.info(self(), :message_queue_len)
{:message_queue_len, 0}
```

## Timeouts in receive

```elixir
receive do
  {:ok, result} -> result
  {:error, reason} -> reason
after
  5000 -> :timeout
end
```

**DevOps Example**: Request with timeout

```elixir
defmodule API do
  def call(service, request, timeout \\ 5000) do
    send(service, {request, self()})
    
    receive do
      {:response, data} -> {:ok, data}
      {:error, reason} -> {:error, reason}
    after
      timeout -> {:error, :timeout}
    end
  end
end
```

## Task Module (Higher-Level)

`Task` provides a higher-level abstraction over processes:

```elixir
# Fire and forget
iex> Task.start(fn -> IO.puts("Background work") end)
Background work
{:ok, #PID<0.115.0>}

# Await result
iex> task = Task.async(fn -> 1 + 1 end)
%Task{...}
iex> Task.await(task)
2
```

**DevOps Example**: Parallel health checks

```elixir
defmodule ParallelHealthChecker do
  def check_all(services) do
    services
    |> Enum.map(&Task.async(fn -> check_service(&1) end))
    |> Enum.map(&Task.await/1)
  end
  
  defp check_service(url) do
    case HTTP.get(url) do
      {:ok, %{status: 200}} -> {url, :healthy}
      _ -> {url, :unhealthy}
    end
  end
end

# Check 100 services in parallel
results = ParallelHealthChecker.check_all(service_urls)
```

## Real-World Example: Metric Collector

```elixir
defmodule MetricCollector do
  def start_link do
    pid = spawn_link(fn -> loop(%{}) end)
    Process.register(pid, __MODULE__)
    {:ok, pid}
  end
  
  def record(metric_name, value) do
    send(__MODULE__, {:record, metric_name, value, System.monotonic_time()})
    :ok
  end
  
  def get_metrics do
    send(__MODULE__, {:get_metrics, self()})
    receive do
      {:metrics, data} -> {:ok, data}
    after
      1000 -> {:error, :timeout}
    end
  end
  
  def get_average(metric_name) do
    send(__MODULE__, {:get_average, metric_name, self()})
    receive do
      {:average, avg} -> {:ok, avg}
      :not_found -> {:error, :not_found}
    after
      1000 -> {:error, :timeout}
    end
  end
  
  defp loop(metrics) do
    receive do
      {:record, metric_name, value, timestamp} ->
        updated_metrics = Map.update(
          metrics,
          metric_name,
          [{value, timestamp}],
          fn existing -> [{value, timestamp} | existing] end
        )
        loop(updated_metrics)
        
      {:get_metrics, caller} ->
        send(caller, {:metrics, metrics})
        loop(metrics)
        
      {:get_average, metric_name, caller} ->
        case Map.get(metrics, metric_name) do
          nil ->
            send(caller, :not_found)
            
          values ->
            avg = values
                  |> Enum.map(fn {val, _} -> val end)
                  |> Enum.sum()
                  |> Kernel./(length(values))
            send(caller, {:average, avg})
        end
        loop(metrics)
        
      :stop ->
        IO.puts("Stopping collector")
    end
  end
end

# Usage
{:ok, _pid} = MetricCollector.start_link()

# Record metrics from multiple processes
1..100 |> Enum.each(fn i ->
  Task.start(fn ->
    MetricCollector.record("cpu_usage", :rand.uniform(100))
    :timer.sleep(100)
  end)
end)

# Get average
{:ok, avg} = MetricCollector.get_average("cpu_usage")
IO.puts("Average CPU: #{Float.round(avg, 2)}%")
```

## Best Practices

1. **Keep processes simple**: One clear responsibility
2. **Use message passing**: Don't share state
3. **Handle all messages**: Always have a catch-all clause
4. **Use timeouts**: Don't block forever
5. **Let it crash**: Don't be defensive, use supervision
6. **Use abstractions**: Task, Agent, GenServer for common patterns

## Common Patterns

### Request-Response

```elixir
send(server, {command, self()})
receive do
  {:response, data} -> data
after
  5000 -> :timeout
end
```

### Fire and Forget

```elixir
spawn(fn -> perform_background_work() end)
```

### Worker Pool

```elixir
workers = Enum.map(1..10, fn _ -> 
  spawn(fn -> worker_loop() end)
end)
```

## Exercises

1. Create a process that echoes messages:
   ```elixir
   defmodule Echo do
     def loop do
       receive do
         {msg, sender} -> 
           send(sender, msg)
           loop()
       end
     end
   end
   ```

2. Build a concurrent counter:
   ```elixir
   defmodule Counter do
     def loop(count) do
       receive do
         {:inc, caller} -> 
           send(caller, count + 1)
           loop(count + 1)
         {:get, caller} ->
           send(caller, count)
           loop(count)
       end
     end
   end
   ```

3. Implement parallel map:
   ```elixir
   defmodule Parallel do
     def map(collection, fun) do
       collection
       |> Enum.map(&Task.async(fn -> fun.(&1) end))
       |> Enum.map(&Task.await/1)
     end
   end
   ```

## Key Takeaways

1. **Processes are cheap**: Create millions without worry
2. **Message passing**: The only way to communicate
3. **Isolation**: Crashes are contained
4. **Links and monitors**: For supervision
5. **spawn vs Task**: Use Task for most cases
6. **Always timeout**: Don't block forever

## What's Next?

Now that you understand processes, let's learn about OTP patterns that make building robust systems easier:
- [OTP: GenServer](02-otp-genserver.md)

## Additional Resources

- [Elixir Processes](https://elixir-lang.org/getting-started/processes.html)
- [Elixir School - Processes](https://elixirschool.com/en/lessons/advanced/concurrency)
- [Task Documentation](https://hexdocs.pm/elixir/Task.html)

