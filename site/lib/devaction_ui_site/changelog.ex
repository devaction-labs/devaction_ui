defmodule DevactionUISite.Changelog do
  @moduledoc """
  The changelog of the kit: the versions and what came with each, kept in SQLite. `sync!/0` writes what the code
  itself knows (every component of the `Catalog` as a `new` entry of the version it came with, with the first
  sentence of its module documentation, the improvements and breaking changes of v0.2.0, what each patch release fixed, and the `planned`
  entries of v0.3) and is safe to run on every boot: rows are keyed by version, group and name, and rows added
  later by hand are left alone.
  """
  import Ecto.Query

  alias DevactionUISite.{Catalog, Reference, Repo, Templates}
  alias DevactionUISite.Changelog.{Entry, Version}

  @kinds ~w(new improved fixed breaking planned)

  @planned [
    {"x-ui.*",
     "Blade package for Laravel and Livewire, starting with color picker, slider and filter menu."}
  ]

  @improved_next [
    {"data_table",
     "`sticky={:start}` and `sticky={:end}` pin the first column and the actions while the table scrolls sideways, with a shadow only on the side that has content behind it. Variations that add up: `variant={:minimal}`, `striped`, `expanded` detail rows, `group_by`, a `tfoot` for totals, `stack` (cards under 640px), an `action` slot for the row menu with `sticky_actions`, `align` and `mono` on a column, and Shift+click range selection. `Pagination` draws the range of the page with `total`, `per_page`, `noun` and `summary_label`."},
    {"breadcrumb",
     "`home`, `home_label` and a `home_icon` slot put a link to the start of the app before the first item; `underline={false}` quiets the links of the trail in a shell header."},
    {"page_header",
     "`toolbar` and `toolbar_end` slots: a row under the tabs for the search, the filters and the count of results; `size={:md}` is the 28px title of a page inside an app shell."},
    {"shell",
     "`sidebar_search/1` for a search field under the head and `sidebar_user/1` for the account card at the foot; both collapse with the rail."},
    {"tabs",
     "An `icon` slot, `counts={:chip}` for the count in a small box, `size={:sm}` for the 14px line tab of an app, and a tab with no content gets an empty panel."},
    {"avatar",
     "`initials` overrides the letters and the `:ink` tone is the solid avatar of the signed-in person."}
  ]

  @improved [
    {"toast_group",
     "Rebuilt: toasts are pushed from the server with `put_toast/4`, `update_toast/3`, `dismiss_toast/2` and `clear_toasts/1`; the pile shows the front toast with two peeking behind and opens into a list on hover or focus."},
    {"data_table",
     "Takes a stream, with toolbar and footer slots, a density toggle, loading and error states and sort arrows through slots."},
    {"dropzone", "`queue/1`: a file queue with progress, errors, retry and cancel."},
    {"avatar",
     "`group/1`: overlapped avatars with status dots and a +N chip; `tone: :auto` picks a colour from the name."},
    {"editor",
     "`suggest/1`, a compact variant with the toolbar at the bottom, and TipTap loaded only when an editor mounts."},
    {"calendar", "The week view has an hours grid and the month and week take a legend."},
    {"date_picker",
     "A recurring due chip, and the range fields live in `date_range` and `date_input`."},
    {"timer", "`timer_mini/1` for the app bar and `time_log/1` for what was logged today."},
    {"kanban", "Cards move with touch and pen, and a move the server rejects is put back."},
    {"popover",
     "Left and right placements, edge clamping and a portal mode for scrolling containers."},
    {"modal", "Body scroll lock, an inert page behind and Esc for the top overlay only."},
    {"drawer", "A bottom sheet that closes by dragging, stacked with modals in a defined order."},
    {"tooltip", "Hoverable and dismissible with Esc, and it flips at the edges of the screen."},
    {"sidebar", "Search and user building blocks and collapsible groups."},
    {"code_block",
     "Copy button, line numbers, highlighted lines, diff lines and an Elixir lexer."},
    {"tone", "Indigo, emerald and chart tones, with strong text tokens."},
    {"spinner", "`dots/1`, a three-dot indicator."},
    {"tabs", "Vertical orientation, and the server can set the selected tab."},
    {"breadcrumb", "A collapsed middle for long paths and a separator as text or chevron."}
  ]

  @breaking [
    {"confirm_dialog",
     "Now a thin wrapper over `Modal`: `eyebrow` is gone and the close button is optional."},
    {"danger_dialog", "`type_label` is a slot, so the name to type can be a `<code>` chip."},
    {"modal", "Modal and drawer need the `DevactionUI.Overlay` hook: load the package hooks."},
    {"command_palette", "The scopes are a tablist of their own and no longer use `Segmented`."},
    {"chart",
     "A line chart's second series is no longer dashed by default: pass `dashed: true`."},
    {"tag", "The default size is 11px with `3px 8px`; the old size is `:lg`."},
    {"callout", "The icon sits inline by default; `icon_layout: :box` is the old tile."},
    {"avatar", "The sizes follow the canvas: `:md` is 40px, `:sm` 32px and `:xs` 22px."},
    {"money_input", "The value no longer carries `R$`: the prefix is an add-on."},
    {"switch", "The thumb is a real element instead of `::after`."},
    {"dropdown", "The `check_icon` slot is gone: the chosen item shows a leading ring."},
    {"panel", "`Panel.empty/1` is removed (use `EmptyState`) and `inner_class` has no default."},
    {"required_texts",
     "New required text attrs: `nav_label` (AuthLayout), `toolbar_label` (Editor), `hint_label` (Kanban), `meter_label` (PasswordStrength), and the labels of DataTable, Kanban and Editor no longer have English defaults."}
  ]

  @releases [
    %{
      version: "v0.4",
      status: "next",
      tag: nil,
      summary:
        "The Blade version of the kit for Laravel and Livewire projects, starting with the color picker, the slider and the filter menu."
    },
    %{
      version: "v0.3.1",
      status: "current",
      tag: "v0.3.1",
      summary:
        "Fixes the stylesheet of 0.3.0, which left a block open, and completes the layout theme: the App template, the new table, and a Composer with commands, mentions and a mode picker."
    },
    %{
      version: "v0.3.0",
      status: "archived",
      tag: "v0.3.0",
      summary:
        "The layout theme: a shell with a collapsing sidebar and six layouts, a scroll area, the composer and the row menu, with a pinned first column and actions in the data table."
    },
    %{
      version: "v0.2.6",
      status: "archived",
      tag: "v0.2.6",
      summary:
        "The site shows the full version in its chips, and the footer dedication is in English with a glow that passes between the letters."
    },
    %{
      version: "v0.2.5",
      status: "archived",
      tag: "v0.2.5",
      summary:
        "The install instructions use Hex (`{:devaction_ui, \"~> 0.2.0\"}`) now that the package is published; the package itself is unchanged since 0.2.3."
    },
    %{
      version: "v0.2.4",
      status: "archived",
      tag: "v0.2.4",
      summary:
        "The example cards of the documentation no longer clip a floating panel (combobox, dropdown, popover), and every release of the series is listed in this changelog."
    },
    %{
      version: "v0.2.3",
      status: "archived",
      tag: "v0.2.3",
      summary:
        "The toast group, rebuilt to the new design: toasts pushed from the server, a pile that opens on hover, loading that turns into done, Alt+T, Esc and a sideways drag."
    },
    %{
      version: "v0.2.2",
      status: "archived",
      tag: "v0.2.2",
      summary: "The toast pile opens and closes with a glide instead of jumping."
    },
    %{
      version: "v0.2.1",
      status: "archived",
      tag: "v0.2.1",
      summary: "The documentation site serves its scripts, styles and icons under digested names."
    },
    %{version: "v0.2.0", status: "archived", tag: "v0.2.0", summary: :v02},
    %{
      version: "v0.1.0",
      status: "archived",
      tag: "v0.1.0",
      summary:
        "First public release: function components for Phoenix LiveView, with light and dark tokens, keyboard navigation and state on the server."
    }
  ]

  @patches %{
    "v0.3.1" => [
      {"fixed", "Fixes", "stylesheet",
       "0.3.0 shipped a stylesheet with a block left open, which stops Tailwind in the host app; every block is closed now and a test counts the braces."},
      {"fixed", "Fixes", "example_cards",
       "An open drawer, modal or palette in an example card stays over the page rail."},
      {"improved", "Improvements", "composer",
       "Commands with `/` and mentions with `@` through `suggest_event` and a `suggestions` slot, `edit_last_event` for the up arrow, a mode picker chip and file chips with a kind and a detail."},
      {"improved", "Improvements", "shell",
       "`sidebar_search/1` and `sidebar_user/1`; `Tabs` takes an icon slot, chip counts and a small size."}
    ],
    "v0.2.6" => [
      {"improved", "Improvements", "site_version",
       "The header chips and the component history show the full version, and the footer dedication has a soft glow."}
    ],
    "v0.2.5" => [
      {"improved", "Improvements", "install",
       "The install instructions use the Hex requirement instead of the GitHub repository."}
    ],
    "v0.2.4" => [
      {"fixed", "Fixes", "example_cards",
       "A floating panel opened inside an example (combobox, dropdown, popover, date picker) is no longer cut off by the card."},
      {"improved", "Improvements", "changelog",
       "Every release of the series has its own entry here, with what it fixed or broke."}
    ],
    "v0.2.3" => [
      {"breaking", "Breaking changes", "toast_group",
       "Rebuilt to the new design: toasts are pushed from the server with `put_toast`, `update_toast`, `dismiss_toast` and `clear_toasts` instead of `:toast` slots, and `label` and `dismiss_label` are required."},
      {"improved", "Improvements", "toast_group",
       "The pile shows the newest toast with two peeking behind; pointing at it or focusing it opens a list; timers pause while it is open or the tab is hidden; Alt+T focuses it, Esc closes a toast and a sideways drag dismisses; `loading` stays until it is updated to done or failed."}
    ],
    "v0.2.2" => [
      {"fixed", "Fixes", "toast_group",
       "The pile opens and closes with a glide, and the group can be anchored with `fixed` (it no longer forces `relative`)."}
    ],
    "v0.2.1" => [
      {"fixed", "Fixes", "site_assets",
       "The documentation site serves its scripts, styles and icons under digested names, so a cache in front of it never hands a page an older script."}
    ]
  }

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

  @doc "The newest version that is not the next one and has new components in it, or `nil`."
  def latest_release(versions) do
    Enum.find(versions, fn version ->
      version.status != "next" and Enum.any?(version.entries, &(&1.kind == "new"))
    end)
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
    total = length(Catalog.all())
    added = Enum.count(Catalog.all(), &(Catalog.since(&1) == "0.2"))

    Repo.delete_all(from(version in Version, where: version.version in ["v0.1", "v0.2", "v0.3"]))

    versions =
      for {release, index} <- Enum.with_index(@releases, 1) do
        %{
          version: release.version,
          status: release.status,
          tag: release.tag,
          released_on: nil,
          summary: summary(release.summary, added, total),
          position: index,
          inserted_at: now,
          updated_at: now
        }
      end

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

  defp summary(:v02, added, total),
    do:
      "#{added} new components for reviews, contracts and the app (file tree, diff view, PDF viewer, one-time code, date range, notifications, plans, cookies, menus and panels), and a round of fixes to the canvas and to the accessibility of the v0.1 components. #{total} components in all."

  defp summary(text, _added, _total), do: text

  defp code_entries(ids, now) do
    planned =
      for {{name, summary}, index} <- Enum.with_index(@planned, 1),
          do: row(ids["v0.4"], "planned", "Planned", name, summary, index, now)

    components =
      for {category, topics} <- Catalog.groups(), topic <- topics do
        {Catalog.since(topic), category, topic.slug, Reference.summary(topic.module)}
      end

    templates =
      for group <- Templates.groups(), do: {group.since, "Templates", group.slug, group.summary}

    released =
      for {since, rows} <- Enum.group_by(components ++ templates, &elem(&1, 0)),
          {{_since, group, name, summary}, index} <- Enum.with_index(rows, 1),
          do: row(ids[release_key(since)], "new", group, name, summary, index, now)

    improved =
      for {{name, summary}, index} <- Enum.with_index(@improved, 1),
          do: row(ids["v0.2.0"], "improved", "Improvements", name, summary, 1000 + index, now)

    breaking =
      for {{name, summary}, index} <- Enum.with_index(@breaking, 1),
          do: row(ids["v0.2.0"], "breaking", "Breaking changes", name, summary, 2000 + index, now)

    patches =
      for {version, rows} <- @patches,
          {{kind, group, name, summary}, index} <- Enum.with_index(rows, 1),
          do: row(ids[version], kind, group, name, summary, 3000 + index, now)

    improved_next =
      for {{name, summary}, index} <- Enum.with_index(@improved_next, 1),
          do: row(ids["v0.3.0"], "improved", "Improvements", name, summary, 1000 + index, now)

    planned ++ released ++ improved_next ++ improved ++ breaking ++ patches
  end

  defp release_key("0.3"), do: "v0.3.0"
  defp release_key(since), do: "v#{since}.0"

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
