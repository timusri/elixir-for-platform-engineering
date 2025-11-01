defmodule HealthCheckAggregator.WebServer do
  @moduledoc """
  HTTP server for querying health check status and metrics.

  Provides endpoints for:
  - GET /health - Server health
  - GET /status - All service statuses
  - GET /status/:service - Specific service status
  - GET /metrics - Prometheus-formatted metrics
  """

  use Plug.Router
  require Logger

  plug(Plug.Logger)
  plug(:match)
  plug(Plug.Parsers, parsers: [:json], json_decoder: Jason)
  plug(:dispatch)

  get "/health" do
    send_json(conn, 200, %{status: "ok", timestamp: DateTime.utc_now()})
  end

  get "/status" do
    statuses = HealthCheckAggregator.get_all_statuses()
    send_json(conn, 200, %{services: statuses})
  end

  get "/status/:service" do
    case HealthCheckAggregator.get_status(service) do
      {:ok, status} ->
        send_json(conn, 200, status)

      {:error, :not_found} ->
        send_json(conn, 404, %{error: "Service not found", service: service})
    end
  end

  get "/metrics" do
    metrics = generate_prometheus_metrics()

    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, metrics)
  end

  get "/services" do
    services = HealthCheckAggregator.list_services()
    send_json(conn, 200, %{services: services, count: length(services)})
  end

  match _ do
    send_json(conn, 404, %{error: "Not found"})
  end

  # Private Functions

  defp send_json(conn, status, data) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(data))
  end

  defp generate_prometheus_metrics do
    statuses = HealthCheckAggregator.get_all_statuses()
    metrics_data = HealthCheckAggregator.MetricsStore.get_metrics()

    [
      "# HELP health_check_status Current health status (1 = healthy, 0 = unhealthy)",
      "# TYPE health_check_status gauge",
      generate_status_metrics(statuses),
      "",
      "# HELP health_check_response_time_ms Last response time in milliseconds",
      "# TYPE health_check_response_time_ms gauge",
      generate_response_time_metrics(statuses),
      "",
      "# HELP health_check_total_checks Total number of health checks performed",
      "# TYPE health_check_total_checks counter",
      generate_total_checks_metrics(metrics_data.totals),
      "",
      "# HELP health_check_failures_total Total number of failed health checks",
      "# TYPE health_check_failures_total counter",
      generate_failures_metrics(metrics_data.totals)
    ]
    |> List.flatten()
    |> Enum.join("\n")
  end

  defp generate_status_metrics(statuses) do
    Enum.map(statuses, fn {name, status} ->
      value = if status.status == :healthy, do: 1, else: 0
      ~s(health_check_status{service="#{name}"} #{value})
    end)
  end

  defp generate_response_time_metrics(statuses) do
    Enum.map(statuses, fn {name, status} ->
      case status.response_time_ms do
        nil -> ~s(health_check_response_time_ms{service="#{name}"} 0)
        time -> ~s(health_check_response_time_ms{service="#{name}"} #{time})
      end
    end)
  end

  defp generate_total_checks_metrics(totals) do
    Enum.map(totals, fn {name, data} ->
      ~s(health_check_total_checks{service="#{name}"} #{data.total})
    end)
  end

  defp generate_failures_metrics(totals) do
    Enum.map(totals, fn {name, data} ->
      ~s(health_check_failures_total{service="#{name}"} #{data.failures})
    end)
  end
end
