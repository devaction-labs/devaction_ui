import Config

config :phoenix, :json_library, Jason

config :devaction_ui_site, ecto_repos: [DevactionUISite.Repo]

config :devaction_ui_site, DevactionUISite.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [formats: [html: DevactionUISite.ErrorHTML], layout: false],
  pubsub_server: DevactionUISite.PubSub,
  live_view: [signing_salt: "devaction-ui-site"]

config :esbuild,
  version: "0.25.4",
  site: [
    args:
      ~w(js/app.js js/theme.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{
      "NODE_PATH" =>
        Enum.join(
          [Path.expand("../deps", __DIR__), Path.expand("../../assets/node_modules", __DIR__)],
          ":"
        )
    }
  ]

config :tailwind,
  version: "4.3.0",
  site: [
    args: ~w(--input=assets/css/site.css --output=priv/static/assets/css/site.css),
    cd: Path.expand("..", __DIR__)
  ]

config :logger, :default_formatter, format: "$time $metadata[$level] $message\n"

import_config "#{config_env()}.exs"
