defmodule DevactionUISite.MixProject do
  use Mix.Project

  def project do
    [
      app: :devaction_ui_site,
      version: "0.1.0",
      elixir: "~> 1.17",
      elixirc_paths: ["lib"],
      start_permanent: Mix.env() == :prod,
      compilers: [:phoenix_live_view] ++ Mix.compilers(),
      listeners: [Phoenix.CodeReloader],
      aliases: aliases(),
      deps: deps(),
      releases: [devaction_ui_site: [include_executables_for: [:unix]]]
    ]
  end

  def application do
    [mod: {DevactionUISite.Application, []}, extra_applications: [:logger, :runtime_tools]]
  end

  defp deps do
    [
      {:devaction_ui, path: ".."},
      {:phoenix, "~> 1.8"},
      {:phoenix_live_view, "~> 1.2"},
      {:phoenix_html, "~> 4.1"},
      {:jason, "~> 1.2"},
      {:ecto_sql, "~> 3.13"},
      {:ecto_sqlite3, "~> 0.21"},
      {:bandit, "~> 1.13"},
      {:esbuild, "~> 0.10", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.5", runtime: Mix.env() == :dev},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:lazy_html, ">= 0.1.0", only: :test},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "assets.setup", "assets.build"],
      "assets.setup": [
        "cmd --cd ../assets npm ci",
        "tailwind.install --if-missing",
        "esbuild.install --if-missing"
      ],
      "assets.build": ["compile", "tailwind site", "esbuild site"],
      "assets.deploy": ["tailwind site --minify", "esbuild site --minify", "phx.digest"],
      "icons.build": [
        "cmd --cd assets node build-icons.mjs icons.json ../priv/static/images/hugeicons.svg"
      ]
    ]
  end
end
