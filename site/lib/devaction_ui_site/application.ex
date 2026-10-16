defmodule DevactionUISite.Application do
  @moduledoc "Starts the documentation server: the SQLite repo (its migrations run at boot), the changelog sync, the PubSub LiveView needs and the endpoint."
  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        DevactionUISite.Repo,
        {Ecto.Migrator, repos: [DevactionUISite.Repo], skip: false}
      ] ++
        sync_children(Application.get_env(:devaction_ui_site, :sync_changelog, true)) ++
        [
          {Phoenix.PubSub, name: DevactionUISite.PubSub},
          DevactionUISite.Endpoint
        ]

    Supervisor.start_link(children, strategy: :one_for_one, name: DevactionUISite.Supervisor)
  end

  defp sync_children(true),
    do: [
      Supervisor.child_spec({Task, &DevactionUISite.Changelog.sync!/0},
        restart: :temporary,
        id: :changelog_sync
      )
    ]

  defp sync_children(_off), do: []
end
