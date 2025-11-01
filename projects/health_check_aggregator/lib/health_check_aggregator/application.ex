defmodule HealthCheckAggregator.Application do
  @moduledoc """
  The Health Check Aggregator Application.

  Starts and supervises all components of the health checking system.
  """

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    Logger.info("Starting Health Check Aggregator...")

    children = [
      # Registry for naming health checker processes
      {Registry, keys: :unique, name: HealthCheckAggregator.Registry},

      # Metrics storage
      HealthCheckAggregator.MetricsStore,

      # Dynamic supervisor for health checkers
      {DynamicSupervisor,
        name: HealthCheckAggregator.CheckerSupervisor,
        strategy: :one_for_one},

      # HTTP server
      {Plug.Cowboy, scheme: :http, plug: HealthCheckAggregator.WebServer, options: [port: 4000]}
    ]

    opts = [strategy: :one_for_one, name: HealthCheckAggregator.Supervisor]

    case Supervisor.start_link(children, opts) do
      {:ok, pid} ->
        Logger.info("Health Check Aggregator started successfully on port 4000")
        start_default_services()
        {:ok, pid}
      {:error, reason} ->
        Logger.error("Failed to start application: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp start_default_services do
    # Add some default services from config if available
    services = Application.get_env(:health_check_aggregator, :services, [])

    Enum.each(services, fn {name, url, opts} ->
      HealthCheckAggregator.add_service(name, url, opts)
    end)
  end
end
