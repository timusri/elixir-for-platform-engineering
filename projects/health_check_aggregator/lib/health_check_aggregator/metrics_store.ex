defmodule HealthCheckAggregator.MetricsStore do
  @moduledoc """
  GenServer that stores and manages metrics for all health checks.

  Keeps track of check results, response times, and provides
  data for the Prometheus metrics endpoint.
  """

  use GenServer
  require Logger

  # Client API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def record_check(service_name, result, response_time) do
    GenServer.cast(__MODULE__, {:record_check, service_name, result, response_time})
  end

  def get_metrics do
    GenServer.call(__MODULE__, :get_metrics)
  end

  def get_service_metrics(service_name) do
    GenServer.call(__MODULE__, {:get_service_metrics, service_name})
  end

  # Server Callbacks

  @impl true
  def init(:ok) do
    state = %{
      checks: %{},  # service_name => [check_results]
      totals: %{}   # service_name => %{total:, failures:}
    }

    Logger.info("Metrics store started")
    {:ok, state}
  end

  @impl true
  def handle_cast({:record_check, service_name, result, response_time}, state) do
    timestamp = System.system_time(:second)

    check_data = %{
      result: result,
      response_time: response_time,
      timestamp: timestamp
    }

    # Update checks history (keep last 100)
    checks = Map.update(
      state.checks,
      service_name,
      [check_data],
      fn history -> [check_data | Enum.take(history, 99)] end
    )

    # Update totals
    totals = Map.update(
      state.totals,
      service_name,
      %{total: 1, failures: if(result == :failure, do: 1, else: 0)},
      fn existing ->
        %{
          total: existing.total + 1,
          failures: existing.failures + if(result == :failure, do: 1, else: 0)
        }
      end
    )

    {:noreply, %{state | checks: checks, totals: totals}}
  end

  @impl true
  def handle_call(:get_metrics, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:get_service_metrics, service_name}, _from, state) do
    service_metrics = %{
      checks: Map.get(state.checks, service_name, []),
      totals: Map.get(state.totals, service_name, %{total: 0, failures: 0})
    }

    {:reply, service_metrics, state}
  end
end
