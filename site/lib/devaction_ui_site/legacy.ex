defmodule DevactionUISite.Legacy do
  @moduledoc "Sends the address of the old catalog (`/dev/ui`, inside devaction_ia) to the introduction."
  @behaviour Plug

  import Plug.Conn

  @impl true
  def init(options), do: options

  @impl true
  def call(%Plug.Conn{request_path: "/dev/ui"} = conn, _options) do
    conn |> put_resp_header("location", "/") |> send_resp(301, "") |> halt()
  end

  def call(conn, _options), do: conn
end
