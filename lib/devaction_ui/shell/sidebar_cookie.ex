defmodule DevactionUI.Shell.SidebarCookie do
  @moduledoc """
  Copies the `dui_sidebar` cookie, which the `DevactionUI.Shell` hook writes when the sidebar is collapsed or
  opened, into the session as `"sidebar_open"`, so the LiveViews render the sidebar in the state the person left
  it, with no flash on the first paint. Put it in the browser pipeline and read the value with
  `DevactionUI.Shell.on_mount/4`:

      pipeline :browser do
        plug DevactionUI.Shell.SidebarCookie
      end

      live_session :app, on_mount: [{DevactionUI.Shell, :sidebar}] do
        ...
      end
  """
  @behaviour Plug

  import Plug.Conn

  @cookie "dui_sidebar"

  @doc "Whether a cookie value leaves the sidebar open: only `\"rail\"` collapses it."
  @spec open?(String.t() | nil) :: boolean()
  def open?("rail"), do: false
  def open?(_value), do: true

  @impl Plug
  def init(options), do: options

  @impl Plug
  def call(conn, _options) do
    conn = fetch_cookies(conn)
    put_session(conn, "sidebar_open", open?(conn.cookies[@cookie]))
  end
end
