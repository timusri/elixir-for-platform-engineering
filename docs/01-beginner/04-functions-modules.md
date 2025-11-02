# Functions & Modules

## Overview

Functions are the building blocks of Elixir programs. They transform data, and in Elixir, they're first-class citizens. Modules organize related functions into namespaces.

## Anonymous Functions

### Basic Syntax

```elixir
# Full syntax
iex> add = fn a, b -> a + b end
iex> add.(5, 3)
8

# Note the dot: add.(5, 3)
# The dot distinguishes anonymous from named functions
```

### Shorthand with Capture Operator

```elixir
# Using &()
iex> add = &(&1 + &2)
iex> add.(5, 3)
8

# &1, &2, &3 are the first, second, third arguments

# More examples
iex> double = &(&1 * 2)
iex> double.(21)
42

iex> is_even = &(rem(&1, 2) == 0)
iex> is_even.(4)
true
```

**Platform Engineering Example**: Data transformations

```elixir
servers = ["web-1", "web-2", "web-3"]

# Add environment prefix
prod_servers = Enum.map(servers, &("prod-" <> &1))
# ["prod-web-1", "prod-web-2", "prod-web-3"]

# Filter by pattern
web_servers = Enum.filter(servers, &String.starts_with?(&1, "web"))
```

### Multi-Clause Anonymous Functions

```elixir
handle_status = fn
  {:ok, data} -> "Success: #{data}"
  {:error, :timeout} -> "Request timed out"
  {:error, reason} -> "Error: #{reason}"
end

iex> handle_status.({:ok, "deployed"})
"Success: deployed"
iex> handle_status.({:error, :timeout})
"Request timed out"
```

## Named Functions

Named functions must be defined inside modules.

### Defining Modules

```elixir
defmodule Math do
  def add(a, b) do
    a + b
  end
  
  def subtract(a, b) do
    a - b
  end
end

iex> Math.add(5, 3)
8
```

### One-Line Functions

```elixir
defmodule Math do
  def add(a, b), do: a + b
  def subtract(a, b), do: a - b
end
```

**Platform Engineering Example**: Server utilities

```elixir
defmodule ServerUtils do
  def build_url(host, port), do: "http://#{host}:#{port}"
  
  def format_uptime(seconds) do
    hours = div(seconds, 3600)
    minutes = div(rem(seconds, 3600), 60)
    "#{hours}h #{minutes}m"
  end
end

iex> ServerUtils.build_url("localhost", 8080)
"http://localhost:8080"
iex> ServerUtils.format_uptime(7265)
"2h 1m"
```

## Pattern Matching in Functions

This is where Elixir really shines!

### Multiple Function Clauses

```elixir
defmodule StatusChecker do
  def check({:ok, 200}), do: :healthy
  def check({:ok, 201}), do: :healthy
  def check({:ok, _status}), do: :unhealthy
  def check({:error, _reason}), do: :error
end

iex> StatusChecker.check({:ok, 200})
:healthy
iex> StatusChecker.check({:ok, 500})
:unhealthy
```

**Platform Engineering Example**: Log level handler

```elixir
defmodule Logger do
  def handle({:error, message}) do
    IO.puts("[ERROR] #{message}")
    alert_oncall(message)
  end
  
  def handle({:warn, message}) do
    IO.puts("[WARN] #{message}")
  end
  
  def handle({:info, message}) do
    IO.puts("[INFO] #{message}")
  end
end
```

### Guards

Add extra conditions with `when`:

```elixir
defmodule PortValidator do
  def validate(port) when port < 1 do
    {:error, :invalid_port}
  end
  
  def validate(port) when port > 65535 do
    {:error, :port_too_high}
  end
  
  def validate(port) when port < 1024 do
    {:warning, :privileged_port, port}
  end
  
  def validate(port) do
    {:ok, port}
  end
end
```

**Common Guard Expressions**:
```elixir
when is_integer(x)
when is_binary(str)
when is_atom(atom)
when is_list(list)
when is_map(map)
when x > 0
when x in [1, 2, 3]
when is_nil(x)
```

### Default Arguments

```elixir
defmodule HTTP do
  def get(url, timeout \\ 5000) do
    # timeout defaults to 5000 if not provided
    HTTPoison.get(url, [], recv_timeout: timeout)
  end
end

iex> HTTP.get("https://api.example.com")  # uses 5000
iex> HTTP.get("https://api.example.com", 10000)  # uses 10000
```

**Platform Engineering Example**: Health checker with defaults

```elixir
defmodule HealthChecker do
  def check(url, interval \\ 30, timeout \\ 5000) do
    # Check every 30 seconds with 5 second timeout
    schedule_check(url, interval, timeout)
  end
end
```

## Recursion

Elixir doesn't have loops - use recursion instead!

### Basic Recursion

```elixir
defmodule Counter do
  def count_down(0), do: IO.puts("Done!")
  
  def count_down(n) do
    IO.puts(n)
    count_down(n - 1)
  end
end

iex> Counter.count_down(3)
3
2
1
Done!
```

### Tail Call Optimization

Elixir optimizes tail-recursive functions (when recursive call is the last operation):

```elixir
defmodule Sum do
  # Not tail recursive
  def sum([]), do: 0
  def sum([head | tail]), do: head + sum(tail)
  
  # Tail recursive (better!)
  def sum_tail(list), do: sum_tail(list, 0)
  
  defp sum_tail([], acc), do: acc
  defp sum_tail([head | tail], acc) do
    sum_tail(tail, acc + head)
  end
end
```

**Platform Engineering Example**: Recursive log processing

```elixir
defmodule LogProcessor do
  def process([]), do: :done
  
  def process([log | remaining]) do
    case parse_log(log) do
      {:error, _} -> alert_team(log)
      {:warn, _} -> record_warning(log)
      {:info, _} -> :ok
    end
    
    process(remaining)
  end
  
  defp parse_log(log), do: # ... implementation
  defp alert_team(log), do: # ... implementation
  defp record_warning(log), do: # ... implementation
end
```

## Private Functions

Use `defp` for private functions (only callable within the module):

```elixir
defmodule Server do
  # Public function
  def start(port) do
    validate_port(port)
    do_start(port)
  end
  
  # Private functions
  defp validate_port(port) when port < 1024 do
    {:error, :privileged_port}
  end
  
  defp validate_port(_port), do: :ok
  
  defp do_start(port) do
    # ... implementation
  end
end

iex> Server.start(8080)  # OK
iex> Server.validate_port(8080)  # ERROR - private function
```

## Module Attributes

Compile-time constants:

```elixir
defmodule Config do
  @default_timeout 5000
  @max_retries 3
  @base_url "https://api.example.com"
  
  def get_timeout, do: @default_timeout
  def get_base_url, do: @base_url
end
```

**Platform Engineering Example**: Configuration constants

```elixir
defmodule HealthChecker do
  @default_interval 30_000
  @default_timeout 5_000
  @max_consecutive_failures 3
  
  def start_checking(url, interval \\ @default_interval) do
    check(url, interval, 0)
  end
  
  defp check(url, interval, failures) when failures >= @max_consecutive_failures do
    alert_oncall("Service down: #{url}")
    :degraded
  end
  
  defp check(url, interval, failures) do
    case HTTP.get(url, timeout: @default_timeout) do
      {:ok, %{status: 200}} -> 
        :timer.sleep(interval)
        check(url, interval, 0)
      _ -> 
        check(url, interval, failures + 1)
    end
  end
end
```

## Import, Alias, and Require

### Import

Import functions from another module:

```elixir
defmodule MyModule do
  import String, only: [upcase: 1, downcase: 1]
  
  def shout(text) do
    upcase(text)  # No need for String.upcase
  end
end
```

### Alias

Create shortcuts for module names:

```elixir
defmodule MyApp.Workers.HealthChecker do
  alias MyApp.Utils.HTTP
  alias MyApp.Alerts.{Slack, PagerDuty}
  
  def check(url) do
    case HTTP.get(url) do
      {:ok, _} -> :healthy
      {:error, _} -> 
        Slack.notify("Service down")
        PagerDuty.alert("Critical")
    end
  end
end
```

### Require

Required for using macros:

```elixir
defmodule MyModule do
  require Logger
  
  def process(data) do
    Logger.debug("Processing: #{inspect(data)}")
    # ... process data
  end
end
```

## Pipe Operator with Functions

Chain function calls elegantly:

```elixir
# Without pipe
result = String.trim(String.upcase(String.reverse("  hello  ")))

# With pipe
result = "  hello  "
         |> String.reverse()
         |> String.upcase()
         |> String.trim()
```

**Platform Engineering Example**: Processing deployment data

```elixir
defmodule Deployment do
  def prepare(config) do
    config
    |> validate_config()
    |> add_defaults()
    |> transform_to_k8s_manifest()
    |> apply_labels()
    |> encrypt_secrets()
  end
  
  defp validate_config(config), do: # ...
  defp add_defaults(config), do: # ...
  defp transform_to_k8s_manifest(config), do: # ...
  defp apply_labels(manifest), do: # ...
  defp encrypt_secrets(manifest), do: # ...
end
```

## Documentation

Use `@doc` and `@moduledoc`:

```elixir
defmodule HealthChecker do
  @moduledoc """
  Provides health checking functionality for HTTP endpoints.
  
  ## Examples
  
      iex> HealthChecker.check("http://localhost:8080/health")
      {:ok, :healthy}
  """
  
  @doc """
  Checks the health of a service endpoint.
  
  ## Parameters
  
    - url: The health check endpoint URL
    - timeout: Request timeout in milliseconds (default: 5000)
  
  ## Returns
  
    - `{:ok, :healthy}` if service responds with 200
    - `{:error, reason}` otherwise
  """
  def check(url, timeout \\ 5000) do
    # implementation
  end
end
```

Generate docs with: `mix docs`

## Type Specifications (Typespecs)

Optional but recommended for documentation and tooling:

```elixir
defmodule HealthChecker do
  @type status :: :healthy | :unhealthy | :degraded
  @type check_result :: {:ok, status} | {:error, term}
  
  @spec check(String.t(), pos_integer) :: check_result
  def check(url, timeout \\ 5000) do
    # implementation
  end
end
```

## Real-World Platform Engineering Module Example

```elixir
defmodule Infrastructure.ServiceMonitor do
  @moduledoc """
  Monitors service health and reports status.
  """
  
  @default_interval 30_000
  @default_timeout 5_000
  @max_failures 3
  
  alias Infrastructure.Alerts
  alias Infrastructure.Metrics
  
  @doc """
  Starts monitoring a service endpoint.
  """
  @spec start_monitoring(String.t(), keyword) :: :ok
  def start_monitoring(url, opts \\ []) do
    interval = Keyword.get(opts, :interval, @default_interval)
    timeout = Keyword.get(opts, :timeout, @default_timeout)
    
    spawn_monitor_loop(url, interval, timeout, 0)
  end
  
  defp spawn_monitor_loop(url, interval, timeout, failures) do
    spawn(fn -> monitor_loop(url, interval, timeout, failures) end)
    :ok
  end
  
  defp monitor_loop(url, interval, timeout, failures) do
    case check_health(url, timeout) do
      {:ok, response_time} ->
        Metrics.record(:health_check, :success, response_time)
        handle_success(url, failures)
        :timer.sleep(interval)
        monitor_loop(url, interval, timeout, 0)
        
      {:error, reason} ->
        Metrics.record(:health_check, :failure, reason)
        new_failures = failures + 1
        handle_failure(url, new_failures)
        :timer.sleep(interval)
        monitor_loop(url, interval, timeout, new_failures)
    end
  end
  
  defp check_health(url, timeout) do
    start_time = System.monotonic_time(:millisecond)
    
    case HTTPoison.get(url, [], timeout: timeout) do
      {:ok, %{status_code: 200}} ->
        response_time = System.monotonic_time(:millisecond) - start_time
        {:ok, response_time}
        
      {:ok, %{status_code: code}} ->
        {:error, {:bad_status, code}}
        
      {:error, %{reason: reason}} ->
        {:error, reason}
    end
  end
  
  defp handle_success(_url, 0), do: :ok
  
  defp handle_success(url, _previous_failures) do
    Alerts.send("Service recovered: #{url}", :info)
  end
  
  defp handle_failure(url, failures) when failures >= @max_failures do
    Alerts.send("Service critical: #{url}", :critical)
  end
  
  defp handle_failure(url, failures) do
    Alerts.send("Service degraded: #{url} (#{failures} failures)", :warning)
  end
end
```

## Exercises

1. Write a module with a function that formats byte sizes:
   ```elixir
   defmodule ByteFormatter do
     def format(bytes) when bytes < 1024, do: "#{bytes} B"
     def format(bytes) when bytes < 1_048_576, do: "#{Float.round(bytes / 1024, 2)} KB"
     def format(bytes) when bytes < 1_073_741_824, do: "#{Float.round(bytes / 1_048_576, 2)} MB"
     def format(bytes), do: "#{Float.round(bytes / 1_073_741_824, 2)} GB"
   end
   
   ByteFormatter.format(5368709120)  # "5.0 GB"
   ```

2. Create a recursive function to count errors in logs:
   ```elixir
   defmodule LogCounter do
     def count_errors([]), do: 0
     def count_errors([{:error, _} | tail]), do: 1 + count_errors(tail)
     def count_errors([_ | tail]), do: count_errors(tail)
   end
   ```

3. Build a URL builder with default values:
   ```elixir
   defmodule URLBuilder do
     def build(host, path, protocol \\ "https", port \\ 443) do
       "#{protocol}://#{host}:#{port}#{path}"
     end
   end
   ```

4. Create a function pipeline for data transformation:
   ```elixir
   "  ERROR: deployment failed  "
   |> String.trim()
   |> String.split(": ")
   |> List.last()
   |> String.upcase()
   # "DEPLOYMENT FAILED"
   ```

## Key Takeaways

1. **Anonymous functions**: Use `fn` or `&()` syntax
2. **Named functions**: Must be in modules
3. **Pattern matching**: Multiple clauses for different inputs
4. **Guards**: Add conditions with `when`
5. **Recursion**: The Elixir way to loop
6. **Private functions**: Use `defp` for internal functions
7. **Pipe operator**: Chain transformations elegantly

## What's Next?

Now that you can write functions and modules, let's explore Elixir's powerful collection processing:
- [Collections & Enumerables](05-collections.md)

## Additional Resources

- [Elixir Modules and Functions](https://elixir-lang.org/getting-started/modules-and-functions.html)
- [Elixir School - Functions](https://elixirschool.com/en/lessons/basics/functions)

