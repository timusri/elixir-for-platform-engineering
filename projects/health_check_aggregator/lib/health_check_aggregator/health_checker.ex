defmodule HealthCheckAggregator.HealthChecker do
  @moduledoc """
  GenServer that performs periodic health checks on a service.

  Each HealthChecker process monitors a single service and reports
  status updates to the MetricsStore.
  """

  use GenServer
  require Logger

  defstruct [
    :name,
    :url,
    :interval,
    :timeout,
    :max_failures,
    :status,
    :last_check,
    :response_time_ms,
    :consecutive_failures
  ]

  # Client API

  def start_link(config) do
    GenServer.start_link(__MODULE__, config, name: via_tuple(config.name))
  end

  def get_status(pid) do
    GenServer.call(pid, :get_status)
  end

  def force_check(pid) do
    send(pid, :perform_check)
    :ok
  end

  # Server Callbacks

  @impl true
  def init(config) do
    # Schedule first check immediately
    send(self(), :perform_check)

    state = %__MODULE__{
      name: config.name,
      url: config.url,
      interval: config.interval,
      timeout: config.timeout,
      max_failures: config.max_failures,
      status: :unknown,
      last_check: nil,
      response_time_ms: nil,
      consecutive_failures: 0
    }

    Logger.info("Health checker started for #{state.name}")
    {:ok, state}
  end

  @impl true
  def handle_call(:get_status, _from, state) do
    status_map = %{
      name: state.name,
      url: state.url,
      status: state.status,
      last_check: state.last_check,
      response_time_ms: state.response_time_ms,
      consecutive_failures: state.consecutive_failures
    }

    {:reply, status_map, state}
  end

  @impl true
  def handle_info(:perform_check, state) do
    {new_state, _result} = perform_health_check(state)
    schedule_next_check(new_state.interval)
    {:noreply, new_state}
  end

  # Private Functions

  defp perform_health_check(state) do
    start_time = System.monotonic_time(:millisecond)

    case HTTPoison.get(state.url, [], timeout: state.timeout, recv_timeout: state.timeout) do
      {:ok, %HTTPoison.Response{status_code: 200}} ->
        response_time = System.monotonic_time(:millisecond) - start_time
        handle_success(state, response_time)

      {:ok, %HTTPoison.Response{status_code: code}} ->
        Logger.warn("#{state.name} returned non-200 status: #{code}")
        handle_failure(state, {:bad_status, code})

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.warn("#{state.name} check failed: #{inspect(reason)}")
        handle_failure(state, reason)
    end
  end

  defp handle_success(state, response_time) do
    new_state = %{state |
      status: :healthy,
      last_check: DateTime.utc_now(),
      response_time_ms: response_time,
      consecutive_failures: 0
    }

    # Report to metrics store
    HealthCheckAggregator.MetricsStore.record_check(
      new_state.name,
      :success,
      response_time
    )

    Logger.debug("#{state.name} is healthy (#{response_time}ms)")
    {new_state, :success}
  end

  defp handle_failure(state, reason) do
    new_failures = state.consecutive_failures + 1

    status = if new_failures >= state.max_failures do
      Logger.error("#{state.name} is CRITICAL (#{new_failures} consecutive failures)")
      :critical
    else
      Logger.warn("#{state.name} is degraded (#{new_failures}/#{state.max_failures} failures)")
      :degraded
    end

    new_state = %{state |
      status: status,
      last_check: DateTime.utc_now(),
      response_time_ms: nil,
      consecutive_failures: new_failures
    }

    # Report to metrics store
    HealthCheckAggregator.MetricsStore.record_check(
      new_state.name,
      :failure,
      nil
    )

    {new_state, {:error, reason}}
  end

  defp schedule_next_check(interval) do
    Process.send_after(self(), :perform_check, interval)
  end

  defp via_tuple(name) do
    {:via, Registry, {HealthCheckAggregator.Registry, name}}
  end
end
