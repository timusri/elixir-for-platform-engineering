defmodule HealthCheckAggregatorTest do
  use ExUnit.Case
  doctest HealthCheckAggregator

  setup do
    # Clean up any existing services
    services = HealthCheckAggregator.list_services()
    Enum.each(services, &HealthCheckAggregator.remove_service/1)
    :ok
  end

  describe "add_service/3" do
    test "adds a new service successfully" do
      assert {:ok, _msg} = HealthCheckAggregator.add_service("test-service", "http://localhost:9999/health")

      services = HealthCheckAggregator.list_services()
      assert "test-service" in services
    end

    test "returns error when adding duplicate service" do
      {:ok, _} = HealthCheckAggregator.add_service("test-service", "http://localhost:9999/health")

      assert {:error, :already_exists} =
               HealthCheckAggregator.add_service("test-service", "http://localhost:9999/health")
    end

    test "accepts custom options" do
      assert {:ok, _msg} =
               HealthCheckAggregator.add_service(
                 "test-service",
                 "http://localhost:9999/health",
                 interval: 60_000,
                 timeout: 10_000
               )

      {:ok, status} = HealthCheckAggregator.get_status("test-service")
      assert status.name == "test-service"
    end
  end

  describe "remove_service/1" do
    test "removes an existing service" do
      {:ok, _} = HealthCheckAggregator.add_service("test-service", "http://localhost:9999/health")

      assert :ok = HealthCheckAggregator.remove_service("test-service")

      services = HealthCheckAggregator.list_services()
      refute "test-service" in services
    end

    test "returns error when removing non-existent service" do
      assert {:error, :not_found} = HealthCheckAggregator.remove_service("non-existent")
    end
  end

  describe "get_status/1" do
    test "returns status for existing service" do
      {:ok, _} = HealthCheckAggregator.add_service("test-service", "http://localhost:9999/health")

      assert {:ok, status} = HealthCheckAggregator.get_status("test-service")
      assert status.name == "test-service"
      assert status.url == "http://localhost:9999/health"
      assert status.status in [:unknown, :degraded, :critical, :healthy]
    end

    test "returns error for non-existent service" do
      assert {:error, :not_found} = HealthCheckAggregator.get_status("non-existent")
    end
  end

  describe "get_all_statuses/0" do
    test "returns empty map when no services" do
      statuses = HealthCheckAggregator.get_all_statuses()
      assert statuses == %{}
    end

    test "returns all service statuses" do
      {:ok, _} = HealthCheckAggregator.add_service("service-1", "http://localhost:9999/health")
      {:ok, _} = HealthCheckAggregator.add_service("service-2", "http://localhost:9998/health")

      statuses = HealthCheckAggregator.get_all_statuses()
      assert map_size(statuses) == 2
      assert Map.has_key?(statuses, "service-1")
      assert Map.has_key?(statuses, "service-2")
    end
  end

  describe "list_services/0" do
    test "returns empty list when no services" do
      assert HealthCheckAggregator.list_services() == []
    end

    test "returns list of service names" do
      {:ok, _} = HealthCheckAggregator.add_service("service-1", "http://localhost:9999/health")
      {:ok, _} = HealthCheckAggregator.add_service("service-2", "http://localhost:9998/health")

      services = HealthCheckAggregator.list_services()
      assert length(services) == 2
      assert "service-1" in services
      assert "service-2" in services
    end
  end
end
