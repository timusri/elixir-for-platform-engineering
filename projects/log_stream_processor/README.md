# Log Stream Processor

A production-ready real-time log processing pipeline built with GenStage and Flow. Process logs from multiple sources, apply transformations, and route to various destinations.

## 🎯 Learning Objectives

- Master GenStage producer-consumer patterns
- Build backpressure-aware pipelines
- Use Flow for parallel processing
- Implement log parsing with pattern matching
- Create flexible output adapters
- Handle streaming data efficiently

## 🏗️ Architecture

```
Log Sources → Producers → Processors → Batchers → Consumers/Outputs
    │              │           │            │            │
  Files         GenStage    Transform    Aggregate   Database
  Syslog        Demand      Parse        Window      Elasticsearch
  HTTP          Buffer      Filter       Batch       S3
  Kafka                     Enrich                   Stdout
```

## 🚀 Features

- ✅ Multiple input sources (file, HTTP, syslog)
- ✅ Real-time log parsing and transformation
- ✅ Pattern-based filtering and routing
- ✅ Time-window aggregations
- ✅ Backpressure handling
- ✅ Multiple output destinations
- ✅ Metrics and monitoring
- ✅ Error handling and dead letter queue

## 📋 Core Concepts

### GenStage Pipeline

```elixir
# Producer: Reads logs
defmodule LogProducer do
  use GenStage
  
  def handle_demand(demand, state) do
    logs = fetch_logs(demand)
    {:noreply, logs, state}
  end
end

# Processor: Transforms logs
defmodule LogProcessor do
  use GenStage
  
  def handle_events(logs, _from, state) do
    processed = Enum.map(logs, &parse_and_transform/1)
    {:noreply, processed, state}
  end
end

# Consumer: Outputs logs
defmodule LogConsumer do
  use GenStage
  
  def handle_events(logs, _from, state) do
    send_to_destination(logs)
    {:noreply, [], state}
  end
end
```

### Flow-Based Processing

```elixir
File.stream!("app.log")
|> Flow.from_enumerable()
|> Flow.partition()
|> Flow.map(&parse_log/1)
|> Flow.filter(&is_error?/1)
|> Flow.partition(window: Flow.Window.fixed(1, :second))
|> Flow.reduce(fn -> %{} end, &count_by_service/2)
|> Enum.to_list()
```

## 🎓 Exercises

### Exercise 1: Custom Log Parser (Beginner)
Implement parsers for different log formats (Apache, JSON, syslog).

### Exercise 2: Filtering Rules (Intermediate)
Add configurable filtering rules (by level, service, pattern).

### Exercise 3: Aggregation Windows (Intermediate)
Implement sliding window aggregations for metrics.

### Exercise 4: Multiple Outputs (Advanced)
Route logs to different destinations based on criteria.

### Exercise 5: Distributed Processing (Expert)
Scale across multiple nodes with work distribution.

## 📊 Key Patterns

**Backpressure**: Consumers control the rate of processing
**Buffering**: Handle bursts without losing data
**Partitioning**: Process logs in parallel
**Windowing**: Time-based aggregations

## 🧪 Testing Strategy

- Unit tests for parsers
- Integration tests for pipelines
- Property-based tests for transformations
- Load tests for throughput

## 📈 Success Criteria

- [ ] Process 10,000+ logs/second
- [ ] Handle backpressure gracefully
- [ ] Parse multiple log formats
- [ ] Route to 3+ destinations
- [ ] Maintain ordering within partitions

## 🚀 Next Steps

After completing:
1. Build [Distributed Task Scheduler](../distributed_task_scheduler/)
2. Read [GenStage Documentation](https://hexdocs.pm/gen_stage/)
3. Explore [Flow Patterns](https://hexdocs.pm/flow/)

## 📚 Resources

- GenStage Guide
- Flow Documentation
- Backpressure Patterns
- Stream Processing Best Practices

