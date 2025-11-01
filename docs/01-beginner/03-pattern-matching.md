# Pattern Matching

## What is Pattern Matching?

Pattern matching is one of Elixir's most powerful features. It's not just comparison - it's a way to destructure data, extract values, and control program flow all at once.

In most languages, `=` is assignment. In Elixir, `=` is the **match operator**.

## The Match Operator `=`

### Basic Matching

```elixir
iex> x = 1
1
iex> x
1

# The match operator tries to make left side equal to right side
iex> 1 = x
1

# This fails because 2 doesn't match x (which is 1)
iex> 2 = x
** (MatchError) no match of right hand side value: 1
```

Think of `=` as asserting that left and right sides are equal, binding variables as needed.

### Practical Example

```elixir
# Traditional assignment mindset
iex> response = {:ok, 200, "Success"}

# Pattern matching mindset
iex> {:ok, status_code, message} = response
{:ok, 200, "Success"}
iex> status_code
200
iex> message
"Success"
```

## Matching with Data Structures

### Tuples

```elixir
# Match all elements
iex> {:ok, result} = {:ok, "deployed"}
{:ok, "deployed"}
iex> result
"deployed"

# Match with specific values
iex> {:ok, 200} = {:ok, 200}
{:ok, 200}

# This fails - tags don't match
iex> {:ok, data} = {:error, "failed"}
** (MatchError) no match of right hand side value: {:error, "failed"}
```

**DevOps Example**: API Response Handling

```elixir
case HTTP.get("https://api.example.com/health") do
  {:ok, %{status: 200, body: body}} ->
    IO.puts("Service healthy: #{body}")
    
  {:ok, %{status: status}} ->
    IO.puts("Service returned: #{status}")
    
  {:error, %{reason: :timeout}} ->
    IO.puts("Service timed out")
    
  {:error, reason} ->
    IO.puts("Error: #{inspect(reason)}")
end
```

### Lists

```elixir
# Match head and tail
iex> [head | tail] = [1, 2, 3, 4, 5]
[1, 2, 3, 4, 5]
iex> head
1
iex> tail
[2, 3, 4, 5]

# Match specific elements
iex> [first, second | rest] = [1, 2, 3, 4]
[1, 2, 3, 4]
iex> first
1
iex> second
2
iex> rest
[3, 4]

# Match exact list
iex> [1, 2, 3] = [1, 2, 3]
[1, 2, 3]

# Match empty list
iex> [] = []
[]
```

**DevOps Example**: Processing log entries

```elixir
def process_logs([]), do: :done

def process_logs([log | remaining_logs]) do
  handle_log(log)
  process_logs(remaining_logs)
end

# Usage
process_logs([
  "ERROR: Connection timeout",
  "INFO: Retry attempt 1",
  "INFO: Retry successful"
])
```

### Maps

```elixir
# Match specific keys
iex> %{name: name} = %{name: "web-1", ip: "10.0.0.1", port: 80}
%{name: "web-1", ip: "10.0.0.1", port: 80}
iex> name
"web-1"

# Match multiple keys
iex> %{name: n, port: p} = %{name: "web-1", ip: "10.0.0.1", port: 80}
iex> n
"web-1"
iex> p
80

# Match with specific value
iex> %{port: 80} = %{name: "web-1", port: 80}
%{name: "web-1", port: 80}

# This fails - port doesn't match
iex> %{port: 443} = %{name: "web-1", port: 80}
** (MatchError) no match of right hand side value
```

**DevOps Example**: Container metadata

```elixir
container = %{
  id: "abc123",
  name: "nginx",
  status: :running,
  ports: [80, 443],
  labels: %{env: "prod", team: "platform"}
}

# Extract specific fields
%{name: name, status: status} = container
# name = "nginx", status = :running

# Match and assert status
%{status: :running, name: name} = container
# Only matches if status is :running
```

## The Pin Operator `^`

The pin operator prevents rebinding and forces a match against the current value.

```elixir
iex> x = 1
1

# Without pin - rebinds x
iex> x = 2
2

# With pin - matches against current value
iex> x = 1
1
iex> ^x = 1
1
iex> ^x = 2
** (MatchError) no match of right hand side value: 2
```

**DevOps Example**: Validating expected values

```elixir
expected_version = "1.2.3"

case get_deployed_version() do
  ^expected_version ->
    IO.puts("Version matches: #{expected_version}")
    
  other_version ->
    IO.puts("Version mismatch! Expected: #{expected_version}, Got: #{other_version}")
end
```

## Pattern Matching in Functions

This is where pattern matching really shines!

### Multiple Function Clauses

```elixir
defmodule StatusChecker do
  # Match on different response patterns
  def handle_response({:ok, 200, body}) do
    {:success, body}
  end
  
  def handle_response({:ok, status, _body}) when status >= 400 do
    {:error, :client_error}
  end
  
  def handle_response({:ok, status, _body}) when status >= 500 do
    {:error, :server_error}
  end
  
  def handle_response({:error, reason}) do
    {:error, reason}
  end
end
```

### Function with Guards

```elixir
defmodule PortValidator do
  def validate(port) when port < 1024 do
    {:error, :privileged_port}
  end
  
  def validate(port) when port > 65535 do
    {:error, :out_of_range}
  end
  
  def validate(port) do
    {:ok, port}
  end
end

iex> PortValidator.validate(80)
{:error, :privileged_port}
iex> PortValidator.validate(8080)
{:ok, 8080}
```

**DevOps Example**: Health check classifier

```elixir
defmodule HealthCheck do
  def classify(response_time) when response_time < 100 do
    :excellent
  end
  
  def classify(response_time) when response_time < 500 do
    :good
  end
  
  def classify(response_time) when response_time < 1000 do
    :acceptable
  end
  
  def classify(_response_time) do
    :poor
  end
end

iex> HealthCheck.classify(50)
:excellent
iex> HealthCheck.classify(750)
:acceptable
```

## Case Expressions

Use `case` for pattern matching on values.

```elixir
case expression do
  pattern1 -> result1
  pattern2 -> result2
  _ -> default_result
end
```

**DevOps Example**: Processing deployment status

```elixir
def handle_deployment_status(status) do
  case status do
    {:success, version} ->
      notify_team("Deployed version #{version}")
      log_deployment(version)
      {:ok, version}
      
    {:in_progress, percentage} when percentage >= 50 ->
      IO.puts("Deployment #{percentage}% complete")
      :wait
      
    {:in_progress, _} ->
      :wait
      
    {:failed, reason} ->
      alert_oncall("Deployment failed: #{reason}")
      rollback_deployment()
      {:error, reason}
      
    _ ->
      {:error, :unknown_status}
  end
end
```

## Cond Expressions

When you need multiple conditions (like if/else chains):

```elixir
cond do
  condition1 -> result1
  condition2 -> result2
  true -> default_result
end
```

**DevOps Example**: Resource allocation

```elixir
def allocate_resources(memory_mb) do
  cond do
    memory_mb < 512 ->
      {:micro, 0.5}
      
    memory_mb < 2048 ->
      {:small, 1.0}
      
    memory_mb < 8192 ->
      {:medium, 2.0}
      
    true ->
      {:large, 4.0}
  end
end
```

## The Underscore `_`

The underscore matches anything but doesn't bind.

```elixir
# Ignore values you don't need
iex> {_, status, _} = {:ok, 200, "body"}
{:ok, 200, "body"}
iex> status
200

# Multiple underscores are independent
iex> {_, _, _} = {:ok, 200, "body"}
{:ok, 200, "body"}

# Named underscore for clarity (still not bound)
iex> {_tag, status, _body} = {:ok, 200, "body"}
iex> status
200
```

**DevOps Example**: Extracting specific metrics

```elixir
metrics = [
  {:cpu, 75.5, :percent},
  {:memory, 4096, :mb},
  {:disk, 100, :gb}
]

for {metric_name, value, _unit} <- metrics do
  IO.puts("#{metric_name}: #{value}")
end
# cpu: 75.5
# memory: 4096
# disk: 100
```

## Pattern Matching with Strings

### String prefix matching

```elixir
iex> "Hello " <> name = "Hello World"
"Hello World"
iex> name
"World"

# Must match exact prefix
iex> "ERROR: " <> message = "ERROR: Connection failed"
"ERROR: Connection failed"
iex> message
"Connection failed"
```

**DevOps Example**: Log level extraction

```elixir
defmodule LogParser do
  def parse("ERROR: " <> message), do: {:error, message}
  def parse("WARN: " <> message), do: {:warn, message}
  def parse("INFO: " <> message), do: {:info, message}
  def parse(message), do: {:unknown, message}
end

iex> LogParser.parse("ERROR: Connection timeout")
{:error, "Connection timeout"}
```

## Complex Pattern Matching

### Nested Patterns

```elixir
# Nested data structure
deployment = {
  :deployment,
  %{
    name: "api-service",
    version: "v2.1.0",
    status: {:running, 3}
  }
}

# Nested pattern match
{:deployment, %{name: name, status: {:running, replicas}}} = deployment

iex> name
"api-service"
iex> replicas
3
```

**DevOps Example**: Kubernetes-style nested config

```elixir
config = %{
  metadata: %{
    name: "nginx",
    namespace: "production",
    labels: %{app: "web", tier: "frontend"}
  },
  spec: %{
    replicas: 3,
    containers: [
      %{name: "nginx", image: "nginx:1.21", ports: [80, 443]}
    ]
  }
}

# Extract nested values
%{
  metadata: %{name: name, namespace: ns},
  spec: %{replicas: count}
} = config

# name = "nginx"
# ns = "production"
# count = 3
```

## Common DevOps Patterns

### API Response Handling

```elixir
case HTTP.post(url, body, headers) do
  {:ok, %{status_code: 200, body: response_body}} ->
    Jason.decode(response_body)
    
  {:ok, %{status_code: 201, body: response_body}} ->
    Jason.decode(response_body)
    
  {:ok, %{status_code: code}} when code >= 400 ->
    {:error, {:http_error, code}}
    
  {:error, %HTTPoison.Error{reason: :timeout}} ->
    {:error, :timeout}
    
  {:error, reason} ->
    {:error, reason}
end
```

### Process Message Matching

```elixir
receive do
  {:health_check, pid} ->
    send(pid, {:ok, :healthy})
    
  {:shutdown, reason} ->
    cleanup()
    exit(reason)
    
  {:update_config, new_config} ->
    apply_config(new_config)
    
  unknown ->
    Logger.warn("Unknown message: #{inspect(unknown)}")
end
```

### Configuration Validation

```elixir
def validate_config(config) do
  case config do
    %{host: host, port: port} when is_binary(host) and is_integer(port) ->
      {:ok, config}
      
    %{host: _} ->
      {:error, :invalid_port}
      
    %{port: _} ->
      {:error, :missing_host}
      
    _ ->
      {:error, :invalid_config}
  end
end
```

## Exercises

1. Match and extract values from a tuple:
   ```elixir
   response = {:ok, 200, "Success"}
   {:ok, status, message} = response
   ```

2. Extract the first error from a list of logs:
   ```elixir
   logs = [
     {:info, "Starting service"},
     {:error, "Connection failed"},
     {:info, "Retrying"}
   ]
   
   find_error = fn
     [{:error, msg} | _] -> {:found, msg}
     [_ | rest] -> find_error.(rest)
     [] -> :not_found
   end
   
   find_error.(logs)
   ```

3. Write a function that categorizes HTTP status codes:
   ```elixir
   defmodule HTTP do
     def categorize(code) when code >= 200 and code < 300, do: :success
     def categorize(code) when code >= 300 and code < 400, do: :redirect
     def categorize(code) when code >= 400 and code < 500, do: :client_error
     def categorize(code) when code >= 500, do: :server_error
     def categorize(_), do: :unknown
   end
   ```

4. Parse environment from a config map:
   ```elixir
   config = %{
     app: "api",
     env: "production",
     debug: false
   }
   
   %{env: env} = config  # env = "production"
   ```

5. Match nested deployment information:
   ```elixir
   deployment = %{
     metadata: %{name: "nginx", version: "1.21"},
     status: {:running, 3}
   }
   
   %{
     metadata: %{name: name},
     status: {state, replicas}
   } = deployment
   ```

## Key Takeaways

1. **`=` is match, not assignment**: It tries to make both sides equal
2. **Pattern matching extracts data**: No need for accessor methods
3. **Multiple function clauses**: Elegant way to handle different cases
4. **Guards add conditions**: `when` clauses for extra validation
5. **`^` pins values**: Match against existing variable value
6. **`_` ignores values**: Skip data you don't need

## What's Next?

Pattern matching works beautifully with functions and modules:
- [Functions & Modules](04-functions-modules.md)

## Additional Resources

- [Elixir Pattern Matching](https://elixir-lang.org/getting-started/pattern-matching.html)
- [Elixir School - Pattern Matching](https://elixirschool.com/en/lessons/basics/pattern_matching)

