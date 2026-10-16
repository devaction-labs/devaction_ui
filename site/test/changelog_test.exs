defmodule DevactionUISite.ChangelogTest do
  use ExUnit.Case, async: true

  alias DevactionUISite.{Catalog, Changelog, Repo}
  alias DevactionUISite.Changelog.Entry

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Changelog.sync!()
  end

  defp new_names(version), do: for(%{kind: "new"} = entry <- version.entries, do: entry.name)

  test "sync writes every component of the catalog as a new entry of the version it came with" do
    versions = Map.new(Changelog.versions(), &{&1.version, &1})
    current = Changelog.current()

    assert current.version == "v0.2"
    assert current.tag == "v0.2.0"

    for topic <- Catalog.all() do
      assert topic.slug in new_names(versions["v" <> Catalog.since(topic)])
    end

    assert "auth" in new_names(versions["v0.1"])
    assert "file_tree" in new_names(versions["v0.2"])
    refute "file_tree" in new_names(versions["v0.1"])
    refute "button" in new_names(versions["v0.2"])
  end

  test "the summary of an entry is the first sentence of the moduledoc" do
    v01 = Enum.find(Changelog.versions(), &(&1.version == "v0.1"))
    entry = Enum.find(v01.entries, &(&1.name == "tabs"))
    assert entry.summary == Catalog.summary(elem(Catalog.fetch("tabs"), 1))
    assert entry.summary != ""
  end

  test "the next version plans only what is truly missing, and v0.1 is archived" do
    [next, current, archived] = Changelog.versions()

    assert {next.version, next.status} == {"v0.3", "next"}
    assert {current.version, current.status} == {"v0.2", "current"}
    assert {archived.version, archived.status} == {"v0.1", "archived"}
    assert Enum.map(next.entries, & &1.name) == ["x-ui.*"]
    assert Enum.all?(next.entries, &(&1.kind == "planned"))
  end

  test "sync is idempotent and leaves entries added by hand alone" do
    {:ok, %Entry{}} = Changelog.add_entry("v0.2", "fixed", "Form", "slider-step", "A fix.")
    before = Changelog.counts(Changelog.versions())
    assert before["fixed"] == 2

    Changelog.sync!()
    Changelog.sync!()

    assert Changelog.counts(Changelog.versions()) == before
  end

  test "counts sum every kind for the filter pills" do
    counts = Changelog.counts(Changelog.versions())

    assert counts["all"] ==
             counts["new"] + counts["planned"] + counts["improved"] + counts["breaking"] +
               counts["fixed"]

    assert counts["new"] == length(Catalog.all()) + 1
    assert counts["planned"] == 1
    assert counts["improved"] > 0
    assert counts["breaking"] > 0
    assert counts["fixed"] > 0
  end

  test "groups keep the order of the entries" do
    assert Enum.map(Changelog.groups(Changelog.current()), &elem(&1, 0)) ==
             ["Base", "Overlay", "Form", "Data", "Improvements", "Breaking changes", "Fixes"]
  end

  test "highlights read the current version" do
    assert [_ | _] = highlights = Changelog.highlights(Changelog.current())
    assert length(highlights) <= 4
  end

  test "an entry for an unknown version or kind is refused" do
    assert {:error, :unknown_version} = Changelog.add_entry("v9", "new", "Base", "x", "s")
    assert {:error, :unknown_kind} = Changelog.add_entry("v0.2", "other", "Base", "x", "s")
  end
end
