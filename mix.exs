defmodule AnanthaLLMUtils.MixProject do
  use Mix.Project

  def project do
    [
      app: :anantha_llm_utils,
      version: "0.1.0",
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      description: "LLM utility toolkit — JSON extraction, defensive decoding, response parsing, and more",
      package: package(),
      source_url: "https://github.com/naharengineer/anantha-os",
      homepage_url: "https://github.com/naharengineer/anantha-os",
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
      name: :anantha_llm_utils,
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/naharengineer/anantha-os"
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
