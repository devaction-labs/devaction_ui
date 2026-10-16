defmodule DevactionUISite.ChangelogSchemaTest do
  use ExUnit.Case, async: true

  alias DevactionUISite.Changelog.{Entry, Version}
  alias DevactionUISite.Repo

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  test "a version keeps its entries in the SQLite database" do
    version =
      Repo.insert!(%Version{version: "v9.9", status: "next", summary: "Test", position: 99})

    Repo.insert!(%Entry{
      version_id: version.id,
      kind: "planned",
      group: "Base",
      name: "thing",
      summary: "A thing.",
      position: 1
    })

    assert [%Entry{name: "thing", kind: "planned"}] = Repo.preload(version, :entries).entries
  end

  test "the same component cannot appear twice in a version and group" do
    version =
      Repo.insert!(%Version{version: "v9.8", status: "next", summary: "Test", position: 98})

    entry = %Entry{
      version_id: version.id,
      kind: "new",
      group: "Base",
      name: "x",
      summary: "s",
      position: 1
    }

    Repo.insert!(entry)

    assert_raise Ecto.ConstraintError, fn -> Repo.insert!(entry) end
  end

  test "the kinds and statuses are the ones the page filters by" do
    assert Entry.kinds() == ~w(new improved fixed breaking planned)
    assert Version.statuses() == ~w(current next archived)
  end
end
