defmodule DevactionUISite.HomeHTML do
  @moduledoc """
  The home page of the site: the hero with the install card, the numbers, the showcase of components running
  with static sample data, the catalog by group, the principles, the changelog teaser and the footer. It renders
  the body only; the header comes from the shell. Counts come from the `Catalog` and the `Templates`, never
  typed, and the changelog teaser from `DevactionUISite.Changelog`.
  """
  use Phoenix.Component

  import DevactionUISite.Icon

  alias DevactionUI.{
    AiPrompt,
    Button,
    Chart,
    CodeBlock,
    CommandPalette,
    DataTable,
    Slider,
    Switch,
    Tag
  }

  alias DevactionUISite.{Catalog, Changelog, Templates}

  @github "https://github.com/devaction-labs/devaction_ui"

  @mix_install ~S|{:devaction_ui, github: "devaction-labs/devaction_ui"}|
  @css_install ~S|@import "../../deps/devaction_ui/assets/css/devaction_ui.css";|
  @js_install_import ~S|import {hooks as devactionUI} from "../../deps/devaction_ui/assets/js/devaction_ui"|
  @js_install_socket ~S|new LiveSocket("/live", Socket, {hooks: {...devactionUI}})|

  @install [
    %{
      id: "mix",
      lang: :elixir,
      label: "mix.exs",
      comment: "# mix.exs",
      lines: ["defp deps do", "  [#{@mix_install}]"]
    },
    %{
      id: "css",
      lang: nil,
      label: "app.css",
      comment: "/* assets/css/app.css */",
      lines: [~S|@import "tailwindcss";|, @css_install]
    },
    %{
      id: "js",
      lang: nil,
      label: "app.js",
      comment: "// assets/js/app.js",
      lines: [@js_install_import, @js_install_socket]
    }
  ]

  @principles [
    {"moon-02", "Tokens, not colors",
     "Components read tokens. Light and dark switch with no dark: class anywhere."},
    {"command", "Keyboard first",
     "Arrows, Home, End and Esc on everything interactive. Focus is always visible."},
    {"plug-socket", "State on the server",
     "Each component sends a LiveView event. The state stays with you."},
    {"globe-02", "No built-in text",
     "Text and icons come in through attributes and slots. No Gettext in the kit."}
  ]

  def page(assigns) do
    versions = assigns[:changelog_versions] || Changelog.versions()
    current = Enum.find(versions, &(&1.status == "current"))
    next = Enum.find(versions, &(&1.status == "next"))
    count = length(Catalog.all())

    assigns =
      assign(assigns,
        count: count,
        group_count: length(Catalog.groups()) + length(Templates.groups()),
        first_slug: hd(Catalog.all()).slug,
        install: Enum.map(@install, &Map.put(&1, :text, install_text(&1))),
        catalog: catalog(),
        principles: @principles,
        current: current,
        highlights: Changelog.highlights(current),
        next_line: next_line(next),
        github: @github
      )

    ~H"""
    <div id="home" class="relative isolate overflow-hidden bg-wrap text-ink">
      <div class="site-grid site-grid-top" aria-hidden="true"></div>
      <div class="site-glow" aria-hidden="true"></div>

      <main>
        <section
          id="hero"
          class="relative mx-auto flex max-w-[1200px] flex-col items-center px-5 pb-14 pt-16 text-center sm:px-10 sm:pt-24"
        >
          <.link
            navigate="/changelog"
            class="inline-flex min-h-8 items-center gap-2.5 rounded-full border border-line bg-card py-1 pl-1.5 pr-2 text-[13px] text-ink-2 no-underline outline-none focus-visible:ring-4 focus-visible:ring-ink/10"
          >
            <span class="rounded-full border border-tag-warn-line bg-tag-warn-bg px-2 py-0.5 font-mono text-[11px] text-tag-warn-text">
              {@current.version}
            </span>
            {@count} components published · see the changelog
            <.icon name="arrow-right-01" class="size-3.5" />
          </.link>

          <h1 class="mt-7 max-w-[900px] text-balance text-[2.5rem] font-semibold leading-[1.04] tracking-[-0.035em] sm:text-6xl lg:text-[64px]">
            The interface of all<br class="hidden sm:inline" /> DevAction Labs projects.
          </h1>
          <p class="mt-5 max-w-[680px] text-balance text-base leading-[1.55] text-ink-2 sm:text-[19px]">
            Function components for Phoenix LiveView on Tailwind v4. Tokens that switch between light and dark, keyboard first and state always on the server.
          </p>

          <div class="mt-8 flex flex-wrap justify-center gap-3">
            <Button.button navigate="/installation" variant={:primary} size={:md}>
              Get started <.icon name="arrow-right-01" class="size-4" />
            </Button.button>
            <Button.button navigate={"/c/" <> @first_slug} variant={:secondary} size={:md}>
              See the {@count} components
            </Button.button>
          </div>

          <.install_card id="install" tabs={@install} />
        </section>

        <section id="numbers" class="relative mx-auto max-w-[1200px] px-5 sm:px-10">
          <dl class="m-0 grid grid-cols-2 gap-px overflow-hidden rounded-2xl border border-line bg-line-soft md:grid-cols-5">
            <.stat :for={{value, label} <- stats(@count, @group_count)} value={value} label={label} />
          </dl>
        </section>

        <section
          id="showcase"
          class="relative mx-auto max-w-[1200px] scroll-mt-20 px-5 pt-[72px] sm:px-10"
        >
          <div class="flex flex-wrap items-end justify-between gap-x-6 gap-y-3">
            <div>
              <p class="site-eyebrow">SHOWCASE</p>
              <h2 class="mt-2 text-[28px] font-semibold tracking-[-0.025em] sm:text-[34px]">
                The components as they run
              </h2>
              <p class="mt-2 text-base text-ink-2">
                Each card opens the component page with examples, HEEx code and the full API.
              </p>
            </div>
            <.link
              navigate="#catalog"
              class="shrink-0 text-sm text-ink-2 underline underline-offset-4 outline-none hover:text-ink focus-visible:ring-4 focus-visible:ring-ink/10"
            >
              All components →
            </.link>
          </div>

          <div class="mt-7 grid grid-cols-1 gap-4 md:grid-cols-12">
            <.show slug="button" name="Button" group="BASE" span="md:col-span-5" height="h-[200px]">
              <.show_button />
            </.show>
            <.show
              slug="command_palette"
              name="Command palette"
              group="OVERLAY"
              span="md:col-span-7"
              height="h-[236px]"
            >
              <.show_palette />
            </.show>
            <.show
              slug="switch"
              name="Switch · Slider"
              group="FORM"
              span="md:col-span-4"
              height="h-[180px]"
            >
              <.show_switch />
            </.show>
            <.show slug="tag" name="Tag · Badge" group="BASE" span="md:col-span-4" height="h-[180px]">
              <.show_tags />
            </.show>
            <.show slug="chart" name="Chart" group="DATA" span="md:col-span-4" height="h-[180px]">
              <.show_chart />
            </.show>
            <.show
              slug="data_table"
              name="Data table"
              group="DATA"
              span="md:col-span-7"
              height="h-[200px]"
            >
              <.show_table />
            </.show>
            <.show
              slug="ai_prompt"
              name="AI prompt"
              group="AI"
              span="md:col-span-5"
              height="h-[200px]"
              tone="text-tag-warn-text"
            >
              <.show_ai />
            </.show>
          </div>
        </section>

        <section
          id="catalog"
          class="relative mx-auto max-w-[1200px] scroll-mt-20 px-5 pt-20 sm:px-10"
        >
          <p class="site-eyebrow">CATALOG</p>
          <h2 class="mt-2 text-[28px] font-semibold tracking-[-0.025em] sm:text-[34px]">
            {@count} components in {@group_count} groups
          </h2>
          <div class="mt-6 grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
            <div
              :for={group <- @catalog}
              id={"group-" <> String.downcase(group.name)}
              class="site-card p-5"
            >
              <div class="flex items-center gap-2.5">
                <span class={["grid size-[34px] place-items-center rounded-[10px]", group.tint]}>
                  <.icon name={group.icon} class="size-[18px]" />
                </span>
                <h3 class="m-0 text-base font-semibold">{group.name}</h3>
                <span class="ml-auto font-mono text-xs text-muted">{length(group.items)}</span>
              </div>
              <ul class="m-0 mt-3.5 flex list-none flex-wrap gap-1.5 p-0">
                <li :for={item <- group.items}>
                  <.link
                    navigate={item.href}
                    class="inline-flex h-[26px] items-center rounded-[7px] border border-line-soft bg-wrap px-[9px] text-xs text-ink-2 no-underline outline-none hover:border-line-strong hover:text-ink focus-visible:ring-4 focus-visible:ring-ink/10"
                  >
                    {item.title}
                  </.link>
                </li>
              </ul>
            </div>
            <.link
              navigate="/changelog"
              class="site-card site-next flex flex-col p-5 text-white no-underline outline-none focus-visible:ring-4 focus-visible:ring-ink/20"
            >
              <span class="font-mono text-[11px] tracking-[0.08em] text-[#E3A72F]">NEXT VERSION</span>
              <span class="mt-2.5 text-lg font-semibold leading-[1.3]">{@next_line}</span>
              <span class="mt-auto pt-4 text-[13px] text-[#D4D4D8]">Follow it in the changelog →</span>
            </.link>
          </div>
        </section>

        <section id="principles" class="relative mx-auto max-w-[1200px] px-5 pt-20 sm:px-10">
          <ul class="m-0 grid list-none grid-cols-1 gap-4 p-0 sm:grid-cols-2 lg:grid-cols-4">
            <li :for={{icon, title, text} <- @principles} class="px-1 pt-1">
              <span class="grid size-[38px] place-items-center rounded-[11px] border border-line bg-card text-ink">
                <.icon name={icon} class="size-[18px]" />
              </span>
              <h3 class="m-0 mt-3.5 text-base font-semibold">{title}</h3>
              <p class="m-0 mt-1.5 text-sm leading-[1.55] text-ink-2">{text}</p>
            </li>
          </ul>
        </section>

        <section id="latest" class="relative mx-auto max-w-[1200px] px-5 pt-20 sm:px-10">
          <div class="site-card grid grid-cols-1 lg:grid-cols-[340px_1fr]">
            <div class="border-b border-line-soft p-7 lg:border-b-0 lg:border-r">
              <p class="site-eyebrow">CHANGELOG</p>
              <h2 class="m-0 mt-2.5 text-2xl font-semibold tracking-[-0.02em]">
                {@current.version} · first release
              </h2>
              <p class="m-0 mt-2 text-sm leading-[1.55] text-ink-2">
                First public release of the kit, used in DevAction IA and in client projects.
              </p>
              <Button.button navigate="/changelog" variant={:secondary} class="mt-5">
                See full changelog
              </Button.button>
            </div>
            <ul class="m-0 list-none px-7 py-5">
              <li
                :for={line <- @highlights}
                class="flex items-center gap-3 border-b border-line-soft py-2.5 text-sm"
              >
                <Tag.tag variant={:ok} size={:sm} class="w-[82px] justify-center font-mono">
                  NEW
                </Tag.tag>
                <span>{line}</span>
              </li>
            </ul>
          </div>
        </section>
      </main>

      <footer class="relative mx-auto mt-20 flex max-w-[1200px] flex-wrap items-center gap-x-6 gap-y-2 border-t border-line px-5 pb-10 pt-7 text-[13px] text-muted sm:px-10">
        <span>DevAction UI · made by DevAction Labs</span>
        <span class="sm:ml-auto">Phoenix LiveView 1.1+ · Tailwind v4 · Geist</span>
        <.link navigate="/changelog" class="underline underline-offset-2 hover:text-ink">
          Changelog
        </.link>
        <a href={@github} class="underline underline-offset-2 hover:text-ink">GitHub</a>
      </footer>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :tabs, :list, required: true

  defp install_card(assigns) do
    ~H"""
    <div
      id={@id}
      phx-hook="SiteInstall"
      data-initial="mix"
      class="site-code mt-10 w-full max-w-[640px] overflow-hidden rounded-2xl text-left shadow-[0_24px_60px_-24px_rgb(24_24_27/0.45)]"
    >
      <div class="flex items-center gap-1 border-b border-white/10 pl-3 pr-2 pt-2">
        <div role="tablist" aria-label="Where to put it" class="flex gap-1">
          <button
            :for={tab <- @tabs}
            id={"#{@id}-tab-#{tab.id}"}
            type="button"
            role="tab"
            data-tab={tab.id}
            aria-selected={to_string(tab.id == "mix")}
            aria-controls={"#{@id}-panel-#{tab.id}"}
            tabindex={(tab.id == "mix" && "0") || "-1"}
            class="h-[34px] cursor-pointer border-0 border-b-2 border-transparent bg-transparent px-3 font-mono text-xs text-[#8B8B99] outline-none focus-visible:ring-2 focus-visible:ring-white/40 aria-selected:border-[#E3A72F] aria-selected:text-white"
          >
            {tab.label}
          </button>
        </div>
        <button
          type="button"
          data-copy-text={hd(@tabs).text}
          class="group mb-1.5 ml-auto inline-flex h-7 cursor-pointer items-center gap-1.5 rounded-lg border border-white/15 bg-white/10 px-2.5 text-xs text-[#E4E4E7] outline-none hover:bg-white/15 focus-visible:ring-2 focus-visible:ring-white/40"
        >
          <.icon name="copy-01" class="size-3.5 group-data-[copied]:hidden" />
          <.icon name="tick-02" class="hidden size-3.5 text-[#8EF0B4] group-data-[copied]:block" />
          <span class="group-data-[copied]:hidden">Copy</span>
          <span class="hidden group-data-[copied]:inline" role="status">Copied</span>
        </button>
      </div>
      <div
        :for={tab <- @tabs}
        id={"#{@id}-panel-#{tab.id}"}
        role="tabpanel"
        aria-labelledby={"#{@id}-tab-#{tab.id}"}
        data-tab={tab.id}
        data-copy={tab.text}
        hidden={tab.id != "mix"}
        class="overflow-x-auto"
      >
        <CodeBlock.code_block
          tone={:dark}
          lang={tab.lang}
          code={tab.text}
          class="rounded-none! bg-transparent! px-5! py-[18px]! leading-[1.7]!"
        />
      </div>
    </div>
    """
  end

  attr :value, :string, required: true
  attr :label, :string, required: true

  defp stat(assigns) do
    ~H"""
    <div class="bg-card px-[22px] py-5">
      <dd class="m-0 text-[28px] font-semibold tracking-[-0.02em]">{@value}</dd>
      <dt class="mt-1 text-[13px] text-muted">{@label}</dt>
    </div>
    """
  end

  attr :slug, :string, required: true
  attr :name, :string, required: true
  attr :group, :string, required: true
  attr :span, :string, required: true
  attr :height, :string, required: true
  attr :tone, :string, default: "text-muted"
  slot :inner_block, required: true

  defp show(assigns) do
    ~H"""
    <article
      id={"show-" <> @slug}
      class={["site-card group/show focus-within:ring-4 focus-within:ring-ink/10", @span]}
    >
      <div class="site-grid site-grid-card" aria-hidden="true"></div>
      <div
        inert
        aria-hidden="true"
        class={["relative flex items-center justify-center overflow-hidden", @height]}
      >
        {render_slot(@inner_block)}
      </div>
      <div class="relative flex items-center justify-between border-t border-line-soft px-[18px] py-3.5">
        <.link
          navigate={"/c/" <> @slug}
          class="font-medium text-ink no-underline outline-none after:absolute after:inset-0 after:content-['']"
        >
          {@name}
        </.link>
        <span class={["font-mono text-[11px]", @tone]}>{@group}</span>
      </div>
    </article>
    """
  end

  defp show_button(assigns) do
    ~H"""
    <div class="flex flex-col items-center gap-3">
      <div class="flex gap-2">
        <Button.button variant={:primary} size={:sm}>Request review</Button.button>
        <Button.button size={:sm}>Cancel</Button.button>
        <Button.button variant={:danger} size={:sm}>Delete</Button.button>
      </div>
      <div class="flex gap-2">
        <Button.button size={:sm} loading>Sending</Button.button>
        <Button.button size={:sm} icon_only aria-label="More">
          <.icon name="more-horizontal" class="size-4" />
        </Button.button>
      </div>
    </div>
    """
  end

  defp show_palette(assigns) do
    ~H"""
    <div class="site-contained absolute inset-0">
      <CommandPalette.palette
        id="home-palette"
        label="Search"
        query="revi"
        search_event="home_palette_search"
        close_event="home_palette_close"
        empty="Nothing found."
        ask_label="Review with AI"
        ask_kbd="⌘↵"
        groups={[
          %{
            label: "Pull requests",
            items: [
              %{
                id: "pr214",
                label: "Open the review of PR #214",
                to: "/c/command_palette",
                hint: "#214",
                hint_style: :plain,
                tone: :info
              }
            ]
          }
        ]}
      >
        <:search_icon><.icon name="search-01" class="size-[18px]" /></:search_icon>
      </CommandPalette.palette>
    </div>
    """
  end

  defp show_switch(assigns) do
    ~H"""
    <div class="flex w-full flex-col gap-4 px-7">
      <div class="flex items-center justify-between text-sm">
        <span id="home-switch-label">Review PRs automatically</span>
        <Switch.switch id="home-switch" checked labelledby="home-switch-label" />
      </div>
      <Slider.slider
        id="home-slider"
        name="hours"
        label="Hours limit"
        value={60}
        min={0}
        max={100}
        format_text="%{value} h"
      />
    </div>
    """
  end

  defp show_tags(assigns) do
    ~H"""
    <div class="flex flex-wrap items-center justify-center gap-2 px-6">
      <Tag.tag variant={:ok}>On track</Tag.tag>
      <Tag.tag variant={:warn}>Attention</Tag.tag>
      <Tag.tag variant={:risk}>At risk</Tag.tag>
      <Tag.tag variant={:info}>Waiting</Tag.tag>
      <Tag.tag variant={:neutral}>Closed</Tag.tag>
    </div>
    """
  end

  defp show_chart(assigns) do
    assigns =
      assign(assigns,
        items:
          Enum.zip_with(
            ~w(Mar Apr May Jun Jul Aug Sep Oct),
            [64, 92, 78, 110, 86, 124, 98, 132],
            &%{label: &1, value: &2}
          )
      )

    ~H"""
    <Chart.column_chart
      id="home-chart"
      summary="Hours per month, from March to October"
      items={@items}
      class="px-5"
    />
    """
  end

  defp show_table(assigns) do
    ~H"""
    <div class="w-full px-8 text-[13px]">
      <DataTable.data_table
        id="home-table"
        label="Projects"
        select_all_label="Select all"
        select_row_label="Select row"
        selected_label="__COUNT__ selected"
        clear_label="Clear"
        rows={[
          %{
            id: "1",
            project: "SGE · Church management",
            milestone: "M3",
            hours: "124 h",
            status: :risk
          },
          %{id: "2", project: "AYRAM web", milestone: "Retainer", hours: "38 h", status: :warn},
          %{id: "3", project: "Hub API", milestone: "M2", hours: "62 h", status: :ok}
        ]}
      >
        <:col :let={row} label="PROJECT">{row.project}</:col>
        <:col :let={row} label="MILESTONE" class="text-ink-2">{row.milestone}</:col>
        <:col :let={row} label="HOURS" class="font-mono">{row.hours}</:col>
        <:col :let={row} label="STATUS">
          <Tag.tag variant={row.status} size={:sm}>{status_label(row.status)}</Tag.tag>
        </:col>
      </DataTable.data_table>
    </div>
    """
  end

  defp show_ai(assigns) do
    ~H"""
    <AiPrompt.ai_prompt
      id="home-ai"
      event="home_prompt"
      label="Ask the AI"
      send_label="Send"
      value="Explain why finding #3 is blocking"
      class="w-full px-7"
    >
      <:attachments>
        <Tag.tag variant={:neutral} size={:sm}>
          <.icon name="attachment-01" class="size-3" /> PR #214
        </Tag.tag>
      </:attachments>
      <:icon><.icon name="arrow-up-02" class="size-4" /></:icon>
    </AiPrompt.ai_prompt>
    """
  end

  defp status_label(:risk), do: "At risk"
  defp status_label(:warn), do: "Attention"
  defp status_label(:ok), do: "On track"

  defp stats(count, groups),
    do: [
      {to_string(count), "components"},
      {to_string(groups), "groups"},
      {"0", "UI dependencies"},
      {"1.1+", "Phoenix LiveView"},
      {"v4", "Tailwind CSS"}
    ]

  defp install_text(%{comment: comment, lines: lines}), do: Enum.join([comment | lines], "\n")

  defp catalog do
    components =
      for {category, topics} <- Catalog.groups() do
        %{
          name: category,
          items: Enum.map(topics, &%{title: &1.title, href: "/c/" <> &1.slug})
        }
      end

    templates = [
      %{
        name: "Templates",
        items: Enum.map(Templates.groups(), &%{title: &1.title, href: "/templates/" <> &1.slug})
      }
    ]

    Enum.map(components ++ templates, &Map.merge(&1, group_style(&1.name)))
  end

  defp group_style("Base"), do: %{icon: "dashboard-square-01", tint: "bg-wrap text-ink"}

  defp group_style("Overlay"),
    do: %{icon: "panel-right", tint: "bg-tag-info-bg text-tag-info-text"}

  defp group_style("Form"), do: %{icon: "edit-02", tint: "bg-tag-ok-bg text-tag-ok-text"}

  defp group_style("Navigation"),
    do: %{icon: "sidebar-left-01", tint: "bg-tag-indigo-bg text-tag-indigo-text"}

  defp group_style("Data"), do: %{icon: "chart-line-data-01", tint: "bg-wrap text-ink"}
  defp group_style("AI"), do: %{icon: "sparkles", tint: "bg-tag-warn-bg text-tag-warn-text"}

  defp group_style("Templates"),
    do: %{icon: "lock-password", tint: "bg-tag-risk-bg text-tag-risk-text"}

  defp next_line(nil), do: "The next version is being planned"

  defp next_line(%{version: version, entries: entries}) do
    names =
      for %{name: name} <- entries,
          not String.contains?(name, "."),
          do: String.downcase(Changelog.humanize(name))

    "#{version} brings #{join(names)}"
  end

  defp join([only]), do: only
  defp join(names), do: Enum.join(Enum.drop(names, -1), ", ") <> " and " <> List.last(names)
end
