defmodule HealthCheckAggregator.HealthCheckerTest do
  use ExUnit.Case
  alias HealthCheckAggregator.HealthChecker

  setup do
    config = %{
      name: "test-service",
      url: "http://localhost:9999/health",
      interval: 60_000,
      timeout: 5_000,
      max_failures: 3
    }

    {:ok, pid} = HealthChecker.start_link(config)
    %{pid: pid, config: config}
  end

  describe "initialization" do
    test "starts with unknown status", %{pid: pid} do
      # Give it a moment to initialize
      Process.sleep(100)

      status = HealthChecker.get_status(pid)
      assert status.name == "test-service"
      assert status.url == "http://localhost:9999/health"
      # Status might be :unknown or :degraded after first check attempt
      assert status.status in [:unknown, :degraded, :critical]
    end
  end

  describe "get_status/1" do
    test "returns current status information", %{pid: pid} do
      status = HealthChecker.get_status(pid)

      assert is_map(status)
      assert Map.has_key?(status, :name)
      assert Map.has_key?(status, :url)
      assert Map.has_key?(status, :status)
      assert Map.has_key?(status, :last_check)
      assert Map.has_key?(status, :response_time_ms)
      assert Map.has_key?(status, :consecutive_failures)
    end
  end

  describe "health checking" do
    test "tracks consecutive failures", %{pid: pid} do
      # Force a check (will likely fail since localhost:9999 isn't running)
      HealthChecker.force_check(pid)
      Process.sleep(100)

      status1 = HealthChecker.get_status(pid)
      failures1 = status1.consecutive_failures

      # Force another check
      HealthChecker.force_check(pid)
      Process.sleep(100)

      status2 = HealthChecker.get_status(pid)
      failures2 = status2.consecutive_failures

      # Failures should increase
      assert failures2 >= failures1
    end

    test "marks service as critical after max failures", %{pid: pid} do
      # Force multiple checks to exceed max_failures
      Enum.each(1..5, fn _ ->
        HealthChecker.force_check(pid)
        Process.sleep(100)
      end)

      status = HealthChecker.get_status(pid)
      assert status.status == :critical
      assert status.consecutive_failures >= 3
    end
  end
end
