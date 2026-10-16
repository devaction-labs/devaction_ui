defmodule DevactionUISite.Shell do
  @moduledoc """
  The frame around every page of the site: the header (logo, version, links, search, GitHub, theme), the left
  sidebar of components and the right rail with "On this page".

  `shell/1` is what the pages use. `page` is the assigns of the LiveView (the shell reads the page, the
  search and the filtered components from it); `sidebar` shows or hides the left sidebar (the home and the
  changelog hide it) and `toc` fills the "On this page" index. The inner block is the content, the `rail`
  slot adds cards under the index. Without the sidebar the content is not padded or limited in width: the
  page draws its own layout.
  """
  use Phoenix.Component

  import DevactionUISite.Icon

  alias DevactionUI.Kbd
  alias DevactionUISite.{Catalog, Project, Templates}
  alias Phoenix.LiveView.JS

  attr :page, :map, required: true, doc: "the assigns of the LiveView"
  attr :sidebar, :boolean, default: true
  attr :toc, :list, default: [], doc: "`{id, label, level}` for the right rail"
  attr :toc_key, :string, default: "page"
  slot :inner_block, required: true
  slot :rail, doc: "cards under the index of the right rail"

  def shell(assigns) do
    assigns =
      assign(assigns,
        live_action: assigns.page.live_action,
        topic: Map.get(assigns.page, :topic),
        template: Map.get(assigns.page, :template_group),
        groups: Map.get(assigns.page, :nav_groups, Catalog.groups()),
        query: Map.get(assigns.page, :nav_query, "")
      )

    ~H"""
    <div id="site" class="min-h-screen bg-wrap text-ink">
      <a
        href="#main"
        class="sr-only z-50 rounded-lg bg-card px-3 py-2 text-sm text-ink focus:not-sr-only focus:fixed focus:top-2 focus:left-2"
      >
        Skip to content
      </a>

      <.topbar live_action={@live_action} query={@query} groups={@groups} sidebar={@sidebar} />

      <details id="mobile-nav" class="border-b border-line bg-card lg:hidden" open={@query != ""}>
        <summary class="flex cursor-pointer list-none items-center gap-2 px-5 py-3 text-sm font-medium text-ink-2">
          <.icon name="menu-01" class="size-4" /> Menu
        </summary>
        <div class="max-h-[60vh] overflow-y-auto px-4 pb-5">
          <.main_links live_action={@live_action} class="flex flex-col gap-0.5 pb-4 text-sm" />
          <.sidebar
            :if={@sidebar}
            live_action={@live_action}
            topic={@topic}
            template={@template}
            groups={@groups}
            query={@query}
          />
        </div>
      </details>

      <div :if={@sidebar} class={layout_class(@toc != [] or @rail != [])}>
        <aside
          id="sidebar"
          aria-label="Components"
          class="sticky hidden overflow-y-auto border-r border-line px-3.5 py-5 lg:block"
        >
          <.sidebar
            live_action={@live_action}
            topic={@topic}
            template={@template}
            groups={@groups}
            query={@query}
          />
        </aside>

        <main id="main" class="min-w-0 px-5 pt-9 pb-16 sm:px-12">
          <div class="mx-auto max-w-[900px]">
            {render_slot(@inner_block)}
            <p class="m-0 mt-16 border-t border-line pt-6 text-center text-[13px] text-muted">
              Toda honra e glória ao Senhor Jesus.
            </p>
          </div>
        </main>

        <aside
          :if={@toc != [] or @rail != []}
          class="hidden pt-9 pr-6 xl:block"
        >
          <div class="sticky top-24 flex max-h-[calc(100vh-7rem)] flex-col gap-7 overflow-y-auto text-[13px]">
            <.on_this_page toc={@toc} toc_key={@toc_key} />
            {render_slot(@rail)}
          </div>
        </aside>
      </div>

      <main :if={!@sidebar} id="main">
        {render_slot(@inner_block)}
      </main>
    </div>
    """
  end

  defp layout_class(true),
    do: "lg:grid lg:grid-cols-[260px_minmax(0,1fr)] xl:grid-cols-[260px_minmax(0,1fr)_232px]"

  defp layout_class(false), do: "lg:grid lg:grid-cols-[260px_minmax(0,1fr)]"

  @doc "The logo of DevAction on its dark tile."
  attr :size, :integer, default: 28
  attr :class, :any, default: nil

  def logo(assigns) do
    ~H"""
    <span
      class={["grid shrink-0 place-items-center rounded-lg bg-[var(--site-logo-tile)]", @class]}
      style={"width: #{@size}px; height: #{@size}px"}
    >
      <svg width={@size} height={@size} viewBox="50 50 1154 1154" aria-hidden="true">
        <path
          d="M395 303 H728 L912 492 Q968 552 968 628 Q968 706 905 770 L828 832 Q834 800 812 776 L392 330 Q380 314 395 303 Z"
          class="fill-[var(--site-logo-mark)]"
        />
        <path
          d="M628 662 Q641 650 654 662 L797 808 Q812 826 797 843 L722 935 Q712 945 698 945 H388 Q366 945 380 925 Z"
          class="fill-ai"
        />
      </svg>
    </span>
    """
  end

  attr :live_action, :atom, required: true
  attr :query, :string, default: ""
  attr :groups, :list, required: true
  attr :sidebar, :boolean, required: true

  defp topbar(assigns) do
    assigns = assign(assigns, variant: variant(assigns.live_action))

    ~H"""
    <header id="topbar" class="site-head" data-variant={@variant}>
      <.link patch="/" class="site-head-brand">
        <.logo size={logo_size(@variant)} />
        <span class="site-head-name">DevAction UI</span>
        <span :if={@variant != :changelog} class="site-head-chip hidden sm:inline-block">
          v{Project.short_version()}
        </span>
      </.link>

      <.main_links
        live_action={@live_action}
        variant={@variant}
        class="site-head-nav hidden lg:flex"
        label="Main"
        mobile={false}
      />

      <div class="site-head-tools">
        <.search :if={@variant != :changelog} query={@query} groups={@groups} sidebar={@sidebar} />
        <.head_buttons variant={@variant} />
      </div>
    </header>
    """
  end

  defp variant(:home), do: :home
  defp variant(:changelog), do: :changelog
  defp variant(_action), do: :docs

  defp logo_size(:home), do: 30
  defp logo_size(_variant), do: 28

  attr :variant, :atom, required: true

  defp head_buttons(%{variant: :changelog} = assigns) do
    ~H"""
    <a href={Project.repo_url() <> "/releases"} class="site-head-link">
      <.icon name="github" class="size-4" /> Releases
    </a>
    <a href={Project.repo_url() <> "/releases.atom"} class="site-head-link">
      <.icon name="notification-01" class="size-4" /> RSS
    </a>
    """
  end

  defp head_buttons(assigns) do
    ~H"""
    <a
      href={Project.repo_url()}
      aria-label="DevAction UI on GitHub"
      class="site-head-icon hidden sm:grid"
    >
      <.icon name="github" class="size-[18px]" />
    </a>

    <button
      id="theme-toggle"
      type="button"
      aria-label="Switch between light and dark"
      phx-click={JS.dispatch("phx:toggle-theme")}
      class="site-head-icon cursor-pointer"
    >
      <.icon name="moon-02" class="size-[18px] dark:hidden" />
      <.icon name="sun-03" class="hidden size-[18px] dark:block" />
    </button>
    """
  end

  attr :query, :string, default: ""
  attr :groups, :list, required: true
  attr :sidebar, :boolean, required: true

  defp search(assigns) do
    assigns =
      assign(assigns, :results, assigns.groups |> Enum.flat_map(&elem(&1, 1)) |> Enum.take(8))

    ~H"""
    <form
      id="search-form"
      phx-change="nav_search"
      phx-submit="nav_go"
      role="search"
      class="site-head-search"
    >
      <label for="site-search" class="sr-only">Search components</label>
      <.icon
        name="search-01"
        class="pointer-events-none absolute top-1/2 left-2.5 size-4 -translate-y-1/2 text-muted"
      />
      <input
        id="site-search"
        type="search"
        name="q"
        value={@query}
        placeholder="Search components"
        autocomplete="off"
        phx-debounce="80"
        class="site-head-input"
      />
      <Kbd.kbd tone={:bare} class="site-head-kbd hidden sm:block">⌘K</Kbd.kbd>

      <div
        :if={@query != ""}
        id="search-results"
        class={[
          "absolute top-full right-0 left-0 z-50 mt-2 rounded-xl border border-line bg-card p-1.5 shadow-lg",
          @sidebar && "lg:hidden"
        ]}
      >
        <p :if={@results == []} data-role="search-empty" class="m-0 px-2.5 py-2 text-sm text-muted">
          Nothing matches that search.
        </p>
        <.link
          :for={topic <- @results}
          patch={"/c/#{topic.slug}"}
          phx-click="nav_clear"
          class="flex h-8 items-center rounded-lg px-2.5 text-sm text-soft no-underline hover:bg-wrap hover:text-ink"
        >
          {topic.title}
        </.link>
      </div>
    </form>
    """
  end

  attr :live_action, :atom, required: true
  attr :class, :string, default: nil
  attr :label, :string, default: "Main menu"
  attr :mobile, :boolean, default: true
  attr :variant, :atom, default: :home

  defp main_links(assigns) do
    assigns =
      assign(assigns,
        current: current_section(assigns.live_action, assigns.variant),
        links: links(assigns.variant)
      )

    ~H"""
    <nav aria-label={@label} class={@class}>
      <.link
        :for={{key, label, to} <- @links}
        patch={to}
        aria-current={@current == key && "page"}
        class={[
          "inline-flex items-center gap-1.5 text-soft no-underline hover:text-ink aria-[current=page]:font-medium aria-[current=page]:text-ink",
          @mobile && "h-8 rounded-lg px-2.5 hover:bg-wrap"
        ]}
      >
        {label}
        <span
          :if={key == :changelog and @variant == :home}
          aria-hidden="true"
          class="size-1.5 rounded-full bg-dot-warn"
        ></span>
      </.link>
    </nav>
    """
  end

  defp links(variant) when variant in [:docs, :changelog],
    do: Enum.reject(links(:home), &(elem(&1, 0) == :components))

  defp links(:home) do
    [
      {:docs, "Documentation", "/docs"},
      {:components, "Components", "/c/#{hd(Catalog.all()).slug}"},
      {:tokens, "Tokens", "/tokens"},
      {:templates, "Templates", "/templates/#{hd(Templates.groups()).slug}"},
      {:changelog, "Changelog", "/changelog"}
    ]
  end

  defp current_section(:topic, :home), do: :components

  defp current_section(action, _variant) when action in [:overview, :installation, :topic],
    do: :docs

  defp current_section(:tokens, _variant), do: :tokens
  defp current_section(:templates, _variant), do: :templates
  defp current_section(:changelog, _variant), do: :changelog
  defp current_section(_action, _variant), do: nil

  attr :live_action, :atom, required: true
  attr :topic, :map, default: nil
  attr :template, :map, default: nil
  attr :groups, :list, required: true
  attr :query, :string, default: ""

  defp sidebar(assigns) do
    ~H"""
    <nav aria-label="Documentation" class="flex flex-col gap-[18px] text-sm">
      <div class="flex flex-col gap-px">
        <.side_link to="/docs" current={@live_action == :overview} class="h-8" tone="text-ink-2">Introduction</.side_link>
        <.side_link
          to="/installation"
          current={@live_action == :installation}
          class="h-8"
          tone="text-ink-2"
        >
          Installation
        </.side_link>
        <.side_link to="/tokens" current={@live_action == :tokens} class="h-8" tone="text-ink-2">
          Colors and tokens
        </.side_link>
        <.side_link to="/changelog" current={@live_action == :changelog} class="h-8" tone="text-ink-2">
          Changelog
          <span class="ml-auto rounded-[5px] border border-tag-warn-line bg-tag-warn-bg px-1.5 py-0.5 font-mono text-[10px] leading-[normal] text-tag-warn-text">
            v{Project.short_version()}
          </span>
        </.side_link>
      </div>

      <p :if={@groups == []} data-role="no-results" class="m-0 px-2.5 text-sm text-muted">
        Nothing matches that search.
      </p>

      <div :for={{group, topics} <- @groups} class="flex flex-col gap-px">
        <h2 class="m-0 flex px-2.5 pb-1.5 font-mono text-[11px] leading-[normal] font-normal tracking-[0.08em] text-muted uppercase">
          {group}
          <span class="ml-auto">{length(topics)}</span>
        </h2>
        <.side_link
          :for={topic <- topics}
          to={"/c/#{topic.slug}"}
          current={@live_action == :topic and @topic.slug == topic.slug}
          class="box-content h-[30px]"
        >
          {topic.title}
        </.side_link>
      </div>

      <div :if={@query == ""} class="flex flex-col gap-px">
        <h2 class="m-0 flex px-2.5 pb-1.5 font-mono text-[11px] leading-[normal] font-normal tracking-[0.08em] text-muted uppercase">
          Templates <span class="ml-auto">{length(Templates.groups())}</span>
        </h2>
        <.side_link
          :for={group <- Templates.groups()}
          to={"/templates/#{group.slug}"}
          current={@live_action == :templates and @template.slug == group.slug}
          class="box-content h-[30px]"
        >
          {group.title}
        </.side_link>
      </div>
    </nav>
    """
  end

  attr :to, :string, required: true
  attr :current, :boolean, default: false
  attr :class, :any, default: nil
  attr :tone, :string, default: "text-soft"
  slot :inner_block, required: true

  defp side_link(assigns) do
    ~H"""
    <.link
      patch={@to}
      aria-current={@current && "page"}
      class={[
        "flex items-center rounded-lg border border-transparent px-2.5 no-underline transition-colors hover:bg-card hover:text-ink aria-[current=page]:border-line aria-[current=page]:bg-card aria-[current=page]:font-medium aria-[current=page]:text-ink",
        @tone,
        @class
      ]}
    >
      {render_slot(@inner_block)}
    </.link>
    """
  end

  attr :toc, :list, required: true
  attr :toc_key, :string, required: true

  defp on_this_page(assigns) do
    ~H"""
    <nav
      :if={@toc != []}
      id={"toc-" <> @toc_key}
      aria-label="On this page"
      phx-hook="SiteToc"
    >
      <h2 class="m-0 font-mono text-[11px] font-normal tracking-[0.08em] text-muted uppercase">
        On this page
      </h2>
      <ul class="m-0 mt-2.5 flex list-none flex-col gap-0.5 border-l border-line p-0">
        <li :for={{id, label, level} <- @toc}>
          <a
            href={"#" <> id}
            class={[
              "-ml-px block border-l-2 border-transparent py-[5px] pl-3 text-muted no-underline transition-colors hover:text-ink aria-[current=location]:border-ink aria-[current=location]:text-ink",
              level == 2 && "pl-6"
            ]}
          >
            {label}
          </a>
        </li>
      </ul>
    </nav>
    """
  end
end
