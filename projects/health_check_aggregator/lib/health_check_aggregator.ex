defmodule HealthCheckAggregator do
  @moduledoc """
  Public API for the Health Check Aggregator.

  Use this module to manage health checks and query service status.

  ## Examples

      # Add a service to monitor
      HealthCheckAggregator.add_service("my-api", "http://localhost:8080/health")

      # Get status of all services
      HealthCheckAggregator.get_all_statuses()

      # Get status of specific service
      HealthCheckAggregator.get_status("my-api")

      # Remove a service
      HealthCheckAggregator.remove_service("my-api")
  """

  alias HealthCheckAggregator.HealthChecker

  @doc """
  Adds a new service to monitor.

  ## Options

    * `:interval` - Check interval in milliseconds (default: 30_000)
    * `:timeout` - HTTP timeout in milliseconds (default: 5_000)
    * `:max_failures` - Max consecutive failures before marking critical (default: 3)

  ## Examples

      iex> HealthCheckAggregator.add_service("api", "http://localhost:8080/health")
      {:ok, "Service added"}

      iex> HealthCheckAggregator.add_service("api", "http://localhost:8080/health", interval: 60_000)
      {:ok, "Service added"}
  """
  @spec add_service(String.t(), String.t(), keyword()) :: {:ok, String.t()} | {:error, term()}
  def add_service(name, url, opts \\ []) do
    service_config = %{
      name: name,
      url: url,
      interval: Keyword.get(opts, :interval, 30_000),
      timeout: Keyword.get(opts, :timeout, 5_000),
      max_failures: Keyword.get(opts, :max_failures, 3)
    }

    child_spec = {HealthChecker, service_config}

    case DynamicSupervisor.start_child(HealthCheckAggregator.CheckerSupervisor, child_spec) do
      {:ok, _pid} ->
        {:ok, "Service '#{name}' added successfully"}
      {:error, {:already_started, _pid}} ->
        {:error, :already_exists}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Removes a service from monitoring.

  ## Examples

      iex> HealthCheckAggregator.remove_service("api")
      :ok
  """
  @spec remove_service(String.t()) :: :ok | {:error, :not_found}
  def remove_service(name) do
    case Registry.lookup(HealthCheckAggregator.Registry, name) do
      [{pid, _}] ->
        DynamicSupervisor.terminate_child(HealthCheckAggregator.CheckerSupervisor, pid)
        :ok
      [] ->
        {:error, :not_found}
    end
  end

  @doc """
  Gets the status of a specific service.

  Returns a map with status information or {:error, :not_found}.
  """
  @spec get_status(String.t()) :: {:ok, map()} | {:error, :not_found}
  def get_status(name) do
    case Registry.lookup(HealthCheckAggregator.Registry, name) do
      [{pid, _}] ->
        status = HealthChecker.get_status(pid)
        {:ok, status}
      [] ->
        {:error, :not_found}
    end
  end

  @doc """
  Gets the status of all monitored services.

  Returns a map with service names as keys and status maps as values.
  """
  @spec get_all_statuses() :: map()
  def get_all_statuses do
    HealthCheckAggregator.CheckerSupervisor
    |> DynamicSupervisor.which_children()
    |> Enum.map(fn {_, pid, _, _} ->
      status = HealthChecker.get_status(pid)
      {status.name, status}
    end)
    |> Map.new()
  end

  @doc """
  Lists all monitored services.
  """
  @spec list_services() :: [String.t()]
  def list_services do
    HealthCheckAggregator.CheckerSupervisor
    |> DynamicSupervisor.which_children()
    |> Enum.map(fn {_, pid, _, _} ->
      HealthChecker.get_status(pid).name
    end)
  end
end
