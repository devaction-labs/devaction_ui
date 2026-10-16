defmodule Mix.Tasks.Changelog.Add do
  @shortdoc "Adds an entry to a version of the changelog"
  @moduledoc """
  Adds one entry to the changelog:

      mix changelog.add VERSION KIND GROUP NAME "summary"

  `KIND` is one of new, improved, fixed, breaking or planned. In a release, the same thing is
  `bin/devaction_ui_site eval 'DevactionUISite.Release.add_entry("v0.2", "fixed", "Form", "slider", "Summary.")'`.
  """
  use Mix.Task

  alias DevactionUISite.Changelog

  @impl Mix.Task
  def run([version, kind, group, name, summary]) do
    Mix.Task.run("app.start")

    case Changelog.add_entry(version, kind, group, name, summary) do
      {:ok, entry} ->
        Mix.shell().info("Added #{entry.kind} #{entry.group}/#{entry.name} to #{version}.")

      {:error, reason} ->
        Mix.raise("Could not add the entry: #{reason}")
    end
  end

  def run(_args),
    do: Mix.raise(~s|usage: mix changelog.add VERSION KIND GROUP NAME "summary"|)
end
