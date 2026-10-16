defmodule DevactionUISite.Application do
  @moduledoc "Starts the documentation server: the SQLite repo (its migrations run at boot), the PubSub LiveView needs and the endpoint."
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      DevactionUISite.Repo,
      {Ecto.Migrator, repos: [DevactionUISite.Repo], skip: false},
      {Phoenix.PubSub, name: DevactionUISite.PubSub},
      DevactionUISite.Endpoint
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: DevactionUISite.Supervisor)
  end
end
