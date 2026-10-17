defmodule DevactionUISite.ChangelogTest do
  use ExUnit.Case, async: true

  alias DevactionUISite.{Catalog, Changelog, Repo, Templates}
  alias DevactionUISite.Changelog.Entry

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Changelog.sync!()
  end

  defp new_names(version), do: for(%{kind: "new"} = entry <- version.entries, do: entry.name)

  defp release_of(topic), do: release_name(Catalog.since(topic))

  defp release_name("0.3"), do: "v0.3.0"
  defp release_name(since), do: "v#{since}.0"

  defp by_version, do: Map.new(Changelog.versions(), &{&1.version, &1})

  test "the current version is the newest release, and every patch has its own entry" do
    versions = Changelog.versions()

    assert Enum.map(versions, &{&1.version, &1.status}) == [
             {"v0.7", "next"},
             {"v0.6.0", "current"},
             {"v0.5.0", "archived"},
             {"v0.4.0", "archived"},
             {"v0.3.3", "archived"},
             {"v0.3.2", "archived"},
             {"v0.3.1", "archived"},
             {"v0.3.0", "archived"},
             {"v0.2.6", "archived"},
             {"v0.2.5", "archived"},
             {"v0.2.4", "archived"},
             {"v0.2.3", "archived"},
             {"v0.2.2", "archived"},
             {"v0.2.1", "archived"},
             {"v0.2.0", "archived"},
             {"v0.1.0", "archived"}
           ]

    assert Changelog.current().version == "v0.6.0"
    assert Changelog.current().tag == "v0.6.0"
  end

  test "sync writes every component of the catalog as a new entry of the release it came with" do
    versions = by_version()

    for topic <- Catalog.all() do
      assert topic.slug in new_names(versions[Catalog.release(topic)])
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
    next = by_version()["v0.7"]

    assert Enum.map(Enum.filter(next.entries, &(&1.kind == "planned")), & &1.name) == ["x-ui.*"]
  end

  test "v0.3.0 lists the new components and the improvements of the layout theme" do
    next = by_version()["v0.3.0"]
    new = for %{kind: "new", name: name} <- next.entries, do: name
    improved = for %{kind: "improved", name: name} <- next.entries, do: name

    assert Enum.sort(new) == ["app", "composer", "row_menu", "scroll_area", "shell"]

    assert Enum.sort(improved) == [
             "avatar",
             "breadcrumb",
             "data_table",
             "page_header",
             "shell",
             "tabs"
           ]

    assert Catalog.release(%{module: DevactionUI.Shell}) == "v0.3.0"
    assert Catalog.release(%{module: DevactionUI.Tabs}) == "v0.1.0"
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
    {:ok, %Entry{}} = Changelog.add_entry("v0.2.6", "fixed", "Form", "slider-step", "A fix.")
    before = Changelog.counts(Changelog.versions())

    Changelog.sync!()
    Changelog.sync!()

    assert Changelog.counts(Changelog.versions()) == before
    assert before["fixed"] == 10
  end

  test "counts sum every kind for the filter pills" do
    counts = Changelog.counts(Changelog.versions())

    assert counts["all"] ==
             counts["new"] + counts["planned"] + counts["improved"] + counts["breaking"] +
               counts["fixed"]

    assert counts["new"] == length(Catalog.all()) + length(Templates.groups())
    assert counts["planned"] == 1
    assert counts["improved"] > 0
    assert counts["breaking"] > 0
    assert counts["fixed"] >= 3
  end

  test "highlights read the latest release with new components" do
    assert Changelog.latest_release(Changelog.versions()).version == "v0.6.0"

    assert [_ | _] =
             highlights = Changelog.highlights(Changelog.latest_release(Changelog.versions()))

    assert length(highlights) <= 4
  end

  test "an entry for an unknown version or kind is refused" do
    assert {:error, :unknown_version} = Changelog.add_entry("v9", "new", "Base", "x", "s")
    assert {:error, :unknown_kind} = Changelog.add_entry("v0.2.6", "other", "Base", "x", "s")
  end
end
