defmodule OpentelemetryGrpc.MixProject do
  use Mix.Project

  def project do
    [
      app: :opentelemetry_grpc,
      version: "0.1.0-dev",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:protobuf, "~> 0.10"},
      {:grpc, "~> 0.5"},
      {:opentelemetry, "~> 1.0", only: :test},
      {:opentelemetry_api, "~> 1.0"}
    ]
  end
end
