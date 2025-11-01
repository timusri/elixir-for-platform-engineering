# Testing with ExUnit

## Overview

ExUnit is Elixir's built-in testing framework. It's powerful, concurrent, and comes with everything you need for testing.

## Your First Test

```elixir
# test/my_module_test.exs
defmodule MyModuleTest do
  use ExUnit.Case
  doctest MyModule

  test "adds two numbers" do
    assert MyModule.add(2, 3) == 5
  end
  
  test "subtracts two numbers" do
    assert MyModule.subtract(5, 3) == 2
  end
end
```

Run tests:

```bash
mix test
```

## Test Structure

### Basic Test

```elixir
defmodule HealthCheckerTest do
  use ExUnit.Case
  
  test "returns :healthy for 200 status" do
    result = HealthChecker.check_status(200)
    assert result == :healthy
  end
  
  test "returns :unhealthy for 500 status" do
    result = HealthChecker.check_status(500)
    assert result == :unhealthy
  end
end
```

### Setup and Cleanup

```elixir
defmodule ServerTest do
  use ExUnit.Case
  
  setup do
    # Runs before each test
    {:ok, pid} = Server.start_link([])
    %{server: pid}
  end
  
  setup_all do
    # Runs once before all tests
    :ok
  end
  
  test "gets value from server", %{server: server} do
    Server.put(server, :key, "value")
    assert Server.get(server, :key) == "value"
  end
end
```

## Assertions

### Basic Assertions

```elixir
# Equality
assert 1 + 1 == 2
refute 1 + 1 == 3

# Truthiness
assert true
refute false

# Pattern matching
assert {:ok, result} = function_call()

# Membership
assert 2 in [1, 2, 3]
refute 5 in [1, 2, 3]

# Exceptions
assert_raise ArgumentError, fn ->
  raise ArgumentError
end

# Messages received
assert_received {:message, "data"}
refute_received {:other, "data"}

# Approximate equality (floats)
assert_in_delta 0.1 + 0.2, 0.3, 0.0001
```

### Custom Messages

```elixir
assert value == expected, "Expected #{expected}, got #{value}"
```

## DevOps Testing Example

```elixir
defmodule HealthCheckerTest do
  use ExUnit.Case
  
  describe "check/1" do
    test "returns :healthy for accessible service" do
      result = HealthChecker.check("http://localhost:8080/health")
      assert {:ok, :healthy} = result
    end
    
    test "returns :unhealthy for 500 response" do
      result = HealthChecker.check("http://localhost:8080/error")
      assert {:error, {:unhealthy, 500}} = result
    end
    
    test "returns :unreachable for timeout" do
      result = HealthChecker.check("http://localhost:9999/health")
      assert {:error, {:unreachable, _}} = result
    end
  end
  
  describe "check_multiple/1" do
    test "checks multiple services concurrently" do
      services = [
        "http://api-1:8080/health",
        "http://api-2:8080/health"
      ]
      
      results = HealthChecker.check_multiple(services)
      assert length(results) == 2
    end
  end
end
```

## Doctest

Test examples in documentation:

```elixir
defmodule Math do
  @doc """
  Adds two numbers.
  
  ## Examples
  
      iex> Math.add(2, 3)
      5
      
      iex> Math.add(0, 0)
      0
  """
  def add(a, b), do: a + b
end

# Test file
defmodule MathTest do
  use ExUnit.Case
  doctest Math  # Runs doctest examples
end
```

## Testing GenServers

```elixir
defmodule ConfigServerTest do
  use ExUnit.Case
  
  setup do
    {:ok, pid} = ConfigServer.start_link(%{})
    %{server: pid}
  end
  
  test "stores and retrieves values", %{server: server} do
    ConfigServer.set(server, :key, "value")
    assert ConfigServer.get(server, :key) == "value"
  end
  
  test "returns nil for missing keys", %{server: server} do
    assert ConfigServer.get(server, :missing) == nil
  end
  
  test "handles concurrent requests", %{server: server} do
    tasks = Enum.map(1..100, fn i ->
      Task.async(fn ->
        ConfigServer.set(server, "key#{i}", i)
        ConfigServer.get(server, "key#{i}")
      end)
    end)
    
    results = Enum.map(tasks, &Task.await/1)
    assert length(results) == 100
  end
end
```

## Mocking and Stubbing

### Using Mox

```elixir
# In mix.exs
defp deps do
  [
    {:mox, "~> 1.0", only: :test}
  ]
end

# Define behavior
defmodule HTTPClient do
  @callback get(String.t()) :: {:ok, map()} | {:error, term()}
end

# In test/test_helper.exs
Mox.defmock(HTTPClientMock, for: HTTPClient)

# In tests
defmodule ServiceTest do
  use ExUnit.Case, async: true
  import Mox
  
  setup :verify_on_exit!
  
  test "handles successful response" do
    expect(HTTPClientMock, :get, fn _url ->
      {:ok, %{status: 200, body: "OK"}}
    end)
    
    result = Service.check_health(HTTPClientMock)
    assert result == :healthy
  end
  
  test "handles error response" do
    expect(HTTPClientMock, :get, fn _url ->
      {:error, :timeout}
    end)
    
    result = Service.check_health(HTTPClientMock)
    assert result == :error
  end
end
```

## Async Tests

Run tests concurrently:

```elixir
defmodule FastTest do
  use ExUnit.Case, async: true
  
  test "runs concurrently" do
    # This test can run in parallel with others
  end
end
```

⚠️ Only use `async: true` if tests don't share state!

## Tags

Organize and filter tests:

```elixir
defmodule MyTest do
  use ExUnit.Case
  
  @tag :slow
  test "expensive operation" do
    # ...
  end
  
  @tag :integration
  test "external service" do
    # ...
  end
  
  @tag skip: "Not implemented yet"
  test "future feature" do
    # ...
  end
end
```

Run specific tags:

```bash
# Only integration tests
mix test --only integration

# Exclude slow tests
mix test --exclude slow

# Include skip tagged tests
mix test --include skip
```

## Test Coverage

```elixir
# In mix.exs
def project do
  [
    test_coverage: [tool: ExCoveralls],
    preferred_cli_env: [
      coveralls: :test,
      "coveralls.detail": :test,
      "coveralls.html": :test
    ]
  ]
end

defp deps do
  [
    {:excoveralls, "~> 0.16", only: :test}
  ]
end
```

Run coverage:

```bash
mix coveralls
mix coveralls.html  # Generate HTML report
```

## Real-World Testing Example

```elixir
defmodule InfraMonitor.ServiceMonitorTest do
  use ExUnit.Case, async: true
  
  alias InfraMonitor.ServiceMonitor
  
  describe "add_service/2" do
    setup do
      {:ok, pid} = ServiceMonitor.start_link([])
      %{monitor: pid}
    end
    
    test "adds a new service", %{monitor: monitor} do
      assert :ok = ServiceMonitor.add_service(monitor, "api", "http://api/health")
      
      status = ServiceMonitor.get_status(monitor)
      assert Map.has_key?(status, "api")
    end
    
    test "prevents duplicate services", %{monitor: monitor} do
      ServiceMonitor.add_service(monitor, "api", "http://api/health")
      
      assert {:error, :already_exists} =
        ServiceMonitor.add_service(monitor, "api", "http://api/health")
    end
  end
  
  describe "perform_checks/1" do
    setup do
      {:ok, monitor} = ServiceMonitor.start_link([])
      
      # Mock HTTP calls
      Application.put_env(:infra_monitor, :http_client, HTTPClientMock)
      
      %{monitor: monitor}
    end
    
    test "updates service status after check", %{monitor: monitor} do
      ServiceMonitor.add_service(monitor, "api", "http://api/health")
      
      expect(HTTPClientMock, :get, fn _url ->
        {:ok, %{status_code: 200}}
      end)
      
      send(monitor, :perform_check)
      :timer.sleep(100)  # Wait for async update
      
      status = ServiceMonitor.get_service_status(monitor, "api")
      assert status.status == :healthy
    end
    
    test "tracks consecutive failures", %{monitor: monitor} do
      ServiceMonitor.add_service(monitor, "api", "http://api/health")
      
      # Simulate 3 failures
      expect(HTTPClientMock, :get, 3, fn _url ->
        {:error, :timeout}
      end)
      
      Enum.each(1..3, fn _ ->
        send(monitor, :perform_check)
        :timer.sleep(100)
      end)
      
      status = ServiceMonitor.get_service_status(monitor, "api")
      assert status.status == :critical
    end
  end
  
  @tag :integration
  test "integrates with real HTTP service" do
    {:ok, monitor} = ServiceMonitor.start_link([])
    ServiceMonitor.add_service(monitor, "github", "https://github.com")
    
    send(monitor, :perform_check)
    :timer.sleep(1000)
    
    status = ServiceMonitor.get_service_status(monitor, "github")
    assert status.status in [:healthy, :unhealthy]
  end
end
```

## Property-Based Testing

Using StreamData:

```elixir
# In mix.exs
{:stream_data, "~> 0.5", only: :test}

# Test
defmodule MathTest do
  use ExUnit.Case
  use ExUnitProperties
  
  property "addition is commutative" do
    check all a <- integer(),
              b <- integer() do
      assert Math.add(a, b) == Math.add(b, a)
    end
  end
  
  property "list reversal is its own inverse" do
    check all list <- list_of(integer()) do
      assert list |> Enum.reverse() |> Enum.reverse() == list
    end
  end
end
```

## Best Practices

1. **Test behavior, not implementation**
2. **Use descriptive test names**
3. **One assertion per test** (when possible)
4. **Use `async: true`** for independent tests
5. **Mock external services**
6. **Test edge cases**
7. **Keep tests fast**

## Common Testing Patterns

### Testing timeouts

```elixir
test "times out after 5 seconds" do
  task = Task.async(fn ->
    :timer.sleep(10_000)
  end)
  
  assert_raise Task.TimeoutError, fn ->
    Task.await(task, 5000)
  end
end
```

### Testing crashes

```elixir
test "process crashes on invalid input" do
  Process.flag(:trap_exit, true)
  pid = spawn_link(fn -> Worker.process(invalid_data) end)
  
  assert_receive {:EXIT, ^pid, _reason}, 1000
end
```

### Testing messages

```elixir
test "sends notification message" do
  Notifier.notify(:alert, "System down")
  
  assert_received {:notification, :alert, "System down"}
end
```

## Exercises

1. Write tests for a key-value store GenServer
2. Test concurrent operations
3. Add property-based tests
4. Write integration tests for a health checker
5. Add test coverage and aim for >80%

## Key Takeaways

1. **ExUnit**: Built-in, powerful testing framework
2. **Async tests**: Run tests concurrently
3. **Mocking**: Use Mox for external dependencies
4. **Doctests**: Test documentation examples
5. **Tags**: Organize and filter tests
6. **Coverage**: Track test coverage

## What's Next?

You've completed intermediate level! Ready for advanced topics:
- [Advanced OTP Patterns](../03-advanced/01-advanced-otp.md)
- [Distribution & Clustering](../03-advanced/02-distribution.md)

## Additional Resources

- [ExUnit Documentation](https://hexdocs.pm/ex_unit/)
- [Mox Documentation](https://hexdocs.pm/mox/)
- [Testing Elixir Book](https://pragprog.com/titles/lmelixir/testing-elixir/)

