# Distribution & Clustering

## Overview

Elixir inherits Erlang's powerful distributed computing capabilities. You can connect multiple nodes into a cluster and have them work together seamlessly.

## Why Distribution for DevOps?

- **High Availability**: Failover across nodes
- **Load Distribution**: Spread work across machines
- **Coordination**: Leader election, distributed locks
- **Scalability**: Add capacity by adding nodes

## Basic Node Operations

### Starting Named Nodes

```bash
# Start node with name
iex --sname node1

# Or with full name
iex --name node1@hostname.local

# Start with cookie for security
iex --sname node1 --cookie secret_cookie
```

### Connecting Nodes

```elixir
# Connect to another node
Node.connect(:"node2@hostname")

# List connected nodes
Node.list()

# Get current node name
Node.self()

# Ping a node
Node.ping(:"node2@hostname")
```

## Remote Process Communication

### Spawning on Remote Nodes

```elixir
# Spawn process on remote node
Node.spawn(:"node2@hostname", fn ->
  IO.puts("Running on #{Node.self()}")
end)

# Spawn and link
Node.spawn_link(:"node2@hostname", Module, :function, [args])
```

### Sending Messages Across Nodes

```elixir
# Send to PID on another node
send(remote_pid, {:message, "data"})

# Send to registered process
send({:process_name, :"node2@hostname"}, :message)
```

## DevOps Example: Distributed Health Checker

```elixir
defmodule DistributedHealthChecker do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: {:global, __MODULE__})
  end

  def check_service(url) do
    # Finds the process on any node
    GenServer.call({:global, __MODULE__}, {:check, url})
  end

  def init(_) do
    {:ok, %{checks: %{}}}
  end

  def handle_call({:check, url}, _from, state) do
    # Distribute work to least loaded node
    node = select_node()
    
    task = Task.Supervisor.async(
      {MyApp.TaskSupervisor, node},
      fn -> perform_check(url) end
    )
    
    result = Task.await(task)
    {:reply, result, state}
  end

  defp select_node do
    nodes = [Node.self() | Node.list()]
    
    loads = Enum.map(nodes, fn node ->
      {node, :rpc.call(node, :cpu_sup, :avg1, [])}
    end)
    
    loads
    |> Enum.min_by(fn {_, load} -> load end)
    |> elem(0)
  end
end
```

## Clustering with libcluster

libcluster provides automatic cluster formation.

### Installation

```elixir
# mix.exs
def deps do
  [
    {:libcluster, "~> 3.3"}
  ]
end
```

### Configuration

```elixir
# config/config.exs
config :libcluster,
  topologies: [
    k8s: [
      strategy: Cluster.Strategy.Kubernetes,
      config: [
        mode: :dns,
        kubernetes_node_basename: "myapp",
        kubernetes_selector: "app=myapp",
        polling_interval: 10_000
      ]
    ]
  ]
```

### Application Setup

```elixir
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    topologies = Application.get_env(:libcluster, :topologies, [])

    children = [
      {Cluster.Supervisor, [topologies, [name: MyApp.ClusterSupervisor]]},
      # Other children
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
```

## Global Registration

Register processes accessible from any node:

```elixir
# Register globally
:global.register_name(:my_process, self())

# Look up
pid = :global.whereis_name(:my_process)

# Unregister
:global.unregister_name(:my_process)
```

## Leader Election Pattern

```elixir
defmodule LeaderElection do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    # Try to become leader
    case :global.register_name(__MODULE__, self()) do
      :yes ->
        IO.puts("I am the leader on #{Node.self()}")
        {:ok, %{role: :leader}}
      :no ->
        IO.puts("I am a follower on #{Node.self()}")
        monitor_leader()
        {:ok, %{role: :follower}}
    end
  end

  def handle_info({:DOWN, _ref, :process, _pid, _reason}, state) do
    # Leader crashed, try to become leader
    case :global.register_name(__MODULE__, self()) do
      :yes ->
        IO.puts("Became leader on #{Node.self()}")
        {:noreply, %{state | role: :leader}}
      :no ->
        monitor_leader()
        {:noreply, state}
    end
  end

  defp monitor_leader do
    case :global.whereis_name(__MODULE__) do
      :undefined -> :ok
      pid -> Process.monitor(pid)
    end
  end
end
```

## Distributed Task Execution

```elixir
defmodule DistributedTaskRunner do
  def run_on_all_nodes(fun) do
    nodes = [Node.self() | Node.list()]
    
    tasks = Enum.map(nodes, fn node ->
      Task.Supervisor.async(
        {MyApp.TaskSupervisor, node},
        fun
      )
    end)
    
    Enum.map(tasks, &Task.await/1)
  end

  def map_reduce(items, map_fun, reduce_fun) do
    nodes = [Node.self() | Node.list()]
    chunk_size = div(length(items), length(nodes)) + 1
    
    items
    |> Enum.chunk_every(chunk_size)
    |> Enum.zip(Stream.cycle(nodes))
    |> Enum.map(fn {chunk, node} ->
      Task.Supervisor.async(
        {MyApp.TaskSupervisor, node},
        fn -> Enum.map(chunk, map_fun) end
      )
    end)
    |> Enum.map(&Task.await/1)
    |> List.flatten()
    |> reduce_fun.()
  end
end
```

## DevOps Example: Distributed Log Aggregator

```elixir
defmodule DistributedLogAggregator do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: {:global, __MODULE__})
  end

  def log(level, message, metadata \\ %{}) do
    GenServer.cast(
      {:global, __MODULE__},
      {:log, level, message, metadata, Node.self()}
    )
  end

  def get_logs(opts \\ []) do
    GenServer.call({:global, __MODULE__}, {:get_logs, opts})
  end

  def init(_) do
    {:ok, %{logs: []}}
  end

  def handle_cast({:log, level, message, metadata, node}, state) do
    log_entry = %{
      timestamp: DateTime.utc_now(),
      level: level,
      message: message,
      metadata: metadata,
      node: node
    }

    new_logs = [log_entry | Enum.take(state.logs, 999)]
    {:noreply, %{state | logs: new_logs}}
  end

  def handle_call({:get_logs, opts}, _from, state) do
    logs = state.logs
    |> maybe_filter_level(opts[:level])
    |> maybe_filter_node(opts[:node])
    |> Enum.take(opts[:limit] || 100)

    {:reply, logs, state}
  end

  defp maybe_filter_level(logs, nil), do: logs
  defp maybe_filter_level(logs, level) do
    Enum.filter(logs, &(&1.level == level))
  end

  defp maybe_filter_node(logs, nil), do: logs
  defp maybe_filter_node(logs, node) do
    Enum.filter(logs, &(&1.node == node))
  end
end
```

## Best Practices

1. **Use cookies for security**: Set consistent erlang cookies
2. **Handle network partitions**: Design for split-brain scenarios
3. **Monitor connections**: Track node up/down events
4. **Global vs Local**: Use global registration sparingly
5. **Test distribution**: Test with multiple nodes locally

## Network Partition Handling

```elixir
defmodule PartitionHandler do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    :net_kernel.monitor_nodes(true)
    {:ok, %{nodes: MapSet.new([Node.self()])}}
  end

  def handle_info({:nodeup, node}, state) do
    IO.puts("Node connected: #{node}")
    new_nodes = MapSet.put(state.nodes, node)
    {:noreply, %{state | nodes: new_nodes}}
  end

  def handle_info({:nodedown, node}, state) do
    IO.puts("Node disconnected: #{node}")
    new_nodes = MapSet.delete(state.nodes, node)
    
    # Handle partition recovery
    handle_partition(node)
    
    {:noreply, %{state | nodes: new_nodes}}
  end

  defp handle_partition(node) do
    # Implement partition recovery logic
    # - Reconcile state
    # - Re-elect leader if necessary
    # - Sync data
    :ok
  end
end
```

## Key Takeaways

1. **Easy distribution**: Connect nodes with Node.connect/1
2. **Remote execution**: Spawn and call across nodes
3. **libcluster**: Automatic cluster formation
4. **Global registry**: Process discovery across nodes
5. **Leader election**: Coordinate distributed work
6. **Handle partitions**: Design for network failures

## What's Next?

- [Metaprogramming & Macros](03-metaprogramming.md)
- [Performance Optimization](04-performance.md)

## Additional Resources

- [Distributed Erlang](https://erlang.org/doc/reference_manual/distributed.html)
- [libcluster Documentation](https://hexdocs.pm/libcluster/)
- [Designing for Scalability with Erlang/OTP](https://www.oreilly.com/library/view/designing-for-scalability/9781449361556/)

