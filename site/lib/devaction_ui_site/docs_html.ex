defmodule DevactionUISite.DocsHTML do
  @moduledoc """
  The pages of the documentation: the top bar, the sidebar by category, the content (introduction,
  installation, colour tokens, a component with its examples and API) and the "On this page" index.
  """
  use Phoenix.Component

  import DevactionUISite.Icon

  alias DevactionUI.{Button, CodeBlock, Kbd, Panel, Tag}
  alias DevactionUISite.{Catalog, Doc, Reference, ScreenHTML, Templates, Tokens, TopicHTML}
  alias Phoenix.LiveView.JS

  @install_css ~S|@import "../../deps/devaction_ui/assets/css/devaction_ui.css";|

  @install_js ~S|import {hooks as devactionUI} from "../../deps/devaction_ui/assets/js/devaction_ui"

new LiveSocket("/live", Socket, {hooks: {...devactionUI}})|

  @install_use ~S|alias DevactionUI.Tag

<Tag.tag variant={:ok}>Em dia</Tag.tag>|

  @install_dep ~S|{:devaction_ui, github: "devaction-labs/devaction_ui"}|

  def page(%{live_action: :preview} = assigns) do
    assigns =
      assign(assigns, :topics, Enum.map(assigns.previews, &{&1, TopicHTML.for_topic(&1.slug)}))

    ~H"""
    <div id="preview" class="flex min-h-screen flex-col gap-10 bg-frame p-12 text-ink">
      <section
        :for={{topic, examples} <- @topics}
        id={"preview-" <> topic.slug}
        class="flex flex-col gap-4"
      >
        <Panel.eyebrow>{topic.title}</Panel.eyebrow>
        <div
          :for={example <- examples}
          id={"preview-" <> example.id}
          class="flex flex-col gap-8 rounded-2xl border border-line bg-panel p-8"
        >
          <Panel.eyebrow>{example.title}</Panel.eyebrow>
          {live_render(@socket, DevactionUISite.ExampleLive,
            id: "live-preview-" <> example.id,
            session: %{"example" => example.id}
          )}
        </div>
      </section>
    </div>
    """
  end

  def page(assigns) do
    assigns = assign(assigns, :chrome, shell_attrs(assigns))

    ~H"""
    <.shell {@chrome}>
      <.content live_action={@live_action} topic={@topic} page_assigns={assigns} />
    </.shell>
    """
  end

  attr :live_action, :atom, required: true
  attr :topic, :map, default: nil
  attr :page_assigns, :map, required: true

  defp content(%{live_action: :overview} = assigns), do: ~H"<.introduction />"
  defp content(%{live_action: :installation} = assigns), do: ~H"<.installation />"
  defp content(%{live_action: :tokens} = assigns), do: ~H"<.tokens />"

  defp content(%{live_action: :templates} = assigns) do
    ~H"<.templates group={@page_assigns.template_group} />"
  end

  defp content(%{live_action: :topic} = assigns) do
    ~H"<.topic topic={@topic} assigns={@page_assigns} />"
  end

  defp shell_attrs(assigns) do
    %{
      live_action: assigns.live_action,
      topic: assigns.topic,
      template: assigns.template_group,
      groups: assigns.nav_groups,
      query: assigns.nav_query,
      toc: toc(assigns),
      toc_key:
        "#{assigns.live_action}-#{assigns.topic && assigns.topic.slug}-#{assigns.template_group && assigns.template_group.slug}"
    }
  end

  defp toc(%{live_action: :overview}),
    do: [{"principles", "What to expect", 1}, {"components", "Components", 1}]

  defp toc(%{live_action: :installation}),
    do: [
      {"dependency", "Dependency", 1},
      {"css", "Tailwind", 1},
      {"js", "Hooks", 1},
      {"use", "First component", 1}
    ]

  defp toc(%{live_action: :templates, template_group: group}),
    do: for(screen <- available_screens(group), do: {"screen-" <> screen.slug, screen.title, 1})

  defp toc(%{live_action: :tokens}),
    do: for({group, _tokens} <- Tokens.groups(), do: {"tokens-" <> slugify(group), group, 1})

  defp toc(%{live_action: :topic, topic: topic}) do
    examples = for example <- TopicHTML.for_topic(topic.slug), do: {example.id, example.title, 1}

    modules =
      for module <- topic.modules,
          do: {"api-" <> Reference.short(module), Reference.short(module), 2}

    examples ++ [{"api", "API reference", 1}] ++ modules
  end

  attr :live_action, :atom, required: true
  attr :topic, :map, default: nil
  attr :template, :map, default: nil
  attr :groups, :list, required: true
  attr :query, :string, default: ""
  attr :toc, :list, default: []
  attr :toc_key, :string, required: true
  slot :inner_block, required: true

  def shell(assigns) do
    ~H"""
    <div id="site" class="min-h-screen bg-frame">
      <.topbar query={@query} />

      <details id="mobile-nav" class="border-b border-line bg-panel lg:hidden">
        <summary class="flex cursor-pointer list-none items-center gap-2 px-5 py-3 text-sm font-medium text-ink-2">
          <.icon name="menu-01" class="size-4" /> Menu
        </summary>
        <div class="max-h-[60vh] overflow-y-auto px-5 pb-5">
          <.sidebar live_action={@live_action} topic={@topic} template={@template} groups={@groups} />
        </div>
      </details>

      <div class="mx-auto flex max-w-[1440px]">
        <aside
          id="sidebar"
          class="sticky top-16 hidden h-[calc(100vh-4rem)] w-64 shrink-0 overflow-y-auto border-r border-line px-5 py-8 lg:block"
        >
          <.sidebar live_action={@live_action} topic={@topic} template={@template} groups={@groups} />
        </aside>

        <main class="min-w-0 flex-1 px-5 py-10 sm:px-10 lg:px-14">
          <div class="mx-auto flex max-w-[780px] flex-col">
            {render_slot(@inner_block)}
          </div>
        </main>

        <aside class="sticky top-16 hidden h-[calc(100vh-4rem)] w-64 shrink-0 overflow-y-auto px-6 py-10 xl:block">
          <.on_this_page toc={@toc} toc_key={@toc_key} />
        </aside>
      </div>
    </div>
    """
  end

  attr :query, :string, default: ""

  defp topbar(assigns) do
    ~H"""
    <header id="topbar" class="sticky top-0 z-40 border-b border-line bg-frame/85 backdrop-blur">
      <div class="mx-auto flex h-16 max-w-[1440px] items-center gap-6 px-5">
        <.link patch="/" class="flex items-center gap-2.5 no-underline">
          <span class="grid size-8 place-items-center rounded-lg bg-ink text-on-primary">
            <.icon name="source-code" class="size-[18px]" />
          </span>
          <span class="text-lg font-bold tracking-[-0.03em] text-ink">DevactionUI</span>
          <Tag.tag size={:sm}>v0.1</Tag.tag>
        </.link>

        <nav aria-label="Main" class="ml-auto hidden items-center gap-6 text-sm font-medium sm:flex">
          <.link patch="/c/tag" class="text-ink-2 no-underline hover:text-ink">Components</.link>
          <.link patch="/installation" class="text-ink-2 no-underline hover:text-ink">Installation</.link>
          <.link patch="/tokens" class="text-ink-2 no-underline hover:text-ink">Colors</.link>
        </nav>

        <form
          id="search-form"
          phx-change="nav_search"
          phx-submit="nav_go"
          role="search"
          class="relative ml-auto sm:ml-0"
        >
          <label for="site-search" class="sr-only">Search the documentation</label>
          <.icon
            name="search-01"
            class="pointer-events-none absolute top-1/2 left-3 size-4 -translate-y-1/2 text-muted"
          />
          <input
            id="site-search"
            type="search"
            name="q"
            value={@query}
            placeholder="Search"
            autocomplete="off"
            phx-debounce="80"
            class="h-10 w-44 rounded-xl border border-line-strong bg-panel pr-14 pl-9 text-sm text-ink outline-none placeholder:text-muted focus:border-ink sm:w-56"
          />
          <Kbd.kbd class="pointer-events-none absolute top-1/2 right-2.5 -translate-y-1/2">
            ⌘K
          </Kbd.kbd>
        </form>

        <Button.button
          id="theme-toggle"
          variant={:ghost}
          size={:sm}
          icon_only
          aria-label="Switch between light and dark"
          phx-click={JS.dispatch("phx:toggle-theme")}
        >
          <.icon name="moon-02" class="size-[18px] dark:hidden" />
          <.icon name="sun-03" class="hidden size-[18px] dark:block" />
        </Button.button>
      </div>
    </header>
    """
  end

  attr :live_action, :atom, required: true
  attr :topic, :map, default: nil
  attr :template, :map, default: nil
  attr :groups, :list, required: true

  defp sidebar(assigns) do
    ~H"""
    <nav aria-label="Documentation" class="flex flex-col gap-8">
      <ul class="m-0 flex list-none flex-col gap-1 p-0">
        <.intro_link to="/" icon="book-02" label="Introduction" current={@live_action == :overview} />
        <.intro_link
          to="/installation"
          icon="download-04"
          label="Installation"
          current={@live_action == :installation}
        />
        <.intro_link
          to="/tokens"
          icon="magic-wand-01"
          label="Colors"
          current={@live_action == :tokens}
        />
      </ul>

      <div class="flex flex-col gap-2">
        <h2 class="m-0 px-3 text-xs font-bold tracking-[0.04em] text-ink uppercase">Templates</h2>
        <ul class="m-0 flex list-none flex-col border-l border-line p-0">
          <li :for={group <- Templates.groups()}>
            <.link
              patch={"/templates/#{group.slug}"}
              aria-current={(@live_action == :templates and @template.slug == group.slug) && "page"}
              class="-ml-px block border-l border-transparent px-4 py-1.5 text-sm text-ink-2 no-underline transition-colors hover:border-line-strong hover:text-ink aria-[current=page]:border-learn aria-[current=page]:font-medium aria-[current=page]:text-learn"
            >
              {group.title}
            </.link>
          </li>
        </ul>
      </div>

      <p :if={@groups == []} data-role="no-results" class="m-0 px-3 text-sm text-muted">
        Nothing matches that search.
      </p>

      <div :for={{group, topics} <- @groups} class="flex flex-col gap-2">
        <h2 class="m-0 px-3 text-xs font-bold tracking-[0.04em] text-ink uppercase">{group}</h2>
        <ul class="m-0 flex list-none flex-col border-l border-line p-0">
          <li :for={topic <- topics}>
            <.link
              patch={"/c/#{topic.slug}"}
              aria-current={(@live_action == :topic and @topic.slug == topic.slug) && "page"}
              class="-ml-px block border-l border-transparent px-4 py-1.5 text-sm text-ink-2 no-underline transition-colors hover:border-line-strong hover:text-ink aria-[current=page]:border-learn aria-[current=page]:font-medium aria-[current=page]:text-learn"
            >
              {topic.title}
            </.link>
          </li>
        </ul>
      </div>
    </nav>
    """
  end

  attr :to, :string, required: true
  attr :icon, :string, required: true
  attr :label, :string, required: true
  attr :current, :boolean, default: false

  defp intro_link(assigns) do
    ~H"""
    <li>
      <.link
        patch={@to}
        aria-current={@current && "page"}
        class="group flex items-center gap-3 rounded-xl px-3 py-1.5 text-sm text-ink-2 no-underline transition-colors hover:text-ink aria-[current=page]:font-medium aria-[current=page]:text-ink"
      >
        <span class="grid size-7 place-items-center rounded-lg border border-line bg-panel text-muted group-aria-[current=page]:text-learn">
          <.icon name={@icon} class="size-4" />
        </span>
        {@label}
      </.link>
    </li>
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
      class="flex flex-col gap-3"
    >
      <h2 class="m-0 text-sm font-semibold text-ink">On this page</h2>
      <ul class="m-0 flex list-none flex-col gap-0.5 p-0">
        <li :for={{id, label, level} <- @toc}>
          <a
            href={"#" <> id}
            class={[
              "block py-1 text-sm text-muted no-underline transition-colors hover:text-ink aria-[current=location]:font-medium aria-[current=location]:text-ink",
              level == 2 && "pl-3"
            ]}
          >
            {label}
          </a>
        </li>
      </ul>
    </nav>
    """
  end

  attr :title, :string, required: true
  attr :text, :string, default: nil
  attr :eyebrow, :string, default: nil

  defp page_header(assigns) do
    ~H"""
    <header class="flex flex-col gap-3">
      <Panel.eyebrow :if={@eyebrow}>{@eyebrow}</Panel.eyebrow>
      <h1 class="m-0 text-[44px] leading-[1.1] font-bold tracking-[-0.04em] text-learn">{@title}</h1>
      <p :if={@text} class="m-0 max-w-[640px] text-xl leading-relaxed text-muted">{@text}</p>
    </header>
    """
  end

  attr :id, :string, required: true
  attr :title, :string, required: true
  attr :text, :string, default: nil
  slot :inner_block, required: true

  defp section(assigns) do
    ~H"""
    <section id={@id} class="mt-14 flex scroll-mt-24 flex-col gap-4">
      <div class="flex flex-col gap-1.5">
        <h2 class="m-0 text-2xl font-semibold tracking-[-0.02em] text-ink">{@title}</h2>
        <p :if={@text not in [nil, ""]} class="m-0 text-[15px] text-muted">{@text}</p>
      </div>
      {render_slot(@inner_block)}
    </section>
    """
  end

  defp introduction(assigns) do
    assigns =
      assign(assigns,
        components: Catalog.all() |> Enum.flat_map(& &1.modules) |> length()
      )

    ~H"""
    <div id="introduction" class="flex flex-col">
      <.page_header
        title="Introduction"
        text={"#{@components} function components for Phoenix LiveView, over Tailwind, themed by tokens that flip with the light and dark scheme. No other UI kit underneath."}
      />

      <.section id="principles" title="What to expect">
        <ul class="m-0 grid list-none gap-3 p-0 sm:grid-cols-2">
          <.principle title="Tokens, never a hex">
            <code>bg-card</code>, <code>text-muted</code>, <code>border-tag-risk-line</code>: a component has no
            <code>dark:</code>
            variant of its own, the tokens flip.
          </.principle>
          <.principle title="Colour is never alone">
            A tag has its text, a callout a title or an icon, a bar its label.
          </.principle>
          <.principle title="Keyboard first">
            Tabs, combobox, table, board, calendar and menus answer to the arrow keys, Home, End and Esc.
          </.principle>
          <.principle title="The server owns the state">
            Components send one LiveView event (a sort, a move, a pick); they never keep what the server should.
          </.principle>
          <.principle title="Text comes in">
            No Gettext inside: every string is an attribute or a slot, and icons are slots too.
          </.principle>
          <.principle title="Reduced motion">
            Animations stand down under <code>prefers-reduced-motion</code>.
          </.principle>
        </ul>
      </.section>

      <.section id="components" title="Components">
        <div
          :for={{group, topics} <- Catalog.groups()}
          id={"group-" <> slugify(group)}
          class="flex flex-col gap-3 pt-2"
        >
          <Panel.eyebrow>{group}</Panel.eyebrow>
          <div class="grid gap-3 sm:grid-cols-2">
            <.link
              :for={topic <- topics}
              id={"card-" <> topic.slug}
              patch={"/c/#{topic.slug}"}
              class="flex flex-col gap-2 rounded-2xl border border-line bg-panel p-4 no-underline transition-colors hover:border-line-strong hover:bg-wrap/50"
            >
              <span class="font-semibold text-ink">{topic.title}</span>
              <span class="text-sm text-ink-2">{Catalog.summary(topic)}</span>
            </.link>
          </div>
        </div>
      </.section>
    </div>
    """
  end

  attr :title, :string, required: true
  slot :inner_block, required: true

  defp principle(assigns) do
    ~H"""
    <li class="flex flex-col gap-1.5 rounded-2xl border border-line bg-panel p-4">
      <span class="font-semibold text-ink">{@title}</span>
      <span class="text-sm leading-relaxed text-ink-2 [&_code]:rounded [&_code]:bg-wrap [&_code]:px-1 [&_code]:font-mono">
        {render_slot(@inner_block)}
      </span>
    </li>
    """
  end

  defp installation(assigns) do
    assigns =
      assign(assigns,
        dep: @install_dep,
        css: @install_css,
        js: @install_js,
        use: @install_use
      )

    ~H"""
    <div id="installation" class="flex flex-col">
      <.page_header
        title="Installation"
        text="Three edits in a Phoenix app that already has Tailwind v4 and LiveView 1.1 or later."
      />

      <.section id="dependency" title="Dependency" text="In mix.exs.">
        <CodeBlock.code_block tone={:dark} label=".exs" code={@dep} />
      </.section>

      <.section
        id="css"
        title="Tailwind"
        text="One import brings the tokens and tells Tailwind where the components and hooks keep their classes."
      >
        <CodeBlock.code_block tone={:dark} label="assets/css/app.css" code={@css} />
        <p class="m-0 text-sm text-muted">
          Geist and Geist Mono are named in the tokens; the host app serves the font files.
        </p>
      </.section>

      <.section
        id="js"
        title="Hooks"
        text="The components that need the browser (tabs, combobox, table, board, calendar…) bring their hooks."
      >
        <CodeBlock.code_block tone={:dark} label="assets/js/app.js" code={@js} />
      </.section>

      <.section id="use" title="First component">
        <CodeBlock.code_block tone={:dark} lang={:heex} label=".heex" code={@use} />
      </.section>
    </div>
    """
  end

  defp tokens(assigns) do
    assigns = assign(assigns, groups: Tokens.groups(), count: Tokens.count())

    ~H"""
    <div id="tokens" class="flex flex-col">
      <.page_header
        title="Colors"
        text={"#{@count} tokens read from devaction_ui.css. Each is one light-dark() pair: the left swatch is light, the right is dark. Use them as Tailwind colours (bg-card) or variables (var(--card)); a token never needs a dark: variant."}
      />

      <.section :for={{group, tokens} <- @groups} id={"tokens-" <> slugify(group)} title={group}>
        <ul class="m-0 grid list-none grid-cols-1 gap-3 p-0 sm:grid-cols-2">
          <li
            :for={token <- tokens}
            id={"token-" <> token.name}
            class="flex items-center gap-3 rounded-2xl border border-line bg-panel p-3"
          >
            <span class="flex shrink-0 overflow-hidden rounded-xl border border-line-strong">
              <span class="size-11" style={"background: " <> token.light}></span>
              <span class="size-11" style={"background: " <> token.dark}></span>
            </span>
            <span class="flex min-w-0 flex-col">
              <span class="truncate font-mono text-sm text-ink">--{token.name}</span>
              <span class="font-mono text-xs text-muted">{token.light} · {token.dark}</span>
            </span>
          </li>
        </ul>
      </.section>
    </div>
    """
  end

  attr :topic, :map, required: true
  attr :assigns, :map, required: true

  defp topic(assigns) do
    assigns =
      assign(assigns,
        group: Catalog.group_of(assigns.topic),
        neighbours: Catalog.neighbours(assigns.topic),
        examples: TopicHTML.for_topic(assigns.topic.slug)
      )

    ~H"""
    <article id={"topic-" <> @topic.slug} class="flex flex-col">
      <.page_header title={@topic.title} text={Catalog.summary(@topic)} eyebrow={@group} />

      <.section :for={example <- @examples} id={example.id} title={example.title} text={example.text}>
        <.example example={example} assigns={@assigns} />
      </.section>

      <section id="api" class="mt-16 flex scroll-mt-24 flex-col gap-10">
        <h2 class="m-0 border-b border-line pb-3 text-3xl font-bold tracking-[-0.03em] text-ink">
          API reference
        </h2>
        <.api :for={module <- @topic.modules} module={module} />
      </section>

      <footer class="mt-16 flex items-center justify-between gap-4 border-t border-line pt-6">
        <.pager side={:previous} topic={elem(@neighbours, 0)} />
        <.pager side={:next} topic={elem(@neighbours, 1)} />
      </footer>
    </article>
    """
  end

  attr :example, :map, required: true
  attr :assigns, :map, required: true

  defp example(assigns) do
    ~H"""
    <.code_card
      id={"example-" <> @example.id}
      source={@example.source}
      preview_class={["gap-8 p-6 sm:p-10", @example.center? && "items-center"]}
    >
      <:preview>
        {live_render(@assigns.socket, DevactionUISite.ExampleLive,
          id: "live-" <> @example.id,
          session: %{"example" => @example.id}
        )}
      </:preview>
    </.code_card>
    """
  end

  attr :id, :string, required: true
  attr :source, :string, required: true
  attr :preview_class, :any, default: nil
  slot :preview, required: true

  defp code_card(assigns) do
    assigns = assign(assigns, long?: length(String.split(assigns.source, "\n")) > 14)

    ~H"""
    <div id={@id} class="overflow-hidden rounded-2xl border border-line bg-panel">
      <div class={["flex min-h-44 flex-col justify-center", @preview_class]}>
        {render_slot(@preview)}
      </div>

      <div class="relative border-t border-line bg-[#11141F]">
        <div class="flex items-center justify-between px-4 pt-3">
          <span class="font-mono text-xs text-[#A1A1AA]">.heex</span>
          <button
            type="button"
            data-copy-text={@source}
            aria-label="Copy the code"
            class="group grid size-8 place-items-center rounded-lg text-[#A1A1AA] transition-colors hover:bg-white/10 hover:text-white"
          >
            <.icon name="copy-01" class="size-4 group-data-[copied]:hidden" />
            <.icon name="tick-02" class="hidden size-4 text-[#8EF0B4] group-data-[copied]:block" />
          </button>
        </div>

        <div id={"code-" <> @id} class={["overflow-hidden", @long? && "max-h-56"]}>
          <CodeBlock.code_block
            tone={:dark}
            lang={:heex}
            code={@source}
            class="rounded-none! bg-transparent! py-3"
          />
        </div>

        <div :if={@long?}>
          <div
            id={"fade-" <> @id}
            aria-hidden="true"
            class="pointer-events-none absolute inset-x-0 bottom-0 h-24 bg-gradient-to-t from-[#11141F] to-transparent"
          >
          </div>
          <button
            type="button"
            id={"more-" <> @id}
            aria-expanded="false"
            aria-controls={"code-" <> @id}
            phx-click={
              JS.toggle_class("max-h-56", to: "#code-" <> @id)
              |> JS.toggle_class("hidden", to: "#fade-" <> @id)
              |> JS.toggle_class("hidden", to: "#show-" <> @id)
              |> JS.toggle_class("hidden", to: "#hide-" <> @id)
              |> JS.toggle_attribute({"aria-expanded", "true", "false"})
            }
            class="relative z-10 flex w-full items-center justify-center gap-1.5 py-3 text-sm font-medium text-[#E4E4E7] hover:text-white"
          >
            <span id={"show-" <> @id} class="flex items-center gap-1.5">
              Show more <.icon name="arrow-down-01" class="size-4" />
            </span>
            <span id={"hide-" <> @id} class="hidden items-center gap-1.5">
              Show less <.icon name="arrow-up-02" class="size-4" />
            </span>
          </button>
        </div>
      </div>
    </div>
    """
  end

  attr :group, :map, required: true

  defp templates(assigns) do
    assigns = assign(assigns, width: Templates.width(), screens: available_screens(assigns.group))

    ~H"""
    <article id={"templates-" <> @group.slug} class="flex flex-col">
      <.page_header title={@group.title} text={@group.summary} eyebrow="Templates" />

      <.section
        :for={screen <- @screens}
        id={"screen-" <> screen.slug}
        title={screen.title}
        text={screen.text}
      >
        <.code_card
          id={"template-" <> @group.slug <> "-" <> screen.slug}
          source={ScreenHTML.source(@group.slug, screen.slug)}
          preview_class="p-4"
        >
          <:preview>
            <div
              id={"frame-" <> @group.slug <> "-" <> screen.slug}
              phx-hook="SiteFit"
              phx-update="ignore"
              data-width={@width}
              class="relative w-full overflow-hidden rounded-xl border border-line"
              style={"aspect-ratio: #{@width} / #{screen.height}"}
            >
              <iframe
                src={"/screens/#{@group.slug}/#{screen.slug}"}
                title={screen.title}
                loading="lazy"
                class="absolute top-0 left-0 origin-top-left border-0 bg-frame"
                style={"width: #{@width}px; height: #{screen.height}px; transform: scale(var(--fit-scale, 0.5))"}
              ></iframe>
            </div>
            <a
              href={"/screens/#{@group.slug}/#{screen.slug}"}
              target="_blank"
              rel="noopener"
              class="self-end text-sm text-ink-2 hover:text-ink"
            >
              Open full screen ↗
            </a>
          </:preview>
        </.code_card>
      </.section>
    </article>
    """
  end

  attr :side, :atom, required: true
  attr :topic, :map, default: nil

  defp pager(%{topic: nil} = assigns), do: ~H"<span></span>"

  defp pager(assigns) do
    ~H"""
    <.link
      patch={"/c/#{@topic.slug}"}
      id={"pager-#{@side}"}
      class={["flex flex-col gap-0.5 no-underline", @side == :next && "items-end text-right"]}
    >
      <span class="font-mono text-xs tracking-[0.08em] text-muted uppercase">{@side}</span>
      <span class="font-medium text-ink">{@topic.title}</span>
    </.link>
    """
  end

  attr :module, :atom, required: true

  defp api(assigns) do
    assigns =
      assign(assigns,
        short: Reference.short(assigns.module),
        moduledoc: Reference.moduledoc(assigns.module),
        components: Reference.components(assigns.module)
      )

    ~H"""
    <section id={"api-" <> @short} class="flex scroll-mt-24 flex-col gap-6">
      <div class="flex flex-col gap-2">
        <h3 class="m-0 flex flex-wrap items-baseline gap-3 text-2xl font-semibold tracking-[-0.03em] text-ink">
          {@short}
          <span class="font-mono text-sm font-normal text-muted">{inspect(@module)}</span>
        </h3>
        <Doc.markdown text={@moduledoc} />
      </div>

      <div
        :for={component <- @components}
        id={"fn-#{String.downcase(@short)}-#{component.name}"}
        class="flex flex-col gap-4 rounded-2xl border border-line bg-panel p-5"
      >
        <h4 class="m-0 font-mono text-base font-semibold text-ink">
          &lt;{@short}.{component.name}&gt;
        </h4>
        <Doc.markdown text={component.doc} />
        <CodeBlock.code_block
          tone={:dark}
          lang={:heex}
          label="minimal"
          code={Reference.usage(@module, component)}
        />
        <.attr_table :if={component.attrs != []} title="Attributes" rows={component.attrs} />
        <.slot_table :if={component.slots != []} slots={component.slots} />
        <p :for={global <- component.globals} class="m-0 text-sm text-ink-2">
          Any other HTML attribute goes to the root element<span :if={global.include != []}>, including <code class="rounded bg-wrap px-1 font-mono text-[0.9em]">{Enum.join(global.include, ", ")}</code></span>.
        </p>
      </div>
    </section>
    """
  end

  attr :title, :string, required: true
  attr :rows, :list, required: true

  defp attr_table(assigns) do
    ~H"""
    <div class="flex flex-col gap-2">
      <Panel.eyebrow>{@title}</Panel.eyebrow>
      <div class="overflow-x-auto rounded-xl border border-line">
        <table class="w-full border-collapse text-left text-sm">
          <thead>
            <tr class="bg-wrap/60 text-xs tracking-[0.06em] text-muted uppercase">
              <th scope="col" class="px-3 py-2 font-medium">Name</th>
              <th scope="col" class="px-3 py-2 font-medium">Type</th>
              <th scope="col" class="px-3 py-2 font-medium">Default</th>
              <th scope="col" class="px-3 py-2 font-medium">Options and notes</th>
            </tr>
          </thead>
          <tbody>
            <tr :for={row <- @rows} class="border-t border-line-soft align-top">
              <th scope="row" class="px-3 py-2.5 font-mono font-medium text-ink">
                {row.name}
                <Tag.tag :if={row.required} variant={:risk} size={:sm}>required</Tag.tag>
              </th>
              <td class="px-3 py-2.5 font-mono text-ink-2">{Reference.type_label(row.type)}</td>
              <td class="px-3 py-2.5 font-mono text-muted">{Reference.default(row) || "-"}</td>
              <td class="px-3 py-2.5 text-ink-2">
                <div :if={row.values} class="flex flex-wrap gap-1.5 pb-1">
                  <Tag.tag :for={value <- row.values} size={:sm} case={:normal}>
                    {inspect(value)}
                  </Tag.tag>
                </div>
                <Doc.inline :if={row.doc} text={row.doc} />
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
    """
  end

  attr :slots, :list, required: true

  defp slot_table(assigns) do
    ~H"""
    <div class="flex flex-col gap-2">
      <Panel.eyebrow>Slots</Panel.eyebrow>
      <ul class="m-0 flex list-none flex-col gap-2 p-0">
        <li
          :for={slot <- @slots}
          class="flex flex-col gap-1.5 rounded-xl border border-line px-3 py-2.5"
        >
          <span class="flex flex-wrap items-center gap-2">
            <code class="font-mono text-sm font-medium text-ink">:{slot.name}</code>
            <Tag.tag :if={slot.required} variant={:risk} size={:sm}>required</Tag.tag>
          </span>
          <span :if={slot.doc} class="text-sm text-ink-2"><Doc.inline text={slot.doc} /></span>
          <.attr_table :if={slot.attrs != []} title="Slot attributes" rows={slot.attrs} />
        </li>
      </ul>
    </div>
    """
  end

  defp available_screens(group),
    do: Enum.filter(group.screens, &ScreenHTML.source(group.slug, &1.slug))

  defp slugify(text), do: text |> String.downcase() |> String.replace(~r/[^a-z0-9]+/, "-")
end
