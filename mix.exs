defmodule AnanthaLLMUtils.MixProject do
  use Mix.Project

  def project do
    [
      app: :llm_utils,
      version: "0.1.0",
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      description: "LLM utility functions for JSON extraction and response parsing",
      package: package(),
      source_url: "https://github.com/nahar/llm_utils",
      homepage_url: "https://github.com/nahar/llm_utils",
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

  defp package do
    [
      name: :llm_utils,
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/nahar/llm_utils"
      },
      files: ~w(lib mix.exs README.md .formatter.exs)
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.2"},
      {:json_remedy, "~> 0.2"},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end
end
