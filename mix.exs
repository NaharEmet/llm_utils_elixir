defmodule AnanthaJson.MixProject do
  use Mix.Project

  def project do
    [
      app: :anantha_json,
      version: "0.1.0",
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      description: "Shared JSON extraction and decoding utilities for Anantha applications.",
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:jason, "~> 1.2"},
      {:json_remedy, "~> 0.2"}
    ]
  end
end
