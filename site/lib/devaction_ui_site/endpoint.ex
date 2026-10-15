defmodule DevactionUISite.Endpoint do
  @moduledoc "The server of the documentation (port 4100)."
  use Phoenix.Endpoint, otp_app: :devaction_ui_site

  plug DevactionUISite.Health
  plug DevactionUISite.Legacy

  @session_options [
    store: :cookie,
    key: "_devaction_ui_site",
    signing_salt: "devaction-ui-session",
    same_site: "Lax",
    secure: Application.compile_env(:devaction_ui_site, :secure_cookies, false),
    http_only: true
  ]

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: [connect_info: [session: @session_options]]

  plug Plug.Static,
    at: "/",
    from: :devaction_ui_site,
    gzip: Mix.env() == :prod,
    only: ~w(assets fonts images favicon.ico robots.txt)

  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug DevactionUISite.Router
end
