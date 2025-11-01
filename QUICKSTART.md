# Quick Start: Your First Day with Elixir

## 30-Minute Quick Start Guide

This guide will get you writing Elixir code in 30 minutes.

## Installation (5 minutes)

### macOS
```bash
brew install elixir
```

### Ubuntu/Debian
```bash
sudo apt-get update
sudo apt-get install elixir
```

### Verify Installation
```bash
elixir --version
# Erlang/OTP 26 [erts-14.0]
# Elixir 1.15.0

iex
# Interactive Elixir (1.15.0)
```

## Interactive Shell (10 minutes)

Start `iex` (Interactive Elixir):

```bash
$ iex
```

### Try These Commands

```elixir
# Basic math
iex> 2 + 2
4

# Strings
iex> "Hello" <> " " <> "DevOps"
"Hello DevOps"

# Lists
iex> [1, 2, 3] ++ [4, 5]
[1, 2, 3, 4, 5]

# Maps (like dictionaries/hashes)
iex> server = %{name: "web-1", port: 8080}
%{name: "web-1", port: 8080}

iex> server.name
"web-1"

# Pipe operator (chain operations)
iex> "  deploy to production  " |> String.trim() |> String.upcase()
"DEPLOY TO PRODUCTION"

# Pattern matching
iex> {:ok, result} = {:ok, "Success"}
{:ok, "Success"}

iex> result
"Success"

# Functions
iex> double = fn x -> x * 2 end
iex> double.(21)
42

# Enum (collection operations)
iex> Enum.map([1, 2, 3], fn x -> x * 2 end)
[2, 4, 6]

iex> Enum.filter([1, 2, 3, 4, 5], fn x -> rem(x, 2) == 0 end)
[2, 4]
```

## Your First Script (5 minutes)

Create `hello.exs`:

```elixir
defmodule DevOpsHelper do
  def greet(name) do
    IO.puts("Hello, #{name}!")
  end
  
  def calculate_uptime(total_seconds) do
    hours = div(total_seconds, 3600)
    minutes = div(rem(total_seconds, 3600), 60)
    "#{hours}h #{minutes}m"
  end
  
  def check_port_range(port) do
    cond do
      port < 1 -> {:error, "Invalid port"}
      port < 1024 -> {:warning, "Privileged port"}
      port > 65535 -> {:error, "Port too high"}
      true -> {:ok, port}
    end
  end
end

# Run the functions
DevOpsHelper.greet("Platform Engineer")

uptime = DevOpsHelper.calculate_uptime(7265)
IO.puts("Uptime: #{uptime}")

case DevOpsHelper.check_port_range(8080) do
  {:ok, port} -> IO.puts("Port #{port} is valid")
  {:warning, msg} -> IO.puts("Warning: #{msg}")
  {:error, msg} -> IO.puts("Error: #{msg}")
end
```

Run it:

```bash
elixir hello.exs
```

## Your First Project (10 minutes)

Create a Mix project (Mix is Elixir's build tool):

```bash
mix new health_checker
cd health_checker
```

Edit `lib/health_checker.ex`:

```elixir
defmodule HealthChecker do
  @moduledoc """
  Simple health checker for HTTP services.
  """

  def check(url) do
    case HTTPoison.get(url, [], timeout: 5000) do
      {:ok, %{status_code: 200}} ->
        {:ok, :healthy}
        
      {:ok, %{status_code: code}} ->
        {:error, {:unhealthy, code}}
        
      {:error, %{reason: reason}} ->
        {:error, {:unreachable, reason}}
    end
  end
  
  def check_multiple(urls) do
    urls
    |> Enum.map(&Task.async(fn -> {&1, check(&1)} end))
    |> Enum.map(&Task.await/1)
  end
  
  def report(results) do
    Enum.each(results, fn {url, result} ->
      case result do
        {:ok, :healthy} -> 
          IO.puts("✓ #{url} is healthy")
        {:error, reason} -> 
          IO.puts("✗ #{url} failed: #{inspect(reason)}")
      end
    end)
  end
end
```

Add HTTPoison dependency in `mix.exs`:

```elixir
defp deps do
  [
    {:httpoison, "~> 2.0"}
  ]
end
```

Install dependencies:

```bash
mix deps.get
```

Create a test script `check_services.exs`:

```elixir
# Check multiple services concurrently
services = [
  "https://google.com",
  "https://github.com",
  "https://elixir-lang.org"
]

results = HealthChecker.check_multiple(services)
HealthChecker.report(results)
```

Run it:

```bash
mix run check_services.exs
```

## Quick Reference Card

### Data Types

```elixir
# Integer
42

# Float
3.14

# Atom (constant)
:ok, :error, :pending

# String
"hello"

# List
[1, 2, 3]

# Tuple
{:ok, "result"}

# Map
%{key: "value"}

# Keyword List
[name: "api", port: 8080]
```

### Pattern Matching

```elixir
# Match and destructure
{:ok, result} = {:ok, "data"}

# Match list head/tail
[head | tail] = [1, 2, 3]

# Match map fields
%{name: name, port: port} = %{name: "api", port: 8080}
```

### Functions

```elixir
# Anonymous function
add = fn a, b -> a + b end
add.(2, 3)

# Named function (in module)
defmodule Math do
  def add(a, b), do: a + b
end

Math.add(2, 3)
```

### Control Flow

```elixir
# case
case value do
  {:ok, result} -> result
  {:error, _} -> "error"
end

# cond
cond do
  x > 10 -> "large"
  x > 5 -> "medium"
  true -> "small"
end

# if
if x > 0, do: "positive", else: "negative"
```

### Common Operations

```elixir
# Pipe operator
"  data  "
|> String.trim()
|> String.upcase()

# Map
Enum.map([1, 2, 3], &(&1 * 2))

# Filter
Enum.filter([1, 2, 3, 4], &(rem(&1, 2) == 0))

# Reduce
Enum.reduce([1, 2, 3], 0, &(&1 + &2))
```

### Concurrency

```elixir
# Spawn process
pid = spawn(fn -> IO.puts("Hello") end)

# Send message
send(pid, :hello)

# Receive message
receive do
  :hello -> "got it"
end

# Task (higher level)
task = Task.async(fn -> heavy_computation() end)
result = Task.await(task)
```

## DevOps-Specific Examples

### Read and Parse Config File

```elixir
case File.read("config.json") do
  {:ok, content} ->
    Jason.decode!(content)
  {:error, reason} ->
    IO.puts("Error reading config: #{reason}")
end
```

### Concurrent Health Checks

```elixir
servers = ["http://api-1", "http://api-2", "http://api-3"]

results = servers
|> Enum.map(&Task.async(fn -> check_health(&1) end))
|> Enum.map(&Task.await/1)
```

### Process Log File

```elixir
File.stream!("/var/log/app.log")
|> Stream.filter(&String.contains?(&1, "ERROR"))
|> Stream.map(&parse_log_line/1)
|> Enum.take(10)
```

### Batch Operations

```elixir
services
|> Enum.chunk_every(5)
|> Enum.each(fn batch ->
  Enum.each(batch, &deploy/1)
  :timer.sleep(5000)  # Wait between batches
end)
```

## Common Mistakes for Beginners

### 1. Forgetting the dot for anonymous functions

```elixir
# Wrong
add = fn a, b -> a + b end
add(2, 3)  # Error!

# Right
add.(2, 3)
```

### 2. Using = as assignment instead of match

```elixir
# This tries to match, not assign
1 = x  # Crashes if x is not 1

# Pattern match correctly
{:ok, result} = function_call()
```

### 3. Trying to modify data

```elixir
# Wrong thinking - Elixir data is immutable
list = [1, 2, 3]
List.append(list, 4)  # Returns new list, doesn't modify
list  # Still [1, 2, 3]

# Right
list = List.append(list, 4)  # Rebind variable
```

### 4. Not handling all pattern match cases

```elixir
# Bad - crashes if :error
{:ok, result} = function_call()

# Good - handle both cases
case function_call() do
  {:ok, result} -> use(result)
  {:error, reason} -> handle_error(reason)
end
```

## Next Steps

### Immediate (Today)
1. Complete the interactive shell exercises
2. Run your first script
3. Create your first Mix project

### This Week
1. Read [Basic Syntax & Data Types](docs/01-beginner/02-basic-syntax.md)
2. Master [Pattern Matching](docs/01-beginner/03-pattern-matching.md)
3. Learn [Functions & Modules](docs/01-beginner/04-functions-modules.md)

### This Month
1. Complete beginner documentation
2. Work through intermediate material (Processes, GenServer)
3. Build the Health Check Aggregator project

### Within 3 Months
1. Complete all documentation
2. Build all 5 DevOps projects
3. Start building your own tools

## Getting Help

### Documentation
```bash
# In iex
iex> h Enum.map
iex> h String
```

### Online Resources
- Official docs: https://elixir-lang.org
- Hex packages: https://hex.pm
- Elixir Forum: https://elixirforum.com
- Exercism: https://exercism.org/tracks/elixir

### Commands
```bash
mix help        # Mix tasks help
mix deps.get    # Get dependencies
mix compile     # Compile project
mix test        # Run tests
mix format      # Format code
iex -S mix      # Start iex with project loaded
```

## Summary

You now know:
- ✓ How to install Elixir
- ✓ How to use the interactive shell
- ✓ Basic syntax and data types
- ✓ How to create and run scripts
- ✓ How to create Mix projects
- ✓ Where to go next

**Congratulations!** You're ready to dive deeper into Elixir.

Start with the full documentation in [README.md](README.md) and work through the beginner level systematically.

Happy coding! 🎉

