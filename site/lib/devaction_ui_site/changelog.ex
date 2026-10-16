defmodule DevactionUISite.Changelog do
  @moduledoc """
  The changelog of the kit: the versions and what came with each, kept in SQLite. `sync!/0` writes what the code
  itself knows (every component of the `Catalog` as a `new` entry of v0.1 with the first sentence of its module
  documentation, and the `planned` entries of v0.2) and is safe to run on every boot: rows are keyed by
  version, group and name, and rows added later by hand (improved, fixed, breaking) are left alone.
  """
  import Ecto.Query

  alias DevactionUISite.{Catalog, Reference, Repo, Templates}
  alias DevactionUISite.Changelog.{Entry, Version}

  @kinds ~w(new improved fixed breaking planned)

  @planned [
    {"file_tree", "File tree of a pull request with +/− and the count of findings per file."},
    {"pdf_viewer", "Zoom, page thumbnails and marked signature fields."},
    {"otp_input", "A 6-digit code with automatic paste and a resend with a countdown."},
    {"x-ui.*",
     "Blade package for Laravel and Livewire, starting with color picker, slider and filter menu."}
  ]

  @doc "The kinds of change, in the order the page shows them."
  def kinds, do: @kinds

  @doc "The versions in the order of the page (the next one first), each with its entries in order."
  def versions do
    entries = from(entry in Entry, order_by: [asc: entry.position, asc: entry.id])

    Repo.all(
      from(version in Version,
        order_by: [asc: version.position, asc: version.id],
        preload: [entries: ^entries]
      )
    )
  end

  @doc "The version marked as the current one, with its entries, or `nil`."
  def current do
    entries = from(entry in Entry, order_by: [asc: entry.position, asc: entry.id])

    Repo.one(
      from(version in Version,
        where: version.status == "current",
        order_by: [asc: version.position],
        limit: 1,
        preload: [entries: ^entries]
      )
    )
  end

  @doc "How many entries there are of each kind, and in all, over a list of versions (for the filter pills)."
  def counts(versions) do
    entries = Enum.flat_map(versions, & &1.entries)
    by_kind = Enum.frequencies_by(entries, & &1.kind)

    Map.new(@kinds, &{&1, Map.get(by_kind, &1, 0)})
    |> Map.put("all", length(entries))
  end

  @doc "The entries of a version grouped by their group, in the order the groups first appear."
  def groups(%Version{entries: entries}) do
    entries
    |> Enum.map(& &1.group)
    |> Enum.uniq()
    |> Enum.map(fn group -> {group, Enum.filter(entries, &(&1.group == group))} end)
  end

  @doc "Up to four lines that sum up the current version, read off its `new` entries."
  def highlights(%Version{entries: entries}) do
    entries
    |> Enum.filter(&(&1.kind == "new"))
    |> Enum.group_by(& &1.group)
    |> Enum.sort_by(fn {_group, rows} -> -length(rows) end)
    |> Enum.take(4)
    |> Enum.sort_by(fn {_group, rows} -> hd(rows).position end)
    |> Enum.map(fn {group, rows} -> highlight(group, rows) end)
  end

  def highlights(nil), do: []

  defp highlight(group, [only]), do: "#{group}: #{humanize(only.name)}"

  defp highlight(group, rows) do
    first = hd(rows)
    last = List.last(rows)

    "#{length(rows)} #{String.downcase(group)} components, from #{humanize(first.name)} to #{humanize(last.name)}"
  end

  @doc "A slug written as a name: `command_palette` is `Command palette`."
  def humanize(name), do: name |> String.replace("_", " ") |> String.capitalize()

  @doc "Adds an entry at the end of a version. Returns `{:ok, entry}` or `{:error, reason}`."
  def add_entry(version, kind, group, name, summary) when kind in @kinds do
    case Repo.get_by(Version, version: version) do
      nil ->
        {:error, :unknown_version}

      %Version{id: id} ->
        Repo.insert(%Entry{
          version_id: id,
          kind: kind,
          group: group,
          name: name,
          summary: summary,
          position: next_position(id)
        })
    end
  end

  def add_entry(_version, _kind, _group, _name, _summary), do: {:error, :unknown_kind}

  defp next_position(version_id) do
    (Repo.one(
       from(entry in Entry, where: entry.version_id == ^version_id, select: max(entry.position))
     ) ||
       0) + 1
  end

  @doc "Writes the versions and the entries the code knows. Idempotent: run it on every boot."
  def sync! do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    versions = [
      %{
        version: "v0.2",
        status: "next",
        tag: nil,
        released_on: nil,
        summary:
          "Components that the DevAction IA screens already ask for: a file tree and a PDF viewer for reviews and contracts, and a one-time code input. Includes the start of the Blade version for Laravel and Livewire projects.",
        position: 1,
        inserted_at: now,
        updated_at: now
      },
      %{
        version: "v0.1",
        status: "current",
        tag: "v0.1.0",
        released_on: nil,
        summary:
          "First public release: #{length(Catalog.all())} function components for Phoenix LiveView, with light and dark tokens, keyboard navigation and state on the server.",
        position: 2,
        inserted_at: now,
        updated_at: now
      }
    ]

    Repo.insert_all(Version, versions,
      on_conflict: {:replace, [:status, :tag, :summary, :position, :updated_at]},
      conflict_target: [:version]
    )

    ids =
      Map.new(Repo.all(from(version in Version, select: {version.version, version.id})))

    Repo.insert_all(Entry, code_entries(ids, now),
      on_conflict: {:replace, [:kind, :summary, :position, :updated_at]},
      conflict_target: [:version_id, :group, :name]
    )

    :ok
  end

  defp code_entries(ids, now) do
    planned =
      for {{name, summary}, index} <- Enum.with_index(@planned, 1),
          do: row(ids["v0.2"], "planned", "Planned", name, summary, index, now)

    components =
      for {category, topics} <- Catalog.groups(), topic <- topics do
        {category, topic.slug, Reference.summary(topic.module)}
      end

    templates =
      for group <- Templates.groups(), do: {"Templates", group.slug, group.summary}

    released =
      (components ++ templates)
      |> Enum.with_index(1)
      |> Enum.map(fn {{group, name, summary}, index} ->
        row(ids["v0.1"], "new", group, name, summary, index, now)
      end)

    planned ++ released
  end

  defp row(version_id, kind, group, name, summary, position, now) do
    %{
      version_id: version_id,
      kind: kind,
      group: group,
      name: name,
      summary: summary,
      position: position,
      inserted_at: now,
      updated_at: now
    }
  end
end
