defmodule DevactionUI.MixProject do
  use Mix.Project

  @version "0.7.1"
  @source_url "https://github.com/devaction-labs/devaction_ui"

  def project do
    [
      app: :devaction_ui,
      version: @version,
      elixir: "~> 1.20",
      compilers: [:phoenix_live_view] ++ Mix.compilers(),
      deps: deps(),
      aliases: aliases(),
      description:
        "Phoenix function components and LiveView hooks, themed with light-dark() tokens.",
      package: package(),
      docs: docs(),
      source_url: @source_url
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:phoenix, "~> 1.8"},
      {:phoenix_live_view, "~> 1.2"},
      {:phoenix_html, "~> 4.1"},
      {:jason, "~> 1.2"},
      {:lazy_html, ">= 0.1.0", only: :test},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp aliases do
    [
      "assets.setup": ["cmd --cd assets npm ci"],
      "js.test": ["cmd --cd assets npm test"],
      precommit: ["compile --warnings-as-errors", "format", "test", "js.test"]
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files:
        ~w(lib assets/css assets/js assets/package.json README.md CHANGELOG.md LICENSE mix.exs),
      exclude_patterns: [~r/\.test\.js$/]
    ]
  end

  defp docs do
    [main: "readme", extras: ["README.md", "CHANGELOG.md"], source_ref: "v#{@version}"]
  end
end
