defmodule HealthCheckAggregator.MixProject do
  use Mix.Project

  def project do
    [
      app: :health_check_aggregator,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {HealthCheckAggregator.Application, []}
    ]
  end

  defp deps do
    [
      # HTTP client
      {:httpoison, "~> 2.0"},

      # JSON encoding/decoding
      {:jason, "~> 1.4"},

      # HTTP server
      {:plug_cowboy, "~> 2.6"},

      # Testing
      {:mock, "~> 0.3", only: :test}
    ]
  end
end
