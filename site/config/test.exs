import Config

config :devaction_ui_site, DevactionUISite.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4101],
  secret_key_base: "devaction-ui-site-test-secret-key-base-devaction-ui-site-test-0123456789abcd",
  server: false

config :logger, level: :warning
config :phoenix, :plug_init_mode, :runtime
