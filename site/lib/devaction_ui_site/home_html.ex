defmodule DevactionUISite.HomeHTML do
  @moduledoc """
  The home page of the site: the hero with the install card, the numbers, the showcase of components drawn
  from static markup, the catalog by group, the principles, the changelog teaser and the footer. It renders
  the body only; the header comes from the shell. Counts come from the `Catalog` and the `Templates`, never
  typed, and the changelog teaser from `DevactionUISite.Changelog`.
  """
  use Phoenix.Component

  import DevactionUISite.Icon

  alias DevactionUISite.{Catalog, Changelog, Project, Templates}

  @github "https://github.com/devaction-labs/devaction_ui"

  @mix_install ~s|{:devaction_ui, "~> #{Project.short_version()}.0"}|
  @css_install ~S|@import "../../deps/devaction_ui/assets/css/devaction_ui.css";|
  @js_install_import ~S|import {hooks as devactionUI} from "../../deps/devaction_ui/assets/js/devaction_ui"|
  @js_install_socket ~S|new LiveSocket("/live", Socket, {hooks: {...devactionUI}})|

  @install [
    %{
      id: "mix",
      label: "mix.exs",
      comment: "# mix.exs",
      first: "defp deps do",
      second: "  [#{@mix_install}]"
    },
    %{
      id: "css",
      label: "app.css",
      comment: "/* assets/css/app.css */",
      first: ~S|@import "tailwindcss";|,
      second: @css_install
    },
    %{
      id: "js",
      label: "app.js",
      comment: "// assets/js/app.js",
      first: @js_install_import,
      second: @js_install_socket
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

  @bars [64, 92, 78, 110, 86, 124, 98, 132]

  @rows [
    %{
      name: "SGE · Church management",
      milestone: "M3",
      hours: "124 h",
      status: "At risk",
      dot: "bg-p-dot-risk",
      chip: "border-tag-risk-line bg-tag-risk-bg text-tag-risk-text"
    },
    %{
      name: "AYRAM web",
      milestone: "Retainer",
      hours: "38 h",
      status: "Attention",
      dot: "bg-p-accent",
      chip: "border-tag-warn-line bg-tag-warn-bg text-tag-warn-text"
    },
    %{
      name: "Hub API",
      milestone: "M2",
      hours: "62 h",
      status: "On track",
      dot: "bg-p-dot-ok",
      chip: "border-tag-ok-line bg-tag-ok-bg text-tag-ok-text"
    }
  ]

  @tags [
    {"On track", "border-tag-ok-line bg-tag-ok-bg text-tag-ok-text", "bg-tag-ok-text"},
    {"Attention", "border-tag-warn-line bg-tag-warn-bg text-tag-warn-text", "bg-eyebrow"},
    {"At risk", "border-tag-risk-line bg-tag-risk-bg text-tag-risk-text", "bg-tag-risk-text"},
    {"Waiting", "border-tag-info-line bg-tag-info-bg text-p-info", "bg-p-info"},
    {"Closed", "border-line bg-wrap text-ink-2", nil}
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
        bars: @bars,
        rows: @rows,
        tags: @tags,
        current: current,
        highlights: Changelog.highlights(Changelog.latest_release(versions)),
        next_line: next_line(next),
        github: @github
      )

    ~H"""
    <div id="home" class="site-home relative isolate overflow-hidden bg-wrap text-[15px] text-ink">
      <div class="site-grid site-grid-top" aria-hidden="true"></div>
      <div class="site-glow" aria-hidden="true"></div>

      <main>
        <section
          id="hero"
          class="relative mx-auto flex max-w-[1280px] flex-col items-center px-5 pb-14 pt-16 text-center sm:px-10 sm:pt-24"
        >
          <.link
            navigate="/changelog"
            class="inline-flex h-[34px] items-center gap-2.5 rounded-full border border-line bg-card px-1.5 text-[13px] text-ink-2 no-underline outline-none focus-visible:ring-4 focus-visible:ring-ink/10"
          >
            <span class="rounded-full border border-tag-warn-line bg-tag-warn-bg px-2 py-[3px] font-mono text-[11px] text-tag-warn-text">
              {@current.version}
            </span>
            {@count} components published · see the changelog
            <.icon name="arrow-right-01" class="mr-1.5 size-3.5" />
          </.link>

          <h1 class="mt-7 max-w-[900px] text-[2.5rem] font-semibold leading-[1.04] tracking-[-0.035em] sm:text-[60px] lg:text-[64px]">
            The interface of all<br class="hidden sm:inline" /> DevAction Labs projects.
          </h1>
          <p class="mt-[22px] max-w-[680px] text-[16px] leading-[1.55] text-soft sm:text-[19px]">
            Function components for Phoenix LiveView on Tailwind v4. Tokens that switch between light and dark, keyboard first and state always on the server.
          </p>

          <div class="mt-8 flex flex-wrap items-start justify-center gap-3">
            <.link
              navigate="/installation"
              class="inline-flex h-[46px] items-center gap-2 rounded-xl bg-ink px-5 font-medium text-p-on-ink no-underline outline-none focus-visible:ring-4 focus-visible:ring-ink/20"
            >
              Get started <.icon name="arrow-right-01" class="size-4" />
            </.link>
            <.link
              navigate={"/c/" <> @first_slug}
              class="inline-flex h-12 items-center gap-2 rounded-xl border border-line bg-card px-5 font-medium text-ink no-underline outline-none focus-visible:ring-4 focus-visible:ring-ink/10"
            >
              See the {@count} components
            </.link>
          </div>

          <.install_card id="install" tabs={@install} />
        </section>

        <section id="numbers" class="relative mx-auto max-w-[1280px] px-5 sm:px-10">
          <dl class="m-0 grid grid-cols-2 overflow-hidden rounded-2xl border border-line bg-card md:grid-cols-5">
            <.stat :for={{value, label} <- stats(@count, @group_count)} value={value} label={label} />
          </dl>
        </section>

        <section
          id="showcase"
          class="relative mx-auto max-w-[1280px] scroll-mt-20 px-5 pt-[72px] sm:px-10"
        >
          <div class="flex flex-wrap items-end justify-between gap-x-6 gap-y-3">
            <div>
              <p class="site-eyebrow">SHOWCASE</p>
              <h2 class="m-0 mt-2 text-[28px] font-semibold tracking-[-0.025em] sm:text-[34px]">
                The components as they run
              </h2>
              <p class="m-0 mt-2 text-[16px] text-soft">
                Each card opens the component page with examples, HEEx code and the full API.
              </p>
            </div>
            <.link
              navigate="#catalog"
              class="shrink-0 text-[14px] text-ink-2 underline outline-none focus-visible:ring-4 focus-visible:ring-ink/10"
            >
              All components →
            </.link>
          </div>

          <div class="mt-7 grid grid-cols-1 gap-4 md:grid-cols-12">
            <.show
              slug="button"
              name="Button"
              group="BASE"
              span="md:col-span-5"
              demo="h-[200px] flex-col justify-center gap-3"
            >
              <.show_button />
            </.show>
            <.show
              slug="command_palette"
              name="Command palette"
              group="OVERLAY"
              span="md:col-span-7"
              demo="h-[200px] justify-center"
            >
              <.show_palette />
            </.show>
            <.show
              slug="switch"
              name="Switch · Slider"
              group="FORM"
              span="md:col-span-4"
              demo="h-[180px] flex-col !items-stretch justify-center gap-4 px-7"
            >
              <.show_switch />
            </.show>
            <.show
              slug="tag"
              name="Tag · Badge"
              group="BASE"
              span="md:col-span-4"
              demo="h-[180px] flex-wrap content-center justify-center gap-2 px-6"
            >
              <.show_tags tags={@tags} />
            </.show>
            <.show
              slug="chart"
              name="Chart"
              group="DATA"
              span="md:col-span-4"
              demo="h-[208px] !items-end justify-center gap-2.5 px-7 pb-7"
            >
              <.show_chart bars={@bars} />
            </.show>
            <.show
              slug="data_table"
              name="Data table"
              group="DATA"
              span="md:col-span-7"
              demo="h-[200px] justify-center px-8"
            >
              <.show_table rows={@rows} />
            </.show>
            <.show
              slug="ai_prompt"
              name="AI prompt"
              group="AI"
              span="md:col-span-5"
              demo="h-[200px] justify-center px-7"
              tone="text-eyebrow"
            >
              <.show_ai />
            </.show>
          </div>
        </section>

        <section
          id="catalog"
          class="relative mx-auto max-w-[1280px] scroll-mt-20 px-5 pt-20 sm:px-10"
        >
          <p class="site-eyebrow">CATALOG</p>
          <h2 class="m-0 mt-2 text-[28px] font-semibold tracking-[-0.025em] sm:text-[34px]">
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
                <h3 class="m-0 text-[16px] font-semibold">{group.name}</h3>
                <span class="ml-auto font-mono text-[12px] text-muted">{length(group.items)}</span>
              </div>
              <ul class="m-0 mt-3.5 flex list-none flex-wrap gap-1.5 p-0">
                <li :for={item <- group.items}>
                  <.link
                    navigate={item.href}
                    class="inline-flex h-7 items-center rounded-[7px] border border-p-hair bg-wrap px-[9px] text-[12px] text-ink-2 no-underline outline-none hover:border-line-strong hover:text-ink focus-visible:ring-4 focus-visible:ring-ink/10"
                  >
                    {item.title}
                  </.link>
                </li>
              </ul>
            </div>
            <.link
              navigate="/changelog"
              class="site-card site-next flex flex-col p-5 no-underline outline-none focus-visible:ring-4 focus-visible:ring-ink/20"
            >
              <span class="site-next-eyebrow font-mono text-[11px] tracking-[0.08em]">
                NEXT VERSION
              </span>
              <span class="mt-2.5 text-[18px] font-semibold leading-[1.3]">{@next_line}</span>
              <span class="site-next-sub mt-auto pt-4 text-[13px]">Follow it in the changelog →</span>
            </.link>
          </div>
        </section>

        <section id="principles" class="relative mx-auto max-w-[1280px] px-5 pt-20 sm:px-10">
          <ul class="m-0 grid list-none grid-cols-1 gap-4 p-0 sm:grid-cols-2 lg:grid-cols-4">
            <li :for={{icon, title, text} <- @principles} class="px-1 pt-1">
              <span class="grid size-10 place-items-center rounded-[11px] border border-line bg-card text-ink">
                <.icon name={icon} class="size-[18px]" />
              </span>
              <h3 class="m-0 mt-3.5 text-[16px] font-semibold">{title}</h3>
              <p class="m-0 mt-1.5 text-[14px] leading-[1.55] text-soft">{text}</p>
            </li>
          </ul>
        </section>

        <section id="latest" class="relative mx-auto max-w-[1280px] px-5 pt-20 sm:px-10">
          <div class="site-card grid grid-cols-1 lg:grid-cols-[340px_1fr]">
            <div class="border-b border-p-hair p-7 lg:border-b-0 lg:border-r">
              <p class="site-eyebrow">CHANGELOG</p>
              <h2 class="m-0 mt-2.5 text-[24px] font-semibold tracking-[-0.02em]">
                {@current.version} · first release
              </h2>
              <p class="m-0 mt-2 text-[14px] leading-[1.55] text-soft">
                First public release of the kit, used in DevAction IA and in client projects.
              </p>
              <.link
                navigate="/changelog"
                class="mt-5 inline-flex h-10 items-center gap-2 rounded-[10px] border border-line px-3.5 text-[14px] no-underline outline-none focus-visible:ring-4 focus-visible:ring-ink/10"
              >
                See full changelog
              </.link>
            </div>
            <ul class="m-0 list-none px-7 py-5">
              <li
                :for={line <- @highlights}
                class="flex items-center gap-3 border-b border-p-hair py-2.5 text-[14px]"
              >
                <span class="flex h-6 w-[84px] flex-none items-center justify-center rounded-[6px] border border-tag-ok-line bg-tag-ok-bg font-mono text-[11px] text-tag-ok-text">
                  NEW
                </span>
                <span>{line}</span>
              </li>
            </ul>
          </div>
        </section>
      </main>

      <footer class="relative mx-auto mt-20 flex max-w-[1280px] flex-wrap items-center gap-x-6 gap-y-2 border-t border-line px-5 pb-10 pt-7 text-[13px] text-muted sm:px-10">
        <span>DevAction UI · made by DevAction Labs</span>
        <span class="sm:ml-auto">Phoenix LiveView 1.1+ · Tailwind v4 · Geist</span>
        <.link navigate="/changelog" class="underline hover:text-ink">Changelog</.link>
        <a href={@github} class="underline hover:text-ink">GitHub</a>
        <p class="m-0 basis-full pt-5 text-center">Toda honra e glória ao Senhor Jesus.</p>
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
      <div class="flex items-center gap-1 border-b border-p-inst-line pl-3 pr-2 pt-2">
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
            class="h-[34px] cursor-pointer border-0 border-b-2 border-transparent bg-transparent px-3 font-mono text-[12px] text-p-inst-tab outline-none focus-visible:ring-2 focus-visible:ring-white/40 aria-selected:border-p-accent-text aria-selected:text-white"
          >
            {tab.label}
          </button>
        </div>
        <button
          type="button"
          data-copy-text={hd(@tabs).text}
          class="group mb-1.5 ml-auto inline-flex h-7 cursor-pointer items-center gap-1.5 rounded-lg border border-p-inst-chip-line bg-p-inst-chip px-2.5 text-[12px] text-p-inst-fg outline-none hover:brightness-125 focus-visible:ring-2 focus-visible:ring-white/40"
        >
          <.icon name="copy-01" class="size-3.5 group-data-[copied]:hidden" />
          <.icon name="tick-02" class="hidden size-3.5 text-p-inst-ok group-data-[copied]:block" />
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
        <div class="px-5 py-[18px] font-mono text-[13px] leading-[1.7] text-p-inst-fg">
          <span class="block whitespace-pre text-p-inst-comment">{tab.comment}</span>
          <span class="block whitespace-pre">{tab.first}</span>
          <span class="block whitespace-pre text-p-inst-hl">{tab.second}</span>
        </div>
      </div>
    </div>
    """
  end

  attr :value, :string, required: true
  attr :label, :string, required: true

  defp stat(assigns) do
    ~H"""
    <div class="border-r border-p-hair px-[22px] py-5">
      <dd class="m-0 text-[28px] font-semibold tracking-[-0.02em]">{@value}</dd>
      <dt class="mt-1 text-[13px] text-muted">{@label}</dt>
    </div>
    """
  end

  attr :slug, :string, required: true
  attr :name, :string, required: true
  attr :group, :string, required: true
  attr :span, :string, required: true
  attr :demo, :string, required: true
  attr :tone, :string, default: "text-muted"
  slot :inner_block, required: true

  defp show(assigns) do
    ~H"""
    <article
      id={"show-" <> @slug}
      class={["site-card group/show focus-within:ring-4 focus-within:ring-ink/10", @span]}
    >
      <div class="site-grid site-grid-card" aria-hidden="true"></div>
      <div inert aria-hidden="true" class={["relative flex items-center", @demo]}>
        {render_slot(@inner_block)}
      </div>
      <div class="relative flex items-center justify-between border-t border-p-hair px-[18px] py-3.5">
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
    <div class="flex gap-2">
      <span class="flex h-[38px] items-center rounded-[10px] bg-ink px-3.5 text-[14px] font-medium text-p-on-ink">
        Request review
      </span>
      <span class="flex h-10 items-center rounded-[10px] border border-line bg-card px-3.5 text-[14px]">
        Cancel
      </span>
      <span class="flex h-10 items-center rounded-[10px] border border-tag-risk-line bg-tag-risk-bg px-3.5 text-[14px] text-tag-risk-text">
        Delete
      </span>
    </div>
    <div class="flex gap-2">
      <span class="flex h-8 items-center gap-1.5 rounded-lg border border-line bg-card px-2.5 text-[13px] text-ink-2">
        <.icon name="loading-03" class="size-3.5" /> Sending
      </span>
      <span class="flex size-8 items-center justify-center rounded-lg border border-line bg-card text-ink-2">
        <.icon name="more-horizontal" class="size-3.5" />
      </span>
    </div>
    """
  end

  defp show_palette(assigns) do
    ~H"""
    <div class="w-[422px] max-w-full overflow-hidden rounded-[14px] border border-line bg-card shadow-[0_18px_40px_-18px_rgb(24_24_27/0.3)]">
      <div class="flex h-[45px] items-center gap-2.5 border-b border-p-hair px-3.5 text-[14px] text-muted">
        <.icon name="search-01" class="size-4" />
        <span class="text-ink">revi</span>
        <span class="h-4 w-px bg-ink"></span>
      </div>
      <div class="p-1.5">
        <div class="flex h-9 items-center gap-2.5 rounded-lg bg-wrap px-2.5 text-[14px]">
          <.icon name="git-pull-request" class="size-4" /> Open the review of PR #214
          <span class="ml-auto font-mono text-[11px] text-muted">↵</span>
        </div>
        <div class="flex h-9 items-center gap-2.5 px-2.5 text-[14px] text-ink-2">
          <.icon name="sparkles" class="size-4" /> Review with AI
        </div>
      </div>
    </div>
    """
  end

  defp show_switch(assigns) do
    ~H"""
    <div class="flex items-center justify-between text-[14px]">
      <span>Review PRs automatically</span>
      <span class="relative h-6 w-10 rounded-xl bg-ink">
        <span class="absolute right-[3px] top-[3px] size-[18px] rounded-full bg-card"></span>
      </span>
    </div>
    <div>
      <div class="flex justify-between text-[13px] text-soft">
        <span>Hours limit</span><span class="font-mono">60 h</span>
      </div>
      <div class="relative mt-2.5 h-1.5 rounded-[3px] bg-line">
        <span class="absolute inset-y-0 left-0 w-[62%] rounded-[3px] bg-ink"></span>
        <span class="absolute -top-1.5 left-[62%] -ml-[9px] size-5 rounded-full border border-p-thumb-line bg-card shadow-[0_1px_3px_rgb(0_0_0/0.15)]"></span>
      </div>
    </div>
    """
  end

  attr :tags, :list, required: true

  defp show_tags(assigns) do
    ~H"""
    <span
      :for={{label, tone, dot} <- @tags}
      class={[
        "flex h-7 items-center gap-1.5 rounded-[7px] border px-2.5 text-[12px] font-medium",
        tone
      ]}
    >
      <span :if={dot} class={["size-1.5 rounded-full", dot]}></span>{label}
    </span>
    """
  end

  attr :bars, :list, required: true

  defp show_chart(assigns) do
    ~H"""
    <span
      :for={{height, index} <- Enum.with_index(@bars)}
      class={[
        "w-[22px] rounded-t rounded-b-sm",
        (index == length(@bars) - 1 && "bg-p-accent") || "bg-ink"
      ]}
      style={"height: #{height}px"}
    ></span>
    """
  end

  attr :rows, :list, required: true

  defp show_table(assigns) do
    ~H"""
    <div class="w-full overflow-hidden rounded-xl border border-line bg-card text-[13px]">
      <div class="grid grid-cols-[2fr_1fr_1fr_90px] bg-p-thead px-3.5 py-2.5 font-mono text-[11px] tracking-[0.04em] text-muted">
        <span>PROJECT</span><span>MILESTONE</span><span>HOURS</span><span>STATUS</span>
      </div>
      <div
        :for={row <- @rows}
        class="grid grid-cols-[2fr_1fr_1fr_90px] items-center border-t border-p-hair px-3.5 py-[9px]"
      >
        <span class="flex items-center gap-2">
          <span class={["size-2 rounded-sm", row.dot]}></span>{row.name}
        </span>
        <span class="text-soft">{row.milestone}</span>
        <span class="font-mono text-soft">{row.hours}</span>
        <span class={[
          "flex h-6 items-center justify-self-start rounded-md border px-2 text-[11px]",
          row.chip
        ]}>
          {row.status}
        </span>
      </div>
    </div>
    """
  end

  defp show_ai(assigns) do
    ~H"""
    <div class="w-full rounded-[14px] border border-tag-warn-line bg-p-ai px-3.5 py-3 shadow-[0_0_0_4px_rgb(210_154_30/0.1)]">
      <div class="text-[14px] text-ink-2">Explain why finding #3 is blocking</div>
      <div class="mt-3.5 flex items-center gap-2">
        <span class="flex h-7 items-center gap-1.5 rounded-[7px] border border-line bg-card px-2 text-[12px] text-soft">
          <.icon name="attachment-01" class="size-[13px]" /> PR #214
        </span>
        <span class="ml-auto flex size-[30px] items-center justify-center rounded-[9px] bg-p-accent text-p-on-ink">
          <.icon name="arrow-up-02" class="size-[15px]" />
        </span>
      </div>
    </div>
    """
  end

  defp stats(count, groups),
    do: [
      {to_string(count), "components"},
      {to_string(groups), "groups"},
      {"0", "UI dependencies"},
      {"1.1+", "Phoenix LiveView"},
      {"v4", "Tailwind CSS"}
    ]

  defp install_text(%{comment: comment, first: first, second: second}),
    do: Enum.join([comment, first, second], "\n")

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
    do: %{icon: "panel-right", tint: "bg-tag-info-bg text-p-info"}

  defp group_style("Form"), do: %{icon: "edit-02", tint: "bg-tag-ok-bg text-tag-ok-text"}

  defp group_style("Navigation"),
    do: %{icon: "sidebar-left-01", tint: "bg-p-indigo-bg text-p-indigo-text"}

  defp group_style("Data"), do: %{icon: "chart-line-data-01", tint: "bg-wrap text-ink"}
  defp group_style("AI"), do: %{icon: "sparkles", tint: "bg-tag-warn-bg text-tag-warn-text"}

  defp group_style("Templates"),
    do: %{icon: "lock-password", tint: "bg-tag-risk-bg text-tag-risk-text"}

  defp next_line(nil), do: "The next version is being planned"

  defp next_line(%{version: version, summary: summary, entries: entries}) do
    names =
      for %{name: name} <- entries,
          not String.contains?(name, "."),
          do: String.downcase(Changelog.humanize(name))

    sentence(version, summary, names)
  end

  defp sentence(version, summary, []), do: "#{version}: #{summary |> String.split(",") |> hd()}"
  defp sentence(version, _summary, names), do: "#{version} brings #{join(names)}"

  defp join([only]), do: only
  defp join(names), do: Enum.join(Enum.drop(names, -1), ", ") <> " and " <> List.last(names)
end
