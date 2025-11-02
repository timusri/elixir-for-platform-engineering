# Control Flow & Error Handling

## Overview

Elixir provides several constructs for controlling program flow and handling errors. Unlike imperative languages, Elixir uses pattern matching and functional patterns instead of traditional if/else chains and try/catch blocks.

## Case

Pattern match against multiple possibilities:

```elixir
case expression do
  pattern1 -> result1
  pattern2 when guard -> result2
  pattern3 -> result3
  _ -> default_result
end
```

### Basic Case Examples

```elixir
iex> case {1, 2, 3} do
...>   {4, 5, 6} -> "Won't match"
...>   {1, x, 3} -> "Matches, x = #{x}"
...>   _ -> "Default"
...> end
"Matches, x = 2"
```

**Platform Engineering Example**: Handle HTTP responses

```elixir
defmodule APIClient do
  def handle_response(response) do
    case response do
      {:ok, %{status: 200, body: body}} ->
        {:success, Jason.decode!(body)}
        
      {:ok, %{status: 201, body: body}} ->
        {:created, Jason.decode!(body)}
        
      {:ok, %{status: status}} when status >= 400 and status < 500 ->
        {:client_error, status}
        
      {:ok, %{status: status}} when status >= 500 ->
        {:server_error, status}
        
      {:error, %{reason: :timeout}} ->
        {:error, :timeout}
        
      {:error, reason} ->
        {:error, reason}
    end
  end
end
```

### Case with Guards

```elixir
defmodule PortChecker do
  def check_port(port) do
    case port do
      p when p < 1 ->
        {:error, :invalid_port}
        
      p when p < 1024 ->
        {:warning, :privileged_port}
        
      p when p > 65535 ->
        {:error, :port_too_high}
        
      p ->
        {:ok, p}
    end
  end
end
```

## Cond

Check multiple conditions (like if/else if chains):

```elixir
cond do
  condition1 -> result1
  condition2 -> result2
  true -> default_result
end
```

### Cond Examples

```elixir
iex> x = 75
iex> cond do
...>   x > 90 -> "Excellent"
...>   x > 70 -> "Good"
...>   x > 50 -> "Average"
...>   true -> "Needs improvement"
...> end
"Good"
```

**Platform Engineering Example**: System health classification

```elixir
defmodule SystemHealth do
  def classify(cpu_usage, memory_usage, disk_usage) do
    cond do
      cpu_usage > 90 or memory_usage > 90 or disk_usage > 90 ->
        {:critical, "System resources critically high"}
        
      cpu_usage > 75 or memory_usage > 75 or disk_usage > 75 ->
        {:warning, "System resources elevated"}
        
      cpu_usage > 50 or memory_usage > 50 or disk_usage > 50 ->
        {:notice, "System resources moderate"}
        
      true ->
        {:healthy, "System resources normal"}
    end
  end
end
```

## If and Unless

Simple boolean conditions:

```elixir
if condition do
  # if true
else
  # if false
end

unless condition do
  # if false
else
  # if true
end
```

### Examples

```elixir
iex> if true, do: "Yes", else: "No"
"Yes"

iex> unless false, do: "Proceed"
"Proceed"

# One-line syntax
iex> if 2 + 2 == 4, do: "Math works"
"Math works"
```

**Platform Engineering Example**: Deployment checks

```elixir
defmodule Deployment do
  def can_deploy?(env, tests_passing?, approvals) do
    if tests_passing? and approvals >= required_approvals(env) do
      {:ok, "Ready to deploy"}
    else
      {:error, "Deployment requirements not met"}
    end
  end
  
  defp required_approvals("production"), do: 2
  defp required_approvals(_), do: 1
end
```

## With

Handle multiple pattern matches in sequence:

```elixir
with pattern1 <- expression1,
     pattern2 <- expression2,
     pattern3 <- expression3 do
  success_result
else
  error_pattern -> handle_error
end
```

### With Examples

```elixir
defmodule UserValidator do
  def validate_and_create(params) do
    with {:ok, username} <- validate_username(params["username"]),
         {:ok, email} <- validate_email(params["email"]),
         {:ok, password} <- validate_password(params["password"]) do
      create_user(username, email, password)
    else
      {:error, reason} -> {:error, reason}
    end
  end
end
```

**Platform Engineering Example**: Deployment validation

```elixir
defmodule DeploymentValidator do
  def validate_and_deploy(config) do
    with {:ok, manifest} <- parse_manifest(config),
         {:ok, _} <- validate_resources(manifest),
         {:ok, _} <- check_quotas(manifest),
         {:ok, _} <- validate_secrets(manifest),
         {:ok, deployment} <- apply_deployment(manifest) do
      {:ok, deployment}
    else
      {:error, :invalid_manifest, reason} ->
        {:error, "Manifest error: #{reason}"}
        
      {:error, :insufficient_resources, needed} ->
        {:error, "Not enough resources: #{inspect(needed)}"}
        
      {:error, :quota_exceeded, quota} ->
        {:error, "Quota exceeded: #{quota}"}
        
      {:error, reason} ->
        {:error, "Deployment failed: #{inspect(reason)}"}
    end
  end
end
```

## Error Handling

### The Two Types of Errors

1. **Expected errors**: Return `{:ok, result}` or `{:error, reason}` tuples
2. **Unexpected errors**: Raise exceptions

### Expected Errors (The Elixir Way)

```elixir
def check_service(url) do
  case HTTP.get(url) do
    {:ok, %{status: 200}} -> {:ok, :healthy}
    {:ok, %{status: _}} -> {:error, :unhealthy}
    {:error, reason} -> {:error, reason}
  end
end

# Usage
case check_service("http://api/health") do
  {:ok, :healthy} -> 
    IO.puts("Service healthy")
  {:error, reason} -> 
    IO.puts("Service unhealthy: #{inspect(reason)}")
end
```

### Raising Exceptions

```elixir
# Raise a runtime error
iex> raise "Something went wrong"
** (RuntimeError) Something went wrong

# Raise specific error type
iex> raise ArgumentError, message: "Invalid port"
** (ArgumentError) Invalid port
```

**When to raise**: Programming errors, not business logic errors

```elixir
defmodule Server do
  def start(port) when is_integer(port) and port > 0 do
    # Start server
  end
  
  def start(_port) do
    raise ArgumentError, "Port must be a positive integer"
  end
end
```

### Try/Rescue/After

```elixir
try do
  risky_operation()
rescue
  error_type -> handle_error(error_type)
after
  cleanup()
end
```

### Try/Rescue Examples

```elixir
defmodule FileHandler do
  def read_config(path) do
    try do
      content = File.read!(path)
      Jason.decode!(content)
    rescue
      File.Error -> {:error, :file_not_found}
      Jason.DecodeError -> {:error, :invalid_json}
    end
  end
end
```

**Platform Engineering Example**: Safe file operations

```elixir
defmodule ConfigLoader do
  def load_config(path) do
    try do
      path
      |> File.read!()
      |> Jason.decode!()
      |> validate_config()
    rescue
      File.Error ->
        IO.puts("Config file not found, using defaults")
        default_config()
        
      Jason.DecodeError ->
        IO.puts("Invalid JSON in config file")
        {:error, :invalid_config}
    after
      IO.puts("Config load attempt completed")
    end
  end
  
  defp validate_config(config) do
    # Validation logic
    {:ok, config}
  end
  
  defp default_config do
    %{timeout: 5000, retries: 3}
  end
end
```

### Try/Catch

For catching thrown values (rare in Elixir):

```elixir
try do
  throw(:something)
catch
  value -> "Caught: #{value}"
end
```

## The Bang Convention

Functions ending with `!` raise on error:

```elixir
# Returns {:ok, content} or {:error, reason}
iex> File.read("existing.txt")
{:ok, "file contents"}

# Returns content or raises
iex> File.read!("existing.txt")
"file contents"

iex> File.read!("missing.txt")
** (File.Error) could not read file "missing.txt": no such file or directory
```

**When to use**:
- `File.read/1`: When you want to handle errors
- `File.read!/1`: When missing file is a programming error

**Platform Engineering Example**:

```elixir
# Use ! when file MUST exist (configuration)
defmodule App do
  def start do
    config = File.read!("config/prod.exs")  # Crash if missing
    # ...
  end
end

# Don't use ! when file might not exist
defmodule Logger do
  def rotate_logs do
    case File.read("app.log") do
      {:ok, content} -> archive(content)
      {:error, _} -> IO.puts("No logs to rotate")
    end
  end
end
```

## Custom Errors

Define your own error types:

```elixir
defmodule DeploymentError do
  defexception [:message, :reason, :service]
  
  @impl true
  def exception(opts) do
    service = Keyword.get(opts, :service, "unknown")
    reason = Keyword.get(opts, :reason, "unknown")
    
    %DeploymentError{
      message: "Deployment failed for #{service}: #{reason}",
      reason: reason,
      service: service
    }
  end
end

# Usage
raise DeploymentError, service: "api", reason: :timeout
```

## Error Handling Patterns

### Pattern 1: Return Tuples

```elixir
defmodule HealthChecker do
  def check(url) do
    case HTTP.get(url) do
      {:ok, %{status: 200}} -> {:ok, :healthy}
      {:ok, %{status: code}} -> {:error, {:unhealthy, code}}
      {:error, reason} -> {:error, {:unreachable, reason}}
    end
  end
end

# Usage
case HealthChecker.check(url) do
  {:ok, :healthy} -> handle_healthy()
  {:error, {:unhealthy, code}} -> handle_unhealthy(code)
  {:error, {:unreachable, reason}} -> handle_unreachable(reason)
end
```

### Pattern 2: With Clause

```elixir
defmodule Deployment do
  def deploy(config) do
    with {:ok, validated} <- validate(config),
         {:ok, built} <- build(validated),
         {:ok, tested} <- test(built),
         {:ok, deployed} <- push(tested) do
      {:ok, deployed}
    else
      {:error, reason} -> {:error, reason}
    end
  end
end
```

### Pattern 3: Let It Crash

```elixir
defmodule Worker do
  def process(data) do
    # Don't catch errors - let supervisor restart us
    data
    |> validate!()     # Raises on invalid data
    |> transform!()    # Raises on transformation error
    |> save!()         # Raises on save error
  end
end
```

## Real-World Platform Engineering Example

```elixir
defmodule InfrastructureProvisioner do
  def provision(config) do
    with {:ok, validated_config} <- validate_config(config),
         {:ok, vpc} <- create_vpc(validated_config),
         {:ok, subnets} <- create_subnets(vpc),
         {:ok, security_groups} <- create_security_groups(vpc),
         {:ok, instances} <- launch_instances(subnets, security_groups),
         {:ok, _} <- configure_load_balancer(instances) do
      {:ok, %{
        vpc: vpc,
        instances: instances,
        status: :provisioned
      }}
    else
      {:error, :invalid_config, errors} ->
        Logger.error("Config validation failed: #{inspect(errors)}")
        {:error, :invalid_config}
        
      {:error, :vpc_creation_failed, reason} ->
        Logger.error("VPC creation failed: #{inspect(reason)}")
        {:error, :vpc_creation_failed}
        
      {:error, step, reason} ->
        Logger.error("Provisioning failed at #{step}: #{inspect(reason)}")
        cleanup_partial_infrastructure()
        {:error, {step, reason}}
    end
  end
  
  defp validate_config(config) do
    cond do
      not Map.has_key?(config, :region) ->
        {:error, :invalid_config, [:missing_region]}
        
      not Map.has_key?(config, :instance_type) ->
        {:error, :invalid_config, [:missing_instance_type]}
        
      true ->
        {:ok, config}
    end
  end
  
  defp create_vpc(config) do
    case AWS.create_vpc(config) do
      {:ok, vpc} -> {:ok, vpc}
      {:error, reason} -> {:error, :vpc_creation_failed, reason}
    end
  end
  
  defp cleanup_partial_infrastructure do
    # Cleanup logic
    :ok
  end
end
```

## Exercises

1. Write a function that categorizes system load:
   ```elixir
   defmodule SystemMonitor do
     def categorize_load(load) do
       cond do
         load < 0.5 -> :light
         load < 1.0 -> :moderate
         load < 2.0 -> :heavy
         true -> :critical
       end
     end
   end
   ```

2. Create a deployment validator with `with`:
   ```elixir
   defmodule Validator do
     def validate_deployment(config) do
       with {:ok, _} <- check_syntax(config),
            {:ok, _} <- check_resources(config),
            {:ok, _} <- check_permissions(config) do
         {:ok, :valid}
       else
         {:error, reason} -> {:error, reason}
       end
     end
   end
   ```

3. Handle file operations safely:
   ```elixir
   defmodule SafeFile do
     def read_or_default(path, default) do
       case File.read(path) do
         {:ok, content} -> content
         {:error, _} -> default
       end
     end
   end
   ```

4. Create a custom exception:
   ```elixir
   defmodule ServiceUnavailableError do
     defexception [:service, :message]
     
     def exception(service) do
       %ServiceUnavailableError{
         service: service,
         message: "Service #{service} is unavailable"
       }
     end
   end
   ```

## Key Takeaways

1. **case**: Pattern match on values
2. **cond**: Check multiple conditions
3. **with**: Chain operations that might fail
4. **if/unless**: Simple boolean checks
5. **{:ok, result} / {:error, reason}**: The Elixir way for expected errors
6. **raise/rescue**: For unexpected errors only
7. **Let it crash**: Don't be defensive, use supervisors
8. **! convention**: Functions that raise on error

## What's Next?

You've completed the beginner level! You now understand:
- Elixir syntax and data types
- Pattern matching
- Functions and modules
- Collections and enumerables
- Control flow and error handling

Ready for intermediate topics? Let's dive into concurrency and processes:
- [Processes & Message Passing](../02-intermediate/01-processes.md)

## Additional Resources

- [Elixir Case, Cond, and If](https://elixir-lang.org/getting-started/case-cond-and-if.html)
- [Elixir Error Handling](https://elixir-lang.org/getting-started/try-catch-and-rescue.html)
- [Elixir School - Control Structures](https://elixirschool.com/en/lessons/basics/control_structures)

