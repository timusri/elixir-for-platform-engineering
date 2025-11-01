defmodule HealthCheckAggregator.MetricsStoreTest do
  use ExUnit.Case
  alias HealthCheckAggregator.MetricsStore

  setup do
    # Start a fresh MetricsStore for each test
    {:ok, pid} = MetricsStore.start_link([])
    %{store: pid}
  end

  describe "record_check/3" do
    test "records successful checks" do
      MetricsStore.record_check("service-1", :success, 100)
      metrics = MetricsStore.get_metrics()

      assert Map.has_key?(metrics.checks, "service-1")
      assert Map.has_key?(metrics.totals, "service-1")

      [check | _] = metrics.checks["service-1"]
      assert check.result == :success
      assert check.response_time == 100
    end

    test "records failed checks" do
      MetricsStore.record_check("service-1", :failure, nil)
      metrics = MetricsStore.get_metrics()

      [check | _] = metrics.checks["service-1"]
      assert check.result == :failure
      assert check.response_time == nil
    end

    test "tracks totals correctly" do
      MetricsStore.record_check("service-1", :success, 100)
      MetricsStore.record_check("service-1", :success, 150)
      MetricsStore.record_check("service-1", :failure, nil)

      metrics = MetricsStore.get_metrics()
      totals = metrics.totals["service-1"]

      assert totals.total == 3
      assert totals.failures == 1
    end

    test "keeps check history limited" do
      # Record 150 checks
      Enum.each(1..150, fn _ ->
        MetricsStore.record_check("service-1", :success, 100)
      end)

      metrics = MetricsStore.get_metrics()
      checks = metrics.checks["service-1"]

      # Should only keep last 100
      assert length(checks) == 100
    end
  end

  describe "get_service_metrics/1" do
    test "returns metrics for specific service" do
      MetricsStore.record_check("service-1", :success, 100)
      MetricsStore.record_check("service-2", :success, 200)

      service1_metrics = MetricsStore.get_service_metrics("service-1")

      assert length(service1_metrics.checks) == 1
      assert service1_metrics.totals.total == 1
    end

    test "returns empty for non-existent service" do
      metrics = MetricsStore.get_service_metrics("non-existent")

      assert metrics.checks == []
      assert metrics.totals == %{total: 0, failures: 0}
    end
  end
end
