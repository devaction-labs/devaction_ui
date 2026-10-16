defmodule DevactionUISite.ChangelogHTML do
  @moduledoc """
  The changelog page: the filter by kind of change, the versions on the left and the timeline of releases, each
  with one collapsible table per group. Everything is read through `DevactionUISite.Changelog`; the filter runs in
  the browser (`SiteChangelog`) over the rows' `data-kind`. It renders the body only; the header comes from the shell.
  """
  use Phoenix.Component

  import DevactionUISite.Icon

  alias DevactionUI.Tag
  alias DevactionUISite.{Catalog, Changelog, Templates}

  @filters [
    {"all", "All"},
    {"new", "New"},
    {"improved", "Improved"},
    {"fixed", "Fixed"},
    {"breaking", "Breaking"},
    {"planned", "Planned"}
  ]

  @legend [
    {"new", "A component that entered the kit."},
    {"improved", "Better behavior or looks, with no change to the API."},
    {"fixed", "A bug fixed, with a link to the issue."},
    {"breaking", "The API changed. Comes with the migration step."}
  ]

  def page(assigns) do
    versions = assigns[:changelog_versions] || Changelog.versions()

    assigns =
      assign(assigns,
        versions: Enum.map(versions, &Map.put(&1, :groups, Changelog.groups(&1))),
        counts: Changelog.counts(versions),
        filters: @filters,
        legend: @legend
      )

    ~H"""
    <div
      id="changelog"
      phx-hook="SiteChangelog"
      class="relative isolate overflow-hidden bg-wrap text-[15px] leading-[normal] text-ink"
    >
      <div class="site-grid cl-grid" aria-hidden="true"></div>
      <div class="cl-glow" aria-hidden="true"></div>

      <main class="relative">
        <header class="mx-auto max-w-[1200px] px-5 pt-14 sm:px-10 sm:pt-[72px]">
          <p class="site-eyebrow leading-[normal]">CHANGELOG</p>
          <h1 class="m-0 mt-2.5 text-balance text-4xl font-semibold leading-[normal] tracking-[-0.035em] sm:text-[52px]">
            What changed in DevAction UI
          </h1>
          <p class="m-0 mt-3.5 max-w-[640px] text-lg leading-[1.55] text-(--cl-ink-2)">
            Each version lists new components, improvements, fixes and breaking changes, with the migration step beside it.
          </p>
          <div
            id="changelog-filters"
            role="group"
            aria-label="Kind of change"
            class="mt-7 flex flex-wrap gap-2"
          >
            <button
              :for={{id, label} <- @filters}
              type="button"
              data-filter={id}
              aria-pressed={to_string(id == "all")}
              class={[
                "group/pill inline-flex h-9 cursor-pointer items-center gap-2 rounded-[10px] border border-line bg-card px-3 font-sans text-sm font-medium leading-[normal] text-ink-2 outline-none",
                "focus-visible:ring-4 focus-visible:ring-ink/10",
                "aria-pressed:border-ink aria-pressed:bg-ink aria-pressed:text-(--cl-on)",
                @counts[id] == 0 && "opacity-50"
              ]}
            >
              <span class={["size-2 rounded-[2px]", dot(id)]} aria-hidden="true"></span>
              {label}
              <span class={[
                "font-mono text-[11px] text-muted",
                "group-aria-pressed/pill:text-(--cl-on-count)"
              ]}>
                {@counts[id]}
              </span>
            </button>
          </div>
        </header>

        <div class="mx-auto grid max-w-[1200px] grid-cols-1 gap-10 px-5 pb-[72px] pt-11 sm:px-10 lg:grid-cols-[200px_1fr] lg:gap-12">
          <aside class="text-sm leading-[normal]">
            <div class="lg:sticky lg:top-6">
              <p class="m-0 font-mono text-[11px] tracking-[0.08em] text-muted">VERSIONS</p>
              <nav aria-label="Versions" class="mt-3 flex flex-col gap-0.5">
                <a
                  :for={version <- @versions}
                  href={"#" <> anchor(version)}
                  class={[
                    "box-content flex h-[34px] items-center gap-2 rounded-lg px-2.5 no-underline outline-none focus-visible:ring-4 focus-visible:ring-ink/10",
                    side_class(version.status)
                  ]}
                >
                  <span
                    class={["box-content size-2 rounded-full", side_dot(version.status)]}
                    aria-hidden="true"
                  ></span>
                  {version.version}
                  <span class={["ml-auto text-[11px] font-normal", side_note_class(version.status)]}>
                    {side_note(version.status)}
                  </span>
                </a>
              </nav>
              <div class="mt-7 rounded-xl border border-line bg-card p-3.5 text-[13px] leading-[1.5] text-(--cl-ink-2)">
                <p class="m-0 font-semibold text-ink">How we version</p>
                <p class="m-0 mt-1.5">
                  SemVer. While it is 0.x, a minor version may break compatibility, and every break is marked with the migration step.
                </p>
              </div>
            </div>
          </aside>

          <div class="flex min-w-0 flex-col">
            <.release :for={version <- @versions} version={version} />

            <div class="lg:pl-8">
              <section
                id="entry-format"
                class="rounded-[14px] border border-line bg-card px-5 py-[18px]"
              >
                <h2 class="m-0 text-[15px] font-semibold leading-[normal]">Format of each entry</h2>
                <ul class="m-0 mt-3 grid list-none grid-cols-1 gap-2.5 p-0 sm:grid-cols-2 lg:grid-cols-4">
                  <li
                    :for={{kind, text} <- @legend}
                    class="flex flex-col gap-1.5 text-[13px] leading-[1.45] text-(--cl-ink-2)"
                  >
                    <.kind_badge kind={kind} />
                    {text}
                  </li>
                </ul>
              </section>
            </div>
          </div>
        </div>
      </main>
    </div>
    """
  end

  attr :version, :map, required: true

  defp release(assigns) do
    assigns = assign(assigns, :install, install_line(assigns.version))

    ~H"""
    <article
      id={anchor(@version)}
      data-release
      class={[
        "relative scroll-mt-6 border-l border-(--cl-rail) pb-12 pl-6 sm:pl-8",
        (@version.status == "next" && "border-dashed") || "border-solid"
      ]}
    >
      <span
        class={[
          "absolute -left-[7px] top-1.5 box-content size-3 rounded-full border shadow-[0_0_0_4px_var(--wrap)]",
          timeline_dot(@version.status)
        ]}
        aria-hidden="true"
      ></span>
      <div class="flex flex-wrap items-center gap-x-3 gap-y-1">
        <h2 class="m-0 text-[28px] font-semibold leading-[normal] tracking-[-0.02em]">
          {@version.version}
        </h2>
        <Tag.tag variant={status_variant(@version.status)} class="h-[26px] py-0 tracking-normal!">
          {status_label(@version.status)}
        </Tag.tag>
        <span class="ml-auto font-mono text-xs leading-[normal] text-muted">{released(@version)}</span>
      </div>
      <p class="m-0 mt-2.5 max-w-[720px] text-base leading-[1.6] text-ink-2">{@version.summary}</p>

      <div
        :if={@install}
        class="mt-4 box-content inline-flex h-10 max-w-full items-center gap-3 overflow-x-auto rounded-[10px] bg-(--site-code) pl-3.5 pr-1.5 font-mono text-[13px] text-(--cl-code-ink)"
      >
        <code id={"install-" <> anchor(@version)} class="whitespace-nowrap font-[inherit]">{@install}</code>
        <button
          type="button"
          data-copy-text={@install}
          class="group inline-flex h-[30px] shrink-0 cursor-pointer items-center gap-1.5 rounded-[7px] border border-(--cl-copy-line) bg-(--cl-copy-bg) px-2.5 font-sans text-xs leading-[normal] text-(--cl-code-ink) outline-none hover:brightness-125 focus-visible:ring-2 focus-visible:ring-white/40"
        >
          <span class="group-data-[copied]:hidden">Copy</span>
          <span class="hidden group-data-[copied]:inline" role="status">Copied</span>
        </button>
      </div>

      <div class="mt-5 flex flex-col gap-3">
        <details
          :for={{{group, entries}, index} <- Enum.with_index(@version.groups)}
          id={"#{anchor(@version)}-#{String.downcase(group)}"}
          data-group
          open={index == 0}
          class="group/details overflow-hidden rounded-[14px] border border-line bg-card"
        >
          <summary class="flex cursor-pointer list-none items-center gap-3 px-4 py-3.5 text-[15px] outline-none focus-visible:ring-4 focus-visible:ring-ink/10 [&::-webkit-details-marker]:hidden">
            <span class="font-semibold">{group}</span>
            <span data-count class="font-mono text-xs leading-[normal] text-muted">{length(entries)}</span>
            <.icon
              name="arrow-down-01"
              class="ml-auto size-4 text-muted transition-transform group-open/details:rotate-180"
            />
          </summary>
          <ul class="m-0 list-none border-t border-(--cl-soft) p-0">
            <li
              :for={entry <- entries}
              data-kind={entry.kind}
              class="grid grid-cols-1 items-baseline gap-x-3 gap-y-1 border-b border-(--cl-soft) px-4 py-[11px] text-sm leading-[normal] md:grid-cols-[96px_170px_1fr]"
            >
              <.kind_badge kind={entry.kind} />
              <.entry_name entry={entry} />
              <span class="leading-[1.5] text-(--cl-ink-2)">{entry.summary}</span>
            </li>
          </ul>
        </details>
        <p
          data-empty
          hidden
          class="m-0 rounded-[14px] border border-dashed border-(--cl-rail) p-[18px] text-sm text-muted"
        >
          No change of this kind in this version.
        </p>
      </div>
    </article>
    """
  end

  attr :kind, :string, required: true

  defp kind_badge(assigns) do
    ~H"""
    <Tag.tag
      variant={kind_variant(@kind)}
      class={["h-6 justify-self-start self-start py-0 tracking-normal!", kind_class(@kind)]}
    >
      {@kind}
    </Tag.tag>
    """
  end

  attr :entry, :map, required: true

  defp entry_name(assigns) do
    assigns = assign(assigns, :href, href(assigns.entry))

    ~H"""
    <.link
      :if={@href}
      navigate={@href}
      class="font-mono text-[13px] font-medium text-ink no-underline outline-none hover:underline focus-visible:ring-4 focus-visible:ring-ink/10"
    >
      {@entry.name}
    </.link>
    <span :if={!@href} class="font-mono text-[13px] font-medium">{@entry.name}</span>
    """
  end

  defp href(%{group: "Templates", name: name}) do
    case Templates.fetch(name) do
      {:ok, _group} -> "/templates/" <> name
      :error -> nil
    end
  end

  defp href(%{name: name}) do
    case Catalog.fetch(name) do
      {:ok, _topic} -> "/c/" <> name
      :error -> nil
    end
  end

  defp anchor(%{version: version}), do: String.replace(version, ".", "")

  defp install_line(%{status: "current", tag: tag}) when is_binary(tag),
    do: ~s|{:devaction_ui, github: "devaction-labs/devaction_ui", tag: "#{tag}"}|

  defp install_line(_version), do: nil

  defp released(%{released_on: %Date{} = date}), do: Date.to_iso8601(date)
  defp released(%{tag: tag}) when is_binary(tag), do: "tag " <> tag
  defp released(_version), do: "no date"

  defp status_label("next"), do: "IN DEVELOPMENT"
  defp status_label("current"), do: "CURRENT VERSION"
  defp status_label(_status), do: "ARCHIVED"

  defp status_variant("next"), do: :warn
  defp status_variant("current"), do: :ok
  defp status_variant(_status), do: :neutral

  defp timeline_dot("next"), do: "border-dashed border-(--cl-dashed) bg-wrap"
  defp timeline_dot("current"), do: "border-tag-ok-text bg-tag-ok-text"
  defp timeline_dot(_status), do: "border-line-strong bg-line-strong"

  defp side_class("current"), do: "border border-line bg-card font-medium text-ink"
  defp side_class(_status), do: "text-(--cl-ink-2) hover:text-ink"

  defp side_dot("next"), do: "border-[1.5px] border-dashed border-(--cl-dashed)"
  defp side_dot("current"), do: "bg-tag-ok-text"
  defp side_dot(_status), do: "bg-dot-neutral"

  defp side_note("next"), do: "next"
  defp side_note("current"), do: "current"
  defp side_note(_status), do: "old"

  defp side_note_class("current"), do: "text-tag-ok-text"
  defp side_note_class(_status), do: "text-muted"

  defp kind_variant("new"), do: :ok
  defp kind_variant("improved"), do: :info
  defp kind_variant("fixed"), do: :neutral
  defp kind_variant("breaking"), do: :risk
  defp kind_variant("planned"), do: :warn

  defp dot("all"), do: "bg-ink"
  defp dot("new"), do: "bg-tag-ok-text"
  defp dot("improved"), do: "bg-(--cl-info-text)"
  defp dot("fixed"), do: "bg-tag-neutral-text"
  defp dot("breaking"), do: "bg-tag-risk-text"
  defp dot("planned"), do: "bg-tag-warn-text"

  defp kind_class("improved"), do: "text-(--cl-info-text)!"
  defp kind_class("fixed"), do: "border-(--cl-neutral-line)! bg-(--cl-neutral-bg)!"
  defp kind_class(_kind), do: nil
end
