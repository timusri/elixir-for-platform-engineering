# Collections & Enumerables

## Overview

Elixir provides powerful tools for working with collections. The `Enum` module works with any enumerable data type (lists, maps, ranges), while the `Stream` module provides lazy evaluation for efficient processing of large datasets.

## The Enum Module

`Enum` is one of the most frequently used modules in Elixir.

### Common Enum Functions

#### map - Transform each element

```elixir
iex> Enum.map([1, 2, 3], fn x -> x * 2 end)
[2, 4, 6]

# With capture operator
iex> Enum.map([1, 2, 3], &(&1 * 2))
[2, 4, 6]
```

**Platform Engineering Example**: Add environment prefix to service names

```elixir
services = ["api", "web", "worker"]
prod_services = Enum.map(services, &("prod-#{&1}"))
# ["prod-api", "prod-web", "prod-worker"]
```

#### filter - Keep elements matching a condition

```elixir
iex> Enum.filter([1, 2, 3, 4, 5], fn x -> rem(x, 2) == 0 end)
[2, 4]

# With capture operator
iex> Enum.filter([1, 2, 3, 4, 5], &(rem(&1, 2) == 0))
[2, 4]
```

**Platform Engineering Example**: Filter healthy services

```elixir
services = [
  %{name: "api", status: :healthy},
  %{name: "web", status: :degraded},
  %{name: "worker", status: :healthy}
]

healthy = Enum.filter(services, &(&1.status == :healthy))
# [%{name: "api", status: :healthy}, %{name: "worker", status: :healthy}]
```

#### reduce - Accumulate a result

```elixir
iex> Enum.reduce([1, 2, 3, 4], 0, fn x, acc -> x + acc end)
10

# With capture operator
iex> Enum.reduce([1, 2, 3, 4], 0, &(&1 + &2))
10
```

**Platform Engineering Example**: Calculate total memory usage

```elixir
containers = [
  %{name: "api", memory_mb: 512},
  %{name: "web", memory_mb: 256},
  %{name: "worker", memory_mb: 1024}
]

total_memory = Enum.reduce(containers, 0, fn container, acc ->
  acc + container.memory_mb
end)
# 1792
```

#### each - Iterate for side effects

```elixir
iex> Enum.each(["api", "web", "worker"], &IO.puts/1)
api
web
worker
:ok
```

**Platform Engineering Example**: Deploy services

```elixir
services = ["api", "web", "worker"]

Enum.each(services, fn service ->
  IO.puts("Deploying #{service}...")
  deploy_service(service)
  IO.puts("✓ #{service} deployed")
end)
```

#### find - Get first matching element

```elixir
iex> Enum.find([1, 2, 3, 4], fn x -> x > 2 end)
3

iex> Enum.find([1, 2, 3, 4], fn x -> x > 10 end)
nil

# With default value
iex> Enum.find([1, 2, 3, 4], :not_found, fn x -> x > 10 end)
:not_found
```

**Platform Engineering Example**: Find failed deployment

```elixir
deployments = [
  %{service: "api", status: :success},
  %{service: "web", status: :failed},
  %{service: "worker", status: :success}
]

failed = Enum.find(deployments, &(&1.status == :failed))
# %{service: "web", status: :failed}
```

#### reject - Opposite of filter

```elixir
iex> Enum.reject([1, 2, 3, 4, 5], &(rem(&1, 2) == 0))
[1, 3, 5]
```

#### any? / all? - Check conditions

```elixir
iex> Enum.any?([1, 2, 3], &(&1 > 2))
true

iex> Enum.all?([1, 2, 3], &(&1 > 0))
true

iex> Enum.all?([1, 2, 3], &(&1 > 2))
false
```

**Platform Engineering Example**: Check system health

```elixir
services = [
  %{name: "api", status: :healthy},
  %{name: "web", status: :healthy},
  %{name: "worker", status: :healthy}
]

all_healthy? = Enum.all?(services, &(&1.status == :healthy))
any_unhealthy? = Enum.any?(services, &(&1.status != :healthy))
```

#### sort / sort_by - Sorting

```elixir
iex> Enum.sort([3, 1, 2])
[1, 2, 3]

iex> Enum.sort([3, 1, 2], :desc)
[3, 2, 1]

iex> Enum.sort_by([{:b, 2}, {:a, 1}, {:c, 3}], fn {_key, val} -> val end)
[{:a, 1}, {:b, 2}, {:c, 3}]
```

**Platform Engineering Example**: Sort by memory usage

```elixir
containers = [
  %{name: "api", memory_mb: 512},
  %{name: "worker", memory_mb: 1024},
  %{name: "web", memory_mb: 256}
]

sorted = Enum.sort_by(containers, & &1.memory_mb, :desc)
# [%{name: "worker", ...}, %{name: "api", ...}, %{name: "web", ...}]
```

#### group_by - Group into buckets

```elixir
iex> Enum.group_by(["api", "web", "worker"], &String.length/1)
%{3 => ["api", "web"], 6 => ["worker"]}
```

**Platform Engineering Example**: Group services by status

```elixir
services = [
  %{name: "api", status: :healthy},
  %{name: "web", status: :degraded},
  %{name: "worker", status: :healthy}
]

grouped = Enum.group_by(services, & &1.status)
# %{
#   healthy: [%{name: "api", ...}, %{name: "worker", ...}],
#   degraded: [%{name: "web", ...}]
# }
```

#### take / drop - Limit elements

```elixir
iex> Enum.take([1, 2, 3, 4, 5], 3)
[1, 2, 3]

iex> Enum.drop([1, 2, 3, 4, 5], 2)
[3, 4, 5]
```

#### chunk_every - Split into chunks

```elixir
iex> Enum.chunk_every([1, 2, 3, 4, 5, 6], 2)
[[1, 2], [3, 4], [5, 6]]
```

**Platform Engineering Example**: Batch deployments

```elixir
services = ["api", "web", "worker", "cache", "db", "queue"]

batches = Enum.chunk_every(services, 2)
# [["api", "web"], ["worker", "cache"], ["db", "queue"]]

Enum.each(batches, fn batch ->
  Enum.each(batch, &deploy_service/1)
  IO.puts("Batch deployed. Waiting...")
  :timer.sleep(10_000)
end)
```

#### zip - Combine two lists

```elixir
iex> Enum.zip([1, 2, 3], [:a, :b, :c])
[{1, :a}, {2, :b}, {3, :c}]
```

**Platform Engineering Example**: Pair services with ports

```elixir
services = ["api", "web", "metrics"]
ports = [8080, 8081, 9090]

service_ports = Enum.zip(services, ports)
# [{"api", 8080}, {"web", 8081}, {"metrics", 9090}]
```

#### flat_map - Map and flatten

```elixir
iex> Enum.flat_map([1, 2, 3], fn x -> [x, x * 2] end)
[1, 2, 2, 4, 3, 6]
```

**Platform Engineering Example**: Expand service replicas

```elixir
services = [
  %{name: "api", replicas: 3},
  %{name: "web", replicas: 2}
]

instances = Enum.flat_map(services, fn service ->
  Enum.map(1..service.replicas, fn i ->
    "#{service.name}-#{i}"
  end)
end)
# ["api-1", "api-2", "api-3", "web-1", "web-2"]
```

#### uniq / uniq_by - Remove duplicates

```elixir
iex> Enum.uniq([1, 2, 2, 3, 3, 3])
[1, 2, 3]

iex> Enum.uniq_by([{:a, 1}, {:b, 1}, {:c, 2}], fn {_, val} -> val end)
[{:a, 1}, {:c, 2}]
```

### Chaining Enum Operations

The power of `Enum` comes from chaining:

```elixir
[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
|> Enum.filter(&(rem(&1, 2) == 0))  # [2, 4, 6, 8, 10]
|> Enum.map(&(&1 * 2))              # [4, 8, 12, 16, 20]
|> Enum.take(3)                      # [4, 8, 12]
```

**Platform Engineering Example**: Process and analyze logs

```elixir
logs = [
  {:info, "Server started"},
  {:error, "Connection failed"},
  {:warn, "High memory usage"},
  {:error, "Timeout"},
  {:info, "Request processed"}
]

error_messages = logs
|> Enum.filter(fn {level, _} -> level == :error end)
|> Enum.map(fn {_, message} -> message end)
|> Enum.join(", ")
# "Connection failed, Timeout"
```

## Working with Maps

### Map-Specific Enum Functions

```elixir
config = %{host: "localhost", port: 5432, timeout: 5000}

# Iterate over key-value pairs
Enum.each(config, fn {key, value} ->
  IO.puts("#{key}: #{value}")
end)

# Transform values
Enum.map(config, fn {key, value} ->
  {key, to_string(value)}
end)
```

### The Map Module

```elixir
# Get value
iex> Map.get(%{a: 1}, :a)
1

# Get with default
iex> Map.get(%{a: 1}, :b, "default")
"default"

# Put value
iex> Map.put(%{a: 1}, :b, 2)
%{a: 1, b: 2}

# Update existing
iex> Map.update(%{a: 1}, :a, 0, &(&1 + 1))
%{a: 2}

# Delete key
iex> Map.delete(%{a: 1, b: 2}, :b)
%{a: 1}

# Keys and values
iex> Map.keys(%{a: 1, b: 2})
[:a, :b]

iex> Map.values(%{a: 1, b: 2})
[1, 2]

# Merge maps
iex> Map.merge(%{a: 1}, %{b: 2})
%{a: 1, b: 2}
```

**Platform Engineering Example**: Merge configurations

```elixir
default_config = %{
  timeout: 5000,
  retries: 3,
  pool_size: 10
}

user_config = %{
  timeout: 10_000,
  pool_size: 20
}

final_config = Map.merge(default_config, user_config)
# %{timeout: 10000, retries: 3, pool_size: 20}
```

## Comprehensions

A concise way to build collections:

### List Comprehensions

```elixir
iex> for x <- [1, 2, 3], do: x * 2
[2, 4, 6]

# With filter
iex> for x <- [1, 2, 3, 4, 5], rem(x, 2) == 0, do: x
[2, 4]

# Multiple generators
iex> for x <- [1, 2], y <- [3, 4], do: {x, y}
[{1, 3}, {1, 4}, {2, 3}, {2, 4}]
```

**Platform Engineering Example**: Generate server matrix

```elixir
environments = ["dev", "staging", "prod"]
regions = ["us-east-1", "us-west-2"]

servers = for env <- environments,
              region <- regions,
              do: "#{env}-#{region}"
# ["dev-us-east-1", "dev-us-west-2", "staging-us-east-1", ...]
```

### Map Comprehensions

```elixir
iex> for {k, v} <- %{a: 1, b: 2}, into: %{}, do: {k, v * 2}
%{a: 2, b: 4}
```

**Platform Engineering Example**: Transform configuration

```elixir
config = %{api_timeout: "5000", db_pool: "10", retries: "3"}

parsed_config = for {key, value} <- config, 
                    into: %{}, 
                    do: {key, String.to_integer(value)}
# %{api_timeout: 5000, db_pool: 10, retries: 3}
```

## Streams - Lazy Enumeration

Streams are lazy - they don't process data until needed. Great for large datasets!

### Creating Streams

```elixir
# From a range
iex> stream = Stream.map(1..1_000_000, &(&1 * 2))
#Stream<...>

# Nothing computed yet!

# Compute first 5
iex> Enum.take(stream, 5)
[2, 4, 6, 8, 10]
```

### Stream Functions

```elixir
# Infinite streams
iex> Stream.cycle([1, 2, 3]) |> Enum.take(7)
[1, 2, 3, 1, 2, 3, 1]

iex> Stream.iterate(0, &(&1 + 1)) |> Enum.take(5)
[0, 1, 2, 3, 4]

# Repeatedly call a function
iex> Stream.repeatedly(fn -> :rand.uniform(10) end) |> Enum.take(3)
[7, 2, 9]
```

**Platform Engineering Example**: Log file processing

```elixir
# Process a large log file without loading it all into memory
File.stream!("/var/log/app.log")
|> Stream.filter(&String.contains?(&1, "ERROR"))
|> Stream.map(&parse_log_line/1)
|> Stream.filter(&critical?/1)
|> Enum.take(10)  # Get first 10 critical errors
```

### Stream vs Enum

```elixir
# Enum - processes immediately, creates intermediate lists
1..1_000_000
|> Enum.map(&(&1 * 2))      # Creates 1M element list
|> Enum.filter(&(rem(&1, 3) == 0))  # Creates another list
|> Enum.take(5)

# Stream - lazy, no intermediate lists
1..1_000_000
|> Stream.map(&(&1 * 2))    # Doesn't compute yet
|> Stream.filter(&(rem(&1, 3) == 0))  # Still doesn't compute
|> Enum.take(5)              # Only now computes 5 elements
```

**Platform Engineering Example**: Process metrics efficiently

```elixir
defmodule MetricsProcessor do
  def process_large_dataset(file_path) do
    File.stream!(file_path)
    |> Stream.map(&parse_metric/1)
    |> Stream.filter(&valid_metric?/1)
    |> Stream.map(&normalize_metric/1)
    |> Stream.chunk_every(1000)
    |> Stream.each(&send_to_database/1)
    |> Stream.run()  # Execute the stream
  end
end
```

## Range

```elixir
iex> Enum.to_list(1..5)
[1, 2, 3, 4, 5]

iex> Enum.map(1..5, &(&1 * 2))
[2, 4, 6, 8, 10]

# Check membership
iex> 3 in 1..10
true
```

## Keyword Lists Revisited

```elixir
# Access
iex> list = [a: 1, b: 2, a: 3]
iex> Keyword.get(list, :a)
1

iex> Keyword.get_values(list, :a)
[1, 3]

# Update
iex> Keyword.put(list, :c, 4)
[a: 1, b: 2, a: 3, c: 4]

# Delete
iex> Keyword.delete(list, :a)
[b: 2, a: 3]  # Deletes only first occurrence
```

## Real-World Platform Engineering Example

```elixir
defmodule InfrastructureAnalyzer do
  def analyze_cluster(nodes) do
    nodes
    |> Enum.filter(&node_responsive?/1)
    |> Enum.group_by(& &1.region)
    |> Enum.map(fn {region, regional_nodes} ->
      %{
        region: region,
        node_count: length(regional_nodes),
        total_memory: calculate_total_memory(regional_nodes),
        average_cpu: calculate_average_cpu(regional_nodes),
        healthy_nodes: Enum.count(regional_nodes, &(&1.status == :healthy))
      }
    end)
    |> Enum.sort_by(& &1.node_count, :desc)
  end
  
  defp calculate_total_memory(nodes) do
    Enum.reduce(nodes, 0, fn node, acc -> acc + node.memory_gb end)
  end
  
  defp calculate_average_cpu(nodes) do
    total = Enum.reduce(nodes, 0, fn node, acc -> acc + node.cpu_usage end)
    Float.round(total / length(nodes), 2)
  end
  
  defp node_responsive?(node) do
    # Implementation
  end
end
```

## Exercises

1. Filter servers with high CPU usage:
   ```elixir
   servers = [%{name: "web-1", cpu: 85}, %{name: "web-2", cpu: 45}]
   high_cpu = Enum.filter(servers, &(&1.cpu > 80))
   ```

2. Calculate average response time:
   ```elixir
   response_times = [100, 250, 150, 200, 175]
   average = Enum.sum(response_times) / length(response_times)
   ```

3. Group logs by level:
   ```elixir
   logs = [{:error, "Failed"}, {:info, "OK"}, {:error, "Timeout"}]
   grouped = Enum.group_by(logs, fn {level, _} -> level end)
   ```

4. Generate deployment configurations:
   ```elixir
   envs = ["dev", "staging", "prod"]
   configs = for env <- envs, do: %{env: env, replicas: if env == "prod", do: 3, else: 1}
   ```

5. Process a stream of metrics:
   ```elixir
   1..100
   |> Stream.map(&{:metric, "cpu", &1})
   |> Stream.filter(fn {_, _, val} -> val > 80 end)
   |> Enum.take(5)
   ```

## Key Takeaways

1. **Enum**: Works with all enumerable types, eager evaluation
2. **Stream**: Lazy evaluation, memory efficient for large datasets
3. **Pipe operator**: Chain operations elegantly
4. **Comprehensions**: Concise syntax for building collections
5. **Pattern matching**: Works in all Enum/Stream functions
6. **Immutability**: Every operation returns a new collection

## What's Next?

Now let's explore control flow and error handling:
- [Control Flow & Error Handling](06-control-flow.md)

## Additional Resources

- [Elixir Enum Module](https://hexdocs.pm/elixir/Enum.html)
- [Elixir Stream Module](https://hexdocs.pm/elixir/Stream.html)
- [Elixir School - Enum](https://elixirschool.com/en/lessons/basics/enum)

