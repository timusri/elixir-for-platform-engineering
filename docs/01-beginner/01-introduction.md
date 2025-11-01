# Introduction to Elixir & the BEAM VM

## What is Elixir?

Elixir is a dynamic, functional programming language designed for building scalable and maintainable applications. Created by José Valim in 2011, Elixir runs on the Erlang Virtual Machine (BEAM), known for creating low-latency, distributed, and fault-tolerant systems.

## Why Elixir?

### For DevOps Engineers

As a DevOps/Platform engineer, you'll find Elixir particularly valuable because:

1. **Concurrency Made Easy**: Handle thousands of concurrent operations without the complexity of threads or locks
2. **Built-in Fault Tolerance**: Systems that self-heal through supervision trees
3. **Distributed by Default**: Built-in support for clustering and distributed computing
4. **Excellent for Infrastructure Tools**: Perfect for building monitoring tools, schedulers, orchestrators
5. **Low Resource Footprint**: Efficient memory usage and predictable performance
6. **Hot Code Reloading**: Update code without stopping the system

### Real-World Use Cases in DevOps

- **Discord**: Handles millions of concurrent users with Elixir
- **Bleacher Report**: Real-time sports updates and notifications
- **Moz**: SEO tools and data processing pipelines
- **Pinterest**: Notification delivery system
- **Heroku**: Routing and log aggregation

## The BEAM Virtual Machine

The BEAM (Bogdan/Björn's Erlang Abstract Machine) is what makes Elixir special:

### Key Features

1. **Lightweight Processes**: Create millions of processes, each with its own garbage collector
2. **Preemptive Scheduling**: Fair distribution of CPU time across all processes
3. **Hot Code Swapping**: Replace code without stopping the system
4. **Built-in Distribution**: Connect multiple nodes into a cluster seamlessly
5. **Fault Isolation**: Process crashes don't affect other processes

### BEAM vs. Traditional VMs

| Feature | BEAM | JVM/Node.js |
|---------|------|-------------|
| Concurrency Model | Lightweight processes | Threads/Event Loop |
| Process Creation | ~1-2 microseconds | Milliseconds |
| Memory per Process | ~2KB | MBs |
| Fault Isolation | Per-process | Application-wide |
| Distribution | Built-in | Requires libraries |

## Functional Programming Primer

Elixir is a functional language. If you come from Python, Ruby, or Go, here are key differences:

### Immutability

In Elixir, data cannot be changed once created:

```elixir
# Python/Ruby mindset
list = [1, 2, 3]
list.append(4)  # Modifies the list

# Elixir mindset
list = [1, 2, 3]
new_list = [4 | list]  # Creates a new list, original unchanged
```

**Benefits for DevOps**:
- No race conditions from shared mutable state
- Easier to reason about concurrent systems
- Predictable behavior in distributed environments

### First-Class Functions

Functions are values that can be passed around:

```elixir
# Functions can be assigned to variables
double = fn x -> x * 2 end

# Functions can be passed to other functions
Enum.map([1, 2, 3], double)
# => [2, 4, 6]
```

### Pure Functions

Functions that always return the same output for the same input:

```elixir
# Pure function - predictable
def calculate_health_score(uptime_percent) do
  uptime_percent * 100
end

# Impure function - depends on external state
def get_current_status() do
  HTTPoison.get("http://service/status")  # Result varies
end
```

**DevOps Relevance**: Pure functions are easier to test and reason about.

## Your First Elixir Code

### Interactive Elixir (IEx)

Open your terminal and type `iex`:

```elixir
$ iex
Erlang/OTP 26 [erts-14.0] [64-bit] [smp:8:8]

Interactive Elixir (1.15.0) - press Ctrl+C to exit
iex(1)> "Hello, DevOps!" |> String.upcase()
"HELLO, DEVOPS!"

iex(2)> 1..10 |> Enum.filter(fn x -> rem(x, 2) == 0 end)
[2, 4, 6, 8, 10]
```

### Basic Operations

```elixir
# Arithmetic
iex> 10 + 5
15
iex> 20 / 4
5.0
iex> div(20, 4)  # Integer division
5

# String concatenation
iex> "Deploy" <> " " <> "to Production"
"Deploy to Production"

# Boolean operations
iex> true and false
false
iex> true or false
true
iex> not true
false

# Comparison
iex> 5 > 3
true
iex> 5 == 5.0  # Value equality
true
iex> 5 === 5.0  # Strict equality
false
```

### The Pipe Operator |>

One of Elixir's most loved features - it makes code read like a pipeline:

```elixir
# Without pipe
String.upcase(String.trim("  hello  "))

# With pipe - reads left to right
"  hello  "
|> String.trim()
|> String.upcase()
# => "HELLO"
```

**DevOps Example**: Processing log lines

```elixir
log_line
|> String.trim()
|> String.split(" ")
|> extract_timestamp()
|> parse_log_level()
|> filter_errors()
```

## Elixir vs. Other Languages

### Coming from Python

```python
# Python
def greet(name):
    return f"Hello, {name}!"

result = greet("DevOps")
```

```elixir
# Elixir
def greet(name) do
  "Hello, #{name}!"
end

result = greet("DevOps")
```

### Coming from Go

```go
// Go
func calculateUptime(checks int, failures int) float64 {
    return float64(checks - failures) / float64(checks) * 100
}
```

```elixir
# Elixir
def calculate_uptime(checks, failures) do
  (checks - failures) / checks * 100
end
```

## Setting Up Your Environment

### Installation

**macOS**:
```bash
brew install elixir
```

**Ubuntu/Debian**:
```bash
sudo apt-get update
sudo apt-get install elixir
```

**Using asdf (recommended for version management)**:
```bash
asdf plugin add elixir
asdf plugin add erlang
asdf install erlang 26.0
asdf install elixir 1.15.0
asdf global erlang 26.0
asdf global elixir 1.15.0
```

### Verify Installation

```bash
$ elixir --version
Erlang/OTP 26 [erts-14.0] [64-bit] [smp:8:8]

Elixir 1.15.0 (compiled with Erlang/OTP 26)

$ iex --version
Erlang/OTP 26 [erts-14.0] [64-bit] [smp:8:8]

IEx 1.15.0 (compiled with Erlang/OTP 26)
```

### Essential Tools

1. **iex**: Interactive Elixir shell
2. **mix**: Build tool and task runner (like make, npm, cargo)
3. **elixir**: Script runner
4. **elixirc**: Compiler

## Key Concepts to Remember

1. **Everything is Immutable**: Data cannot be changed, only transformed
2. **Pattern Matching**: The heart of Elixir (covered in next chapter)
3. **Processes**: Not OS processes - lightweight BEAM processes
4. **Message Passing**: Processes communicate by sending messages
5. **Fault Tolerance**: "Let it crash" philosophy with supervision

## DevOps Mindset Alignment

As a DevOps engineer, you already think in terms of:

| DevOps Concept | Elixir Equivalent |
|----------------|-------------------|
| Microservices | Processes |
| Service Mesh | Process links and monitors |
| Circuit Breakers | Supervisors |
| Horizontal Scaling | Distributed Erlang |
| Immutable Infrastructure | Immutable Data |
| Declarative Config | Pattern Matching |

## Exercises

Try these in `iex`:

1. Calculate how many seconds are in a day:
   ```elixir
   24 * 60 * 60
   ```

2. Use the pipe operator to transform a string:
   ```elixir
   "   deploy to kubernetes   "
   |> String.trim()
   |> String.upcase()
   |> String.replace(" ", "-")
   ```

3. Check if a number is even:
   ```elixir
   rem(42, 2) == 0
   ```

4. Create a range and convert it to a list:
   ```elixir
   1..5 |> Enum.to_list()
   ```

## What's Next?

Now that you understand what Elixir is and why it's valuable for DevOps, let's dive into:
- [Basic Syntax & Data Types](02-basic-syntax.md)

## Additional Resources

- [Elixir Official Getting Started Guide](https://elixir-lang.org/getting-started/introduction.html)
- [Elixir School - Basics](https://elixirschool.com/en/lessons/basics/basics)
- [Why We Use Elixir (Bleacher Report)](https://bleacherreport.com/articles/2866853)

