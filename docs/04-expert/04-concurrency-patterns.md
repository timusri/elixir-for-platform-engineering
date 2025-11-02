# Advanced Concurrency Patterns

## Overview

Beyond basic processes and GenServers, Elixir offers advanced patterns for complex concurrent systems. This chapter covers GenStage, Flow, Broadway, and custom patterns.

## GenStage

Producer-consumer pattern for backpressure handling.

### Installation

```elixir
{:gen_stage, "~> 1.2"}
```

### Basic Producer

```elixir
defmodule NumberProducer do
  use GenStage

  def start_link(max) do
    GenStage.start_link(__MODULE__, max, name: __MODULE__)
  end

  def init(max) do
    {:producer, %{counter: 0, max: max}}
  end

  def handle_demand(demand, state) when state.counter < state.max do
    events = Enum.to_list(state.counter..(state.counter + demand - 1))
    {:noreply, events, %{state | counter: state.counter + demand}}
  end

  def handle_demand(_demand, state) do
    {:noreply, [], state}
  end
end
```

### Consumer

```elixir
defmodule NumberConsumer do
  use GenStage

  def start_link do
    GenStage.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    {:consumer, :ok}
  end

  def handle_events(events, _from, state) do
    Enum.each(events, fn event ->
      IO.puts("Consumed: #{event}")
    end)

    {:noreply, [], state}
  end
end
```

### Starting Pipeline

```elixir
{:ok, producer} = NumberProducer.start_link(1000)
{:ok, consumer} = NumberConsumer.start_link()

GenStage.sync_subscribe(consumer, to: producer)
```

## Flow

Parallel data processing built on GenStage.

```elixir
alias Experimental.Flow

# Process large dataset in parallel
File.stream!("large_file.csv")
|> Flow.from_enumerable()
|> Flow.partition()
|> Flow.map(&parse_line/1)
|> Flow.filter(&valid?/1)
|> Flow.reduce(fn -> %{} end, fn item, acc ->
  Map.update(acc, item.category, 1, &(&1 + 1))
end)
|> Enum.to_list()
```

### Platform Engineering Example: Log Aggregation

```elixir
defmodule LogAggregator do
  alias Experimental.Flow

  def aggregate_logs(file_paths) do
    file_paths
    |> Flow.from_enumerable()
    |> Flow.flat_map(&File.stream!/1)
    |> Flow.partition()
    |> Flow.map(&parse_log/1)
    |> Flow.reject(&is_nil/1)
    |> Flow.partition(key: {:key, :level})
    |> Flow.group_by(& &1.level)
    |> Flow.map(fn {level, logs} ->
      {level, length(logs)}
    end)
    |> Enum.into(%{})
  end

  defp parse_log(line) do
    case String.split(line, " ", parts: 3) do
      [timestamp, level, message] ->
        %{
          timestamp: timestamp,
          level: String.trim(level, ":"),
          message: message
        }
      _ -> nil
    end
  end
end
```

## Broadway

Build concurrent, multi-stage data ingestion and processing pipelines.

```elixir
{:broadway, "~> 1.0"}

defmodule DataPipeline do
  use Broadway

  def start_link(_opts) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: {BroadwayRabbitMQ.Producer,
          queue: "my_queue",
          connection: [host: "localhost"]
        },
        concurrency: 1
      ],
      processors: [
        default: [concurrency: 10]
      ],
      batchers: [
        default: [
          concurrency: 5,
          batch_size: 100,
          batch_timeout: 1000
        ]
      ]
    )
  end

  def handle_message(_processor, message, _context) do
    # Process individual message
    data = Jason.decode!(message.data)
    processed = transform(data)
    
    Broadway.Message.update_data(message, fn _ -> processed end)
  end

  def handle_batch(_batcher, messages, _batch_info, _context) do
    # Process batch of messages
    data = Enum.map(messages, & &1.data)
    Database.insert_all(data)
    
    messages
  end
end
```

## Task.async_stream

Parallel processing with controlled concurrency:

```elixir
urls = ["url1", "url2", "url3", ... "url1000"]

results = urls
|> Task.async_stream(&fetch_url/1, 
    max_concurrency: 50,
    timeout: 10_000,
    on_timeout: :kill_task
  )
|> Enum.to_list()
```

## Custom Worker Pool

```elixir
defmodule WorkerPool do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    pool_size = Keyword.get(opts, :size, 10)

    children = for i <- 1..pool_size do
      Supervisor.child_spec({Worker, []}, id: {:worker, i})
    end

    Supervisor.init(children, strategy: :one_for_one)
  end

  def execute(fun) do
    worker = select_worker()
    Worker.execute(worker, fun)
  end

  defp select_worker do
    WorkerPool.Supervisor
    |> Supervisor.which_children()
    |> Enum.map(fn {_, pid, _, _} -> {pid, message_queue_len(pid)} end)
    |> Enum.min_by(fn {_, len} -> len end)
    |> elem(0)
  end

  defp message_queue_len(pid) do
    {:message_queue_len, len} = Process.info(pid, :message_queue_len)
    len
  end
end

defmodule Worker do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, [])
  end

  def execute(pid, fun) do
    GenServer.call(pid, {:execute, fun})
  end

  def init(_) do
    {:ok, %{}}
  end

  def handle_call({:execute, fun}, _from, state) do
    result = fun.()
    {:reply, result, state}
  end
end
```

## Rate Limiting with Token Bucket

```elixir
defmodule TokenBucket do
  use GenServer

  defstruct [:rate, :capacity, :tokens, :last_refill]

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def consume(tokens \\ 1) do
    GenServer.call(__MODULE__, {:consume, tokens})
  end

  def init(opts) do
    state = %__MODULE__{
      rate: opts[:rate] || 100,      # tokens per second
      capacity: opts[:capacity] || 100,
      tokens: opts[:capacity] || 100,
      last_refill: System.monotonic_time(:second)
    }

    {:ok, state}
  end

  def handle_call({:consume, requested}, _from, state) do
    state = refill_tokens(state)

    if state.tokens >= requested do
      {:reply, :ok, %{state | tokens: state.tokens - requested}}
    else
      {:reply, {:error, :rate_limit_exceeded}, state}
    end
  end

  defp refill_tokens(state) do
    now = System.monotonic_time(:second)
    elapsed = now - state.last_refill
    
    new_tokens = min(
      state.capacity,
      state.tokens + (elapsed * state.rate)
    )

    %{state | tokens: new_tokens, last_refill: now}
  end
end
```

## Poolboy Integration

For managing worker pools:

```elixir
{:poolboy, "~> 1.5"}

# config/config.exs
config :my_app, :worker_pool,
  size: 10,
  max_overflow: 5

# Application
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    pool_opts = [
      name: {:local, :worker_pool},
      worker_module: MyApp.Worker,
      size: 10,
      max_overflow: 5
    ]

    children = [
      :poolboy.child_spec(:worker_pool, pool_opts)
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end

# Usage
:poolboy.transaction(:worker_pool, fn pid ->
  MyApp.Worker.do_work(pid, args)
end)
```

## Key Takeaways

1. **GenStage**: Producer-consumer with backpressure
2. **Flow**: Parallel data processing
3. **Broadway**: Data ingestion pipelines
4. **Worker pools**: Manage concurrent workers
5. **Rate limiting**: Control throughput

## Additional Resources

- [GenStage Documentation](https://hexdocs.pm/gen_stage/)
- [Flow Documentation](https://hexdocs.pm/flow/)
- [Broadway Documentation](https://hexdocs.pm/broadway/)
- [Poolboy](https://github.com/devinus/poolboy)

