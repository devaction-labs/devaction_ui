defmodule DevactionUISite.ChangelogTest do
  use ExUnit.Case, async: true

  alias DevactionUISite.{Catalog, Changelog, Repo}
  alias DevactionUISite.Changelog.Entry

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Changelog.sync!()
  end

  test "sync writes every component of the catalog as a new entry of the current version" do
    current = Changelog.current()
    names = for %{kind: "new"} = entry <- current.entries, do: entry.name

    assert current.version == "v0.1"
    assert current.tag == "v0.1.0"

    for topic <- Catalog.all() do
      assert topic.slug in names
    end

    assert "auth" in names
  end

  test "the summary of an entry is the first sentence of the moduledoc" do
    entry = Enum.find(Changelog.current().entries, &(&1.name == "tabs"))
    assert entry.summary == Catalog.summary(elem(Catalog.fetch("tabs"), 1))
    assert entry.summary != ""
  end

  test "only what is truly missing is planned for the next version" do
    [next, current] = Changelog.versions()

    assert next.version == "v0.2"
    assert current.version == "v0.1"
    assert Enum.map(next.entries, & &1.name) == ~w(file_tree pdf_viewer otp_input x-ui.*)
    assert Enum.all?(next.entries, &(&1.kind == "planned"))
  end

  test "sync is idempotent and leaves entries added by hand alone" do
    {:ok, %Entry{}} = Changelog.add_entry("v0.1", "fixed", "Form", "slider-step", "A fix.")
    before = Changelog.counts(Changelog.versions())

    Changelog.sync!()
    Changelog.sync!()

    assert Changelog.counts(Changelog.versions()) == before
    assert before["fixed"] == 1
  end

  test "counts sum every kind for the filter pills" do
    counts = Changelog.counts(Changelog.versions())

    assert counts["all"] == counts["new"] + counts["planned"]
    assert counts["new"] == length(Catalog.all()) + 1
    assert counts["planned"] == 4
    assert counts["improved"] == 0
    assert counts["breaking"] == 0
  end

  test "groups keep the order of the entries" do
    current = Changelog.current()

    assert Enum.map(Changelog.groups(current), &elem(&1, 0)) ==
             ~w(Base Overlay Form Navigation Data AI Templates)
  end

  test "highlights read the current version" do
    assert [_ | _] = highlights = Changelog.highlights(Changelog.current())
    assert length(highlights) <= 4
  end

  test "an entry for an unknown version or kind is refused" do
    assert {:error, :unknown_version} = Changelog.add_entry("v9", "new", "Base", "x", "s")
    assert {:error, :unknown_kind} = Changelog.add_entry("v0.1", "other", "Base", "x", "s")
  end
end
