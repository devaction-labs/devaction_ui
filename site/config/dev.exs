import Config

config :devaction_ui_site, DevactionUISite.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: String.to_integer(System.get_env("DEVACTION_UI_PORT", "4100"))],
  server: true,
  check_origin: false,
  code_reloader: true,
  reloadable_apps: [:devaction_ui, :devaction_ui_site],
  debug_errors: true,
  secret_key_base: "devaction-ui-site-dev-secret-key-base-devaction-ui-site-dev-0123456789abcdef",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:site, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:site, ~w(--watch)]}
  ],
  live_reload: [
    web_console_logger: true,
    dirs: ["lib", "priv/static", "../lib", "../assets/css"],
    patterns: [
      ~r"priv/static/(?!assets/).*\.(svg|woff2)$",
      ~r"priv/static/assets/.*\.(js|css)$",
      ~r"lib/.*\.(ex|heex)$",
      ~r"assets/css/.*\.css$"
    ]
  ]

config :devaction_ui_site, DevactionUISite.Repo,
  database: Path.expand("../priv/data/dev.db", __DIR__),
  pool_size: 5

config :phoenix, :stacktrace_depth, 20
config :phoenix, :plug_init_mode, :runtime
config :phoenix_live_view, debug_heex_annotations: true, debug_attributes: true
