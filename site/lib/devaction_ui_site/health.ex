defmodule DevactionUISite.Health do
  @moduledoc "Answers `/up` with 200 before anything else, so a proxy can tell the release is alive."
  @behaviour Plug

  import Plug.Conn

  @impl true
  def init(options), do: options

  @impl true
  def call(%Plug.Conn{request_path: "/up"} = conn, _options),
    do: conn |> send_resp(200, "ok") |> halt()

  def call(conn, _options), do: conn
end
