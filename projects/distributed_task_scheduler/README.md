# Distributed Task Scheduler

A cron-like distributed task scheduler with leader election and fault tolerance. Schedule and execute tasks across a cluster with automatic failover.

## 🎯 Learning Objectives

- Implement distributed coordination
- Master leader election patterns
- Build fault-tolerant schedulers
- Handle network partitions
- Manage distributed state
- Implement task migration

## 🏗️ Architecture

```
Node 1 (Leader)         Node 2 (Follower)       Node 3 (Follower)
    │                         │                       │
    ├─ Leader Election ───────┴───────────────────────┤
    │                                                  │
    ├─ Task Scheduler                                  │
    │   ├─ Cron Parser                                │
    │   ├─ Task Queue                                 │
    │   └─ Executor Pool                              │
    │                                                  │
    └─ State Sync ────────────────────────────────────┘
```

## 🚀 Features

- ✅ Cron-style task scheduling
- ✅ Distributed leader election
- ✅ Automatic failover
- ✅ Task migration on node failure
- ✅ Execution history and logs
- ✅ Task dependencies
- ✅ Retry with exponential backoff
- ✅ Distributed locks

## 📋 Core Concepts

### Leader Election

```elixir
defmodule LeaderElection do
  use GenServer

  def init(_) do
    case :global.register_name(__MODULE__, self()) do
      :yes ->
        IO.puts("I am the leader")
        start_scheduler()
        {:ok, %{role: :leader}}
      :no ->
        monitor_leader()
        {:ok, %{role: :follower}}
    end
  end

  def handle_info({:DOWN, _ref, :process, _pid, _reason}, state) do
    attempt_takeover()
    {:noreply, state}
  end
end
```

### Task Scheduling

```elixir
defmodule TaskScheduler do
  # Schedule task with cron expression
  def schedule(name, cron, mfa) do
    GenServer.call(__MODULE__, {:schedule, name, cron, mfa})
  end

  # Parse cron: "*/5 * * * *" -> every 5 minutes
  defp parse_cron(cron) do
    # Implementation
  end

  # Calculate next run time
  defp next_run_time(cron_parsed) do
    # Implementation
  end
end
```

### Distributed Locking

```elixir
defmodule DistributedLock do
  def acquire(resource, ttl \\ 5000) do
    case :global.set_lock({__MODULE__, resource}, [node() | Node.list()], 0) do
      true ->
        schedule_release(resource, ttl)
        {:ok, :acquired}
      false ->
        {:error, :locked}
    end
  end

  def release(resource) do
    :global.del_lock({__MODULE__, resource})
  end
end
```

## 🎓 Exercises

### Exercise 1: Cron Parser (Beginner)
Implement full cron expression parser supporting all fields.

### Exercise 2: Task History (Intermediate)
Store execution history with success/failure tracking.

### Exercise 3: Dependencies (Intermediate)
Implement task dependencies and execution ordering.

### Exercise 4: Split-Brain Handling (Advanced)
Handle network partitions and split-brain scenarios.

### Exercise 5: Multi-Datacenter (Expert)
Coordinate scheduling across multiple datacenters.

## 📊 Key Patterns

**Leader Election**: Single coordinator in cluster
**Distributed Locks**: Prevent duplicate execution
**Heartbeats**: Monitor node health
**State Replication**: Sync across nodes

## 🧪 Testing Strategy

- Unit tests for cron parsing
- Integration tests for leader election
- Chaos tests for network partitions
- Multi-node cluster tests

## 📈 Success Criteria

- [ ] Leader election works reliably
- [ ] Tasks execute on schedule
- [ ] Failover happens automatically
- [ ] No duplicate task execution
- [ ] Handles network partitions

## 🚀 Next Steps

After completing:
1. Build [Infrastructure Reconciler](../infrastructure_reconciler/)
2. Read [Distributed Erlang](https://erlang.org/doc/reference_manual/distributed.html)
3. Explore [libcluster](https://hexdocs.pm/libcluster/)

## 📚 Resources

- Distributed Systems Principles
- Leader Election Algorithms
- Cron Expression Syntax
- Network Partition Handling

