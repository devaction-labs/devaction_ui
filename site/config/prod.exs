import Config

config :devaction_ui_site, DevactionUISite.Endpoint,
  server: true,
  cache_static_manifest: "priv/static/cache_manifest.json"

config :devaction_ui_site, :secure_cookies, true

config :logger, level: :info
