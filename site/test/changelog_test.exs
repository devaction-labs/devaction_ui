defmodule DevactionUISite.ChangelogTest do
  use ExUnit.Case, async: true

  alias DevactionUISite.{Catalog, Changelog, Repo}
  alias DevactionUISite.Changelog.Entry

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Changelog.sync!()
  end

  defp new_names(version), do: for(%{kind: "new"} = entry <- version.entries, do: entry.name)

  defp by_version, do: Map.new(Changelog.versions(), &{&1.version, &1})

  test "the current version is the newest release, and every patch has its own entry" do
    versions = Changelog.versions()

    assert Enum.map(versions, &{&1.version, &1.status}) == [
             {"v0.3", "next"},
             {"v0.2.4", "current"},
             {"v0.2.3", "archived"},
             {"v0.2.2", "archived"},
             {"v0.2.1", "archived"},
             {"v0.2.0", "archived"},
             {"v0.1.0", "archived"}
           ]

    assert Changelog.current().version == "v0.2.4"
    assert Changelog.current().tag == "v0.2.4"
  end

  test "sync writes every component of the catalog as a new entry of the release it came with" do
    versions = by_version()

    for topic <- Catalog.all() do
      assert topic.slug in new_names(versions["v#{Catalog.since(topic)}.0"])
    end

    assert "auth" in new_names(versions["v0.1.0"])
    assert "file_tree" in new_names(versions["v0.2.0"])
    refute "file_tree" in new_names(versions["v0.1.0"])
    refute "button" in new_names(versions["v0.2.0"])
  end

  test "the summary of an entry is the first sentence of the moduledoc" do
    entry = Enum.find(by_version()["v0.1.0"].entries, &(&1.name == "tabs"))
    assert entry.summary == Catalog.summary(elem(Catalog.fetch("tabs"), 1))
    assert entry.summary != ""
  end

  test "what each patch release fixed or broke is on its own version" do
    versions = by_version()

    assert [{"Fixes", _}, {"Improvements", _}] = Changelog.groups(versions["v0.2.4"])
    assert [{"Breaking changes", _}, {"Improvements", _}] = Changelog.groups(versions["v0.2.3"])
    assert Enum.map(versions["v0.2.2"].entries, &{&1.kind, &1.name}) == [{"fixed", "toast_group"}]
    assert Enum.map(versions["v0.2.1"].entries, &{&1.kind, &1.name}) == [{"fixed", "site_assets"}]
  end

  test "the next version plans only what is truly missing" do
    next = by_version()["v0.3"]

    assert Enum.map(next.entries, & &1.name) == ["x-ui.*"]
    assert Enum.all?(next.entries, &(&1.kind == "planned"))
  end

  test "the old two-part versions are removed when sync runs" do
    Repo.insert!(%DevactionUISite.Changelog.Version{
      version: "v0.2",
      status: "current",
      summary: "old",
      position: 99
    })

    Changelog.sync!()

    refute Map.has_key?(by_version(), "v0.2")
  end

  test "sync is idempotent and leaves entries added by hand alone" do
    {:ok, %Entry{}} = Changelog.add_entry("v0.2.4", "fixed", "Form", "slider-step", "A fix.")
    before = Changelog.counts(Changelog.versions())

    Changelog.sync!()
    Changelog.sync!()

    assert Changelog.counts(Changelog.versions()) == before
    assert before["fixed"] == 4
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
    assert counts["fixed"] >= 3
  end

  test "highlights read the latest release with new components" do
    assert Changelog.latest_release(Changelog.versions()).version == "v0.2.0"

    assert [_ | _] =
             highlights = Changelog.highlights(Changelog.latest_release(Changelog.versions()))

    assert length(highlights) <= 4
  end

  test "an entry for an unknown version or kind is refused" do
    assert {:error, :unknown_version} = Changelog.add_entry("v9", "new", "Base", "x", "s")
    assert {:error, :unknown_kind} = Changelog.add_entry("v0.2.4", "other", "Base", "x", "s")
  end
end
