# Performance Optimization

## Overview

Elixir is fast, but understanding performance characteristics helps build efficient systems. This guide covers profiling, optimization strategies, and common pitfalls.

## Profiling Tools

### :timer.tc - Measure Execution Time

```elixir
{time_microseconds, result} = :timer.tc(fn ->
  # Code to measure
  expensive_operation()
end)

IO.puts("Took #{time_microseconds / 1_000}ms")
```

### Benchee - Comprehensive Benchmarking

```elixir
# mix.exs
{:benchee, "~> 1.1", only: :dev}

# benchmark.exs
Benchee.run(%{
  "map" => fn -> Enum.map(1..10_000, &(&1 * 2)) end,
  "for" => fn -> for x <- 1..10_000, do: x * 2 end
})
```

### :fprof - Function Profiler

```elixir
:fprof.trace([:start])
# Run code
my_function()
:fprof.trace([:stop])
:fprof.profile()
:fprof.analyse()
```

### :eprof - Time Profiler

```elixir
:eprof.start()
:eprof.profile(fn -> my_function() end)
:eprof.analyze()
```

## Common Performance Patterns

### Use Streams for Large Data

```elixir
# Bad - loads entire file into memory
File.read!("large_file.log")
|> String.split("\n")
|> Enum.filter(&String.contains?(&1, "ERROR"))

# Good - processes line by line
File.stream!("large_file.log")
|> Stream.filter(&String.contains?(&1, "ERROR"))
|> Enum.take(100)
```

### Avoid Creating Unnecessary Lists

```elixir
# Bad
Enum.map(list, &transform/1)
|> Enum.filter(&valid?/1)
|> Enum.map(&format/1)

# Better - single pass
Enum.reduce(list, [], fn item, acc ->
  transformed = transform(item)
  if valid?(transformed) do
    [format(transformed) | acc]
  else
    acc
  end
end)
|> Enum.reverse()
```

### Use ETS for Fast Lookups

```elixir
# Create ETS table
:ets.new(:cache, [:set, :public, :named_table])

# Insert
:ets.insert(:cache, {"key", "value"})

# Lookup (very fast)
:ets.lookup(:cache, "key")
```

### Optimize Pattern Matching

```elixir
# Bad - checks entire list
def process([]), do: :done
def process([h | t]) do
  handle(h)
  process(t)
end

# Better - tail call optimized
def process(list), do: process(list, [])

defp process([], acc), do: Enum.reverse(acc)
defp process([h | t], acc) do
  process(t, [handle(h) | acc])
end
```

## Platform Engineering-Specific Optimizations

### Concurrent Health Checks

```elixir
# Bad - sequential
def check_all_sequential(urls) do
  Enum.map(urls, &check_url/1)
end

# Good - concurrent
def check_all_concurrent(urls) do
  urls
  |> Task.async_stream(&check_url/1, max_concurrency: 100)
  |> Enum.to_list()
end
```

### Batch Operations

```elixir
# Bad - individual inserts
Enum.each(items, fn item ->
  Database.insert(item)
end)

# Good - batch insert
Database.insert_all(items)
```

### Connection Pooling

```elixir
# Use DBConnection or similar for pooling
defmodule MyApp.Repo do
  use Ecto.Repo,
    otp_app: :my_app,
    adapter: Ecto.Adapters.Postgres

  # Configure pool
  def init(_, opts) do
    {:ok, Keyword.put(opts, :pool_size, 20)}
  end
end
```

## Memory Optimization

### Process Memory

```elixir
# Check process memory
Process.info(self(), :memory)

# Garbage collect
:erlang.garbage_collect(self())
```

### Binary Memory

```elixir
# Large binaries are reference counted
# Small binaries (<64 bytes) are copied

# Bad - creates many small binaries
Enum.map(1..1000, fn i -> <<i>> end)

# Better - use iodata
iodata = Enum.map(1..1000, fn i -> [<<i>>] end)
:erlang.iolist_to_binary(iodata)
```

## Monitoring Performance

### VM Statistics

```elixir
# Get VM stats
:erlang.statistics(:runtime)
:erlang.statistics(:wall_clock)
:erlang.memory()

# Process count
:erlang.system_info(:process_count)

# Schedulers
:erlang.system_info(:schedulers_online)
```

### Telemetry

```elixir
# Add to mix.exs
{:telemetry, "~> 1.2"}

# Attach handler
:telemetry.attach(
  "log-handler",
  [:my_app, :request, :stop],
  fn name, measurements, metadata, _config ->
    duration = measurements.duration
    IO.puts("Request took #{duration}ms")
  end,
  nil
)

# Emit events
:telemetry.execute(
  [:my_app, :request, :stop],
  %{duration: duration_ms},
  %{path: "/health"}
)
```

## Performance Checklist

- [ ] Profile before optimizing
- [ ] Use streams for large data
- [ ] Leverage concurrency
- [ ] Batch database operations
- [ ] Use ETS for caching
- [ ] Pool connections
- [ ] Monitor memory usage
- [ ] Use proper data structures

## Key Takeaways

1. **Profile first**: Don't guess, measure
2. **Streams**: For large datasets
3. **Concurrency**: Leverage BEAM
4. **ETS**: Fast in-memory storage
5. **Batch operations**: Reduce overhead
6. **Monitor**: Use Telemetry

## Additional Resources

- [Benchee Documentation](https://hexdocs.pm/benchee/)
- [Erlang Efficiency Guide](http://erlang.org/doc/efficiency_guide/users_guide.html)
- [Telemetry Guide](https://hexdocs.pm/telemetry/)

