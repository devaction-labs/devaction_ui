defmodule DevactionUISite.Release do
  @moduledoc "Tasks a release runs by hand with `bin/devaction_ui_site eval`."

  alias DevactionUISite.{Changelog, Repo}

  @doc "Adds an entry to a version of the changelog; see `Mix.Tasks.Changelog.Add`."
  def add_entry(version, kind, group, name, summary) do
    Application.load(:devaction_ui_site)

    {:ok, result, _apps} =
      Ecto.Migrator.with_repo(Repo, fn _repo ->
        Changelog.add_entry(version, kind, group, name, summary)
      end)

    result
  end
end
