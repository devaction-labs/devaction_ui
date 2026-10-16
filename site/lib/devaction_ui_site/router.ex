defmodule DevactionUISite.Router do
  @moduledoc """
  The routes of the documentation, all one LiveView in one `live_session`, so moving between them is a
  patch and the state of the demos stays.
  """
  use Phoenix.Router, helpers: false

  import Phoenix.LiveView.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {DevactionUISite.Layouts, :root}
    plug :protect_from_forgery

    plug :put_secure_browser_headers, %{
      "content-security-policy" =>
        "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; " <>
          "font-src 'self' data:; connect-src 'self' ws: wss:; frame-ancestors 'self'"
    }
  end

  scope "/", DevactionUISite do
    pipe_through :browser

    live_session :docs do
      live "/", DocsLive, :home
      live "/docs", DocsLive, :overview
      live "/installation", DocsLive, :installation
      live "/tokens", DocsLive, :tokens
      live "/changelog", DocsLive, :changelog
      live "/c/:slug", DocsLive, :topic
      live "/preview/:slugs", DocsLive, :preview
      live "/templates/:group", DocsLive, :templates
    end

    live_session :screens do
      live "/screens/:group/:slug", ScreenLive, :show
    end
  end
end
