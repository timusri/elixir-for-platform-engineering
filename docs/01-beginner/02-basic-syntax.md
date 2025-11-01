# Basic Syntax & Data Types

## Overview

Elixir has a clean, Ruby-inspired syntax with powerful features. This chapter covers the fundamental building blocks you'll use every day.

## Basic Data Types

### Integers

```elixir
# Decimal
iex> 42
42

# Binary
iex> 0b1010
10

# Octal
iex> 0o777
511

# Hexadecimal
iex> 0xFF
255

# Large numbers (no limit!)
iex> 123_456_789_000_000
123456789000000

# DevOps example: bytes to gigabytes
iex> bytes = 5_368_709_120
iex> bytes / 1024 / 1024 / 1024
5.0
```

### Floats

```elixir
iex> 3.14
3.14

iex> 1.0e-10
1.0e-10

# DevOps example: CPU usage percentage
iex> cpu_usage = 87.5
iex> Float.round(cpu_usage, 2)
87.5
```

### Atoms

Atoms are constants whose name is their value. Think of them like symbols in Ruby or enums in Go.

```elixir
iex> :ok
:ok

iex> :error
:error

iex> :kubernetes
:kubernetes

# Atoms with spaces or special characters
iex> :"deployment-failed"
:"deployment-failed"

# Boolean values are atoms
iex> true
true
iex> is_atom(true)
true
iex> true === :true
true
```

**DevOps Usage**: Status codes, tags, configuration keys

```elixir
# Common patterns
{:ok, result}
{:error, reason}
{:pending, task}

# Health check status
:healthy
:unhealthy
:degraded
```

### Strings

Strings are UTF-8 encoded binaries.

```elixir
iex> "Hello, DevOps!"
"Hello, DevOps!"

# Multi-line strings
iex> """
...> apiVersion: v1
...> kind: Pod
...> metadata:
...>   name: nginx
...> """

# String interpolation
iex> name = "Kubernetes"
iex> "Deploying to #{name}"
"Deploying to Kubernetes"

# String concatenation
iex> "Hello" <> " " <> "World"
"Hello World"
```

### String Operations

```elixir
# Length
iex> String.length("deploy")
6

# Uppercase/Lowercase
iex> String.upcase("kubernetes")
"KUBERNETES"
iex> String.downcase("AWS")
"aws"

# Trim whitespace
iex> String.trim("  nginx  ")
"nginx"

# Split
iex> String.split("error:connection:timeout", ":")
["error", "connection", "timeout"]

# Contains
iex> String.contains?("deployment.yaml", ".yaml")
true

# Replace
iex> String.replace("http://api", "http", "https")
"https://api"
```

**DevOps Example**: Log parsing

```elixir
log_line = "2024-11-01 ERROR: Connection timeout in pod nginx-123"

log_line
|> String.split(" ", parts: 3)
|> case do
  [date, level, message] -> 
    %{date: date, level: level, message: message}
  _ -> 
    :invalid_format
end
```

## Collections

### Lists

Lists are linked lists - fast at the head, slow at the tail.

```elixir
iex> [1, 2, 3, 4, 5]
[1, 2, 3, 4, 5]

# Mixed types (though uncommon)
iex> [1, "two", :three]
[1, "two", :three]

# Head and tail
iex> [head | tail] = [1, 2, 3, 4]
iex> head
1
iex> tail
[2, 3, 4]

# Prepend (fast - O(1))
iex> [0 | [1, 2, 3]]
[0, 1, 2, 3]

# Append (slow - O(n))
iex> [1, 2, 3] ++ [4, 5]
[1, 2, 3, 4, 5]

# Subtract
iex> [1, 2, 3, 4] -- [2, 4]
[1, 3]

# Check membership
iex> 2 in [1, 2, 3]
true
```

**DevOps Example**: Processing server list

```elixir
servers = ["web-1", "web-2", "web-3"]
new_servers = ["web-4" | servers]

# Result: ["web-4", "web-1", "web-2", "web-3"]
```

### Tuples

Tuples store elements contiguously in memory - fast access by index.

```elixir
iex> {:ok, "Success"}
{:ok, "Success"}

iex> {:error, :not_found, "File not found"}
{:error, :not_found, "File not found"}

# Access by index (0-based)
iex> tuple = {:ok, 200, "OK"}
iex> elem(tuple, 0)
:ok
iex> elem(tuple, 1)
200

# Update (creates new tuple)
iex> put_elem(tuple, 1, 201)
{:ok, 201, "OK"}

# Size
iex> tuple_size({:ok, "data"})
2
```

**DevOps Pattern**: Return tuples for success/error

```elixir
def check_service_health(url) do
  case HTTPoison.get(url) do
    {:ok, %{status_code: 200}} -> {:ok, :healthy}
    {:ok, %{status_code: code}} -> {:error, {:unhealthy, code}}
    {:error, reason} -> {:error, {:unreachable, reason}}
  end
end
```

### Keyword Lists

Lists of 2-element tuples where the first element is an atom.

```elixir
iex> options = [host: "localhost", port: 5432, timeout: 5000]
[host: "localhost", port: 5432, timeout: 5000]

# Same as:
iex> [{:host, "localhost"}, {:port, 5432}, {:timeout, 5000}]

# Access
iex> options[:host]
"localhost"

# Duplicate keys allowed
iex> [debug: true, debug: false]
[debug: true, debug: false]
```

**DevOps Usage**: Function options, configuration

```elixir
HTTP.get("https://api.example.com", 
  headers: [{"Authorization", "Bearer token"}],
  timeout: 5000,
  recv_timeout: 10000
)
```

### Maps

Key-value stores with fast lookup.

```elixir
iex> server = %{name: "web-1", ip: "10.0.0.1", port: 80}
%{name: "web-1", ip: "10.0.0.1", port: 80}

# Access with atom keys
iex> server[:name]
"web-1"
iex> server.name
"web-1"

# String keys (need bracket access)
iex> config = %{"environment" => "production", "region" => "us-west-2"}
iex> config["environment"]
"production"

# Update (creates new map)
iex> %{server | port: 443}
%{name: "web-1", ip: "10.0.0.1", port: 443}

# Add new key
iex> Map.put(server, :status, :running)
%{name: "web-1", ip: "10.0.0.1", port: 80, status: :running}

# Get with default
iex> Map.get(server, :missing, "default")
"default"
```

**DevOps Example**: Infrastructure configuration

```elixir
cluster = %{
  name: "prod-cluster",
  region: "us-east-1",
  nodes: [
    %{id: "node-1", type: "t3.large", az: "us-east-1a"},
    %{id: "node-2", type: "t3.large", az: "us-east-1b"},
    %{id: "node-3", type: "t3.large", az: "us-east-1c"}
  ],
  tags: %{
    environment: "production",
    team: "platform"
  }
}
```

### Structs (Preview)

Structs are maps with defined keys and default values. We'll cover these more in the Functions & Modules chapter.

```elixir
defmodule Server do
  defstruct name: "", ip: "0.0.0.0", port: 80, status: :stopped
end

iex> server = %Server{name: "web-1", ip: "10.0.0.1"}
%Server{name: "web-1", ip: "10.0.0.1", port: 80, status: :stopped}
```

## Operators

### Arithmetic Operators

```elixir
iex> 10 + 5        # 15
iex> 10 - 5        # 5
iex> 10 * 5        # 50
iex> 10 / 5        # 2.0 (always returns float)
iex> div(10, 3)    # 3 (integer division)
iex> rem(10, 3)    # 1 (remainder)
```

### Comparison Operators

```elixir
iex> 1 == 1.0      # true (value equality)
iex> 1 === 1.0     # false (strict equality)
iex> 1 != 2        # true
iex> 1 !== 1.0     # true
iex> 1 < 2         # true
iex> 1 <= 1        # true
iex> 2 > 1         # true
iex> 2 >= 1        # true
```

### Boolean Operators

```elixir
# Expect boolean operands (strict)
iex> true and true    # true
iex> false or true    # true
iex> not false        # true

# Allow any type (relaxed)
iex> 1 || 2           # 1
iex> false || 11      # 11
iex> nil && 13        # nil
iex> true && 17       # 17
```

### String Operators

```elixir
iex> "Hello" <> " " <> "World"
"Hello World"

iex> "abc" =~ ~r/bc/
true
```

## Type Checking

```elixir
iex> is_integer(42)
true
iex> is_float(3.14)
true
iex> is_atom(:ok)
true
iex> is_boolean(true)
true
iex> is_binary("hello")
true
iex> is_list([1, 2, 3])
true
iex> is_tuple({:ok, "data"})
true
iex> is_map(%{key: "value"})
true
```

## Ranges

```elixir
iex> 1..10
1..10

iex> Enum.to_list(1..5)
[1, 2, 3, 4, 5]

# Descending
iex> 10..1
10..1

# Check membership
iex> 5 in 1..10
true
```

**DevOps Example**: Port ranges

```elixir
port_range = 8000..8010
port = 8005

if port in port_range do
  "Port #{port} is in allowed range"
else
  "Port #{port} is outside allowed range"
end
```

## Anonymous Functions

```elixir
# Basic syntax
iex> add = fn a, b -> a + b end
iex> add.(5, 3)
8

# Shorthand with capture operator
iex> add = &(&1 + &2)
iex> add.(5, 3)
8

# Multi-clause functions
iex> handle_response = fn
...>   {:ok, data} -> "Success: #{data}"
...>   {:error, reason} -> "Error: #{reason}"
...> end

iex> handle_response.({:ok, "deployed"})
"Success: deployed"
```

**DevOps Example**: Health check handler

```elixir
check_status = fn
  %{status: 200} -> {:ok, :healthy}
  %{status: 503} -> {:error, :unavailable}
  %{status: code} -> {:error, {:unknown, code}}
end
```

## Comments

```elixir
# This is a single-line comment

# This is also a comment
# You can stack them

# TODO: Implement health check monitoring
# FIXME: Handle timeout errors
```

## Printing and Debugging

```elixir
# Print to console
iex> IO.puts("Deploying to production")
Deploying to production
:ok

# Print with newline
iex> IO.write("Processing...")
Processing...:ok

# Inspect data structures
iex> IO.inspect([1, 2, 3], label: "List")
List: [1, 2, 3]
[1, 2, 3]

# Debugging in pipelines
iex> "  data  "
...> |> String.trim()
...> |> IO.inspect(label: "After trim")
...> |> String.upcase()
After trim: "data"
"DATA"
```

## Naming Conventions

```elixir
# Variables and function names: snake_case
server_name = "web-1"
def check_health(url), do: :ok

# Module names: PascalCase
defmodule HealthChecker do
end

# Atoms: snake_case or kebab-case
:health_check
:running
:"deployment-failed"

# Constants (module attributes): snake_case with @ prefix
@default_timeout 5000
```

## Common Patterns for DevOps

### Status Tuples

```elixir
{:ok, result}
{:error, reason}
{:pending, task_id}
```

### Configuration Maps

```elixir
config = %{
  host: "localhost",
  port: 5432,
  pool_size: 10,
  timeout: 5000
}
```

### Tagged Data

```elixir
{:metric, "cpu_usage", 87.5, timestamp}
{:log, :error, "Connection failed", metadata}
{:event, :deployment, "v2.1.0", deploy_info}
```

## Exercises

Try these in `iex`:

1. Create a map representing a server with name, IP, and port:
   ```elixir
   server = %{name: "web-1", ip: "10.0.0.1", port: 80}
   ```

2. Update the server to use HTTPS (port 443):
   ```elixir
   %{server | port: 443}
   ```

3. Create a list of 5 server names and add a new one at the front:
   ```elixir
   servers = ["web-1", "web-2", "web-3", "web-4", "web-5"]
   ["web-6" | servers]
   ```

4. Parse a log level from a string:
   ```elixir
   log = "ERROR: Connection timeout"
   [level, message] = String.split(log, ": ", parts: 2)
   ```

5. Create an anonymous function that categorizes response codes:
   ```elixir
   categorize = fn
     code when code >= 200 and code < 300 -> :success
     code when code >= 400 and code < 500 -> :client_error
     code when code >= 500 -> :server_error
   end
   
   categorize.(200)  # :success
   categorize.(404)  # :client_error
   ```

## Key Takeaways

1. **Immutability**: All data structures are immutable
2. **Atoms**: Use for constants, tags, and return status
3. **Lists**: For sequential processing, prepend is fast
4. **Maps**: For key-value lookups, configuration
5. **Tuples**: For fixed-size returns, pattern matching
6. **Pipe Operator**: Chain transformations elegantly

## What's Next?

Now that you know the basic data types and syntax, let's explore one of Elixir's most powerful features:
- [Pattern Matching](03-pattern-matching.md)

## Additional Resources

- [Elixir Basic Types](https://elixir-lang.org/getting-started/basic-types.html)
- [Elixir School - Collections](https://elixirschool.com/en/lessons/basics/collections)

