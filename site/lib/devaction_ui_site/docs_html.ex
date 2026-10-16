defmodule DevactionUISite.DocsHTML do
  @moduledoc """
  The pages of the documentation: the top bar, the sidebar by category, the content (introduction,
  installation, colour tokens, a component with its examples and API) and the "On this page" index.
  """
  use Phoenix.Component

  import DevactionUISite.Icon

  alias DevactionUI.{CodeBlock, Panel, Tag}

  alias DevactionUISite.{
    Catalog,
    ChangelogHTML,
    Doc,
    HomeHTML,
    Project,
    Reference,
    ScreenHTML,
    Shell,
    Templates,
    Tokens,
    TopicHTML
  }

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
          class="flex flex-col gap-8 rounded-2xl border border-line bg-card p-8"
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

  def page(%{live_action: :home} = assigns) do
    ~H"""
    <Shell.shell page={assigns} sidebar={false}>
      <HomeHTML.page {assigns} />
    </Shell.shell>
    """
  end

  def page(%{live_action: :changelog} = assigns) do
    ~H"""
    <Shell.shell page={assigns} sidebar={false}>
      <ChangelogHTML.page {assigns} />
    </Shell.shell>
    """
  end

  def page(assigns) do
    assigns = assign(assigns, toc: toc(assigns), toc_key: toc_key(assigns))

    ~H"""
    <Shell.shell page={assigns} toc={@toc} toc_key={@toc_key}>
      <.content live_action={@live_action} topic={@topic} page_assigns={assigns} />
      <:rail :if={@live_action == :topic}>
        <.history_cards />
      </:rail>
    </Shell.shell>
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

  defp toc_key(%{live_action: :topic, topic: topic}), do: "topic-" <> topic.slug
  defp toc_key(%{live_action: :templates, template_group: group}), do: "templates-" <> group.slug
  defp toc_key(%{live_action: action}), do: Atom.to_string(action)

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

    api = [{"api", "API reference", 1}]

    accessibility =
      for _note <- Enum.take(Enum.flat_map(topic.modules, &Reference.accessibility/1), 1),
          do: {"accessibility", "Accessibility", 1}

    examples ++ api ++ accessibility
  end

  attr :title, :string, required: true
  attr :text, :string, default: nil
  attr :eyebrow, :string, default: nil

  defp page_header(assigns) do
    ~H"""
    <header class="flex flex-col gap-2.5">
      <Panel.eyebrow :if={@eyebrow}>{@eyebrow}</Panel.eyebrow>
      <h1 class="m-0 text-[40px] leading-[1.1] font-semibold tracking-[-0.03em] text-ink">
        {@title}
      </h1>
      <p :if={@text} class="m-0 max-w-[680px] text-[17px] leading-[1.55] text-soft">{@text}</p>
    </header>
    """
  end

  attr :id, :string, required: true
  attr :title, :string, required: true
  attr :text, :string, default: nil
  slot :inner_block, required: true

  defp section(assigns) do
    ~H"""
    <section id={@id} class="mt-11 flex scroll-mt-24 flex-col gap-4">
      <div class="flex flex-col gap-1.5">
        <h2 class="m-0 text-[22px] font-semibold tracking-[-0.015em] text-ink">{@title}</h2>
        <p :if={@text not in [nil, ""]} class="m-0 text-[15px] text-soft">{@text}</p>
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
              class="flex flex-col gap-2 rounded-2xl border border-line bg-card p-4 no-underline transition-colors hover:border-line-strong hover:bg-wrap/50"
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
    <li class="flex flex-col gap-1.5 rounded-2xl border border-line bg-card p-4">
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
            class="flex items-center gap-3 rounded-2xl border border-line bg-card p-3"
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
        examples: TopicHTML.for_topic(assigns.topic.slug),
        alias_line: "alias " <> inspect(hd(assigns.topic.modules)),
        source_url: Project.source_url(hd(assigns.topic.modules)),
        accessibility: Enum.flat_map(assigns.topic.modules, &Reference.accessibility/1)
      )

    ~H"""
    <article id={"topic-" <> @topic.slug} class="flex flex-col [line-height:normal]">
      <nav aria-label="Breadcrumb">
        <ol class="m-0 flex list-none items-center gap-2 p-0 text-[13px] text-muted">
          <li>
            <.link patch="/docs#components" class="text-muted no-underline hover:text-ink">
              Components
            </.link>
          </li>
          <li aria-hidden="true">/</li>
          <li>{@group}</li>
          <li aria-hidden="true">/</li>
          <li aria-current="page" class="text-ink">{@topic.title}</li>
        </ol>
      </nav>

      <div class="mt-3.5 flex flex-wrap items-center gap-3">
        <h1 class="m-0 text-[40px] [line-height:normal] font-semibold tracking-[-0.03em] text-ink">
          {@topic.title}
        </h1>
        <Tag.tag variant={:ok} class="h-[26px]! rounded-[7px]! px-2! py-0! tracking-normal!">
          Stable
        </Tag.tag>
        <Tag.tag
          variant={:neutral}
          surface={:plain}
          case={:normal}
          class="h-[26px]! rounded-[7px]! border-line! px-2! py-0! text-soft!"
        >
          since v{Catalog.since(@topic)}
        </Tag.tag>
      </div>

      <p class="m-0 mt-2.5 max-w-[680px] text-[17px] leading-[1.55] text-soft">
        {Catalog.summary(@topic)}
      </p>

      <div class="mt-[18px] flex flex-wrap gap-2 text-[13px]">
        <span class="inline-flex h-[34px] items-center gap-2 rounded-lg border border-line bg-card px-2.5 font-mono text-ink-2">
          {@alias_line}
          <button
            type="button"
            data-copy-text={@alias_line}
            aria-label="Copy the alias"
            class="group relative grid size-3.5 cursor-pointer place-items-center rounded text-muted after:absolute after:-inset-1.5 after:content-[''] hover:text-ink"
          >
            <.icon name="copy-01" class="size-3.5 group-data-[copied]:hidden" />
            <.icon name="tick-02" class="hidden size-3.5 text-tag-ok-text group-data-[copied]:block" />
          </button>
        </span>
        <a
          href={@source_url}
          target="_blank"
          rel="noopener"
          class="inline-flex h-[34px] items-center gap-2 rounded-lg border border-line bg-card px-2.5 text-ink-2 no-underline hover:text-ink"
        >
          <.icon name="source-code" class="size-3.5" /> Source code
        </a>
        <.link
          patch="/changelog"
          class="inline-flex h-[34px] items-center gap-2 rounded-lg border border-line bg-card px-2.5 text-ink-2 no-underline hover:text-ink"
        >
          <.history_icon class="size-3.5 shrink-0" /> History
        </.link>
      </div>

      <.section :for={example <- @examples} id={example.id} title={example.title} text={example.text}>
        <.example example={example} assigns={@assigns} />
      </.section>

      <section id="api" class="mt-[52px] scroll-mt-24">
        <h2 class="m-0 text-[22px] font-semibold tracking-[-0.015em] text-ink">API</h2>
        <.api
          :for={module <- @topic.modules}
          module={module}
          heading={length(@topic.modules) > 1}
        />
      </section>

      <section
        :if={@accessibility != []}
        id="accessibility"
        class="mt-11 flex scroll-mt-24 flex-col gap-3.5"
      >
        <h2 class="m-0 text-[22px] font-semibold tracking-[-0.015em] text-ink">Accessibility</h2>
        <ul class="m-0 grid list-none gap-3 p-0 sm:grid-cols-2">
          <li
            :for={note <- @accessibility}
            class="flex gap-2.5 rounded-xl border border-line bg-card px-4 py-3.5 text-sm leading-normal text-ink-2"
          >
            <.icon name="checkmark-circle-02" class="mt-px size-[18px] text-tag-ok-text" />
            <span><Doc.inline text={note} /></span>
          </li>
        </ul>
      </section>

      <footer class="mt-[52px] grid gap-3 sm:grid-cols-2">
        <.pager side={:previous} topic={elem(@neighbours, 0)} />
        <.pager side={:next} topic={elem(@neighbours, 1)} />
      </footer>
    </article>
    """
  end

  defp history_cards(assigns) do
    ~H"""
    <div class="flex flex-col gap-4">
      <section aria-labelledby="history-title">
        <h2
          id="history-title"
          class="m-0 font-mono text-[11px] font-normal tracking-[0.08em] text-muted uppercase"
        >
          History
        </h2>
        <div class="mt-2.5 rounded-xl border border-line bg-card p-3">
          <p class="m-0 flex items-center gap-2 text-ink-2">
            <Tag.tag variant={:ok} size={:sm} case={:normal} class="rounded-[5px]! px-1.5!">
              v{Project.short_version()}
            </Tag.tag>
            Component created
          </p>
          <.link patch="/changelog" class="mt-2.5 block text-soft underline hover:text-ink">
            See in the changelog →
          </.link>
        </div>
      </section>
      <p class="m-0 rounded-xl border border-line bg-card p-3 leading-normal text-soft">
        Found a problem?
        <a href={Project.issues_url()} target="_blank" rel="noopener" class="text-ink underline">
          Open an issue on GitHub
        </a>
      </p>
    </div>
    """
  end

  @history_path "M11.0065 21H9.60546C6.02021 21 4.22759 21 3.11379 19.865C2 18.7301 2 16.9034 2 13.25C2 9.59661 2 7.76992 3.11379 6.63496C4.22759 5.5 6.02021 5.5 9.60546 5.5H13.4082C16.9934 5.5 18.7861 5.5 19.8999 6.63496C20.7568 7.50819 20.9544 8.7909 21 11 M18.85 18.85L17.5 17.95V15.7M13 17.5C13 19.9853 15.0147 22 17.5 22C19.9853 22 22 19.9853 22 17.5C22 15.0147 19.9853 13 17.5 13C15.0147 13 13 15.0147 13 17.5Z M16 5.5L15.9007 5.19094C15.4056 3.65089 15.1581 2.88087 14.5689 2.44043C13.9796 2 13.197 2 11.6316 2H11.3684C9.80304 2 9.02036 2 8.43111 2.44043C7.84186 2.88087 7.59436 3.65089 7.09934 5.19094L7 5.5"

  defp history_path, do: @history_path

  attr :class, :string, default: nil

  defp history_icon(assigns) do
    ~H"""
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="1.5"
      stroke-linecap="round"
      stroke-linejoin="round"
      aria-hidden="true"
      class={@class}
    >
      <path d={history_path()} />
    </svg>
    """
  end

  attr :example, :map, required: true
  attr :assigns, :map, required: true

  defp example(assigns) do
    ~H"""
    <.code_card
      id={"example-" <> @example.id}
      source={@example.source}
      preview_class={[
        "flex-col justify-center gap-8 p-6 sm:p-8",
        @example.center? && "items-center"
      ]}
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
  attr :theme_switch, :boolean, default: true
  slot :preview, required: true

  defp code_card(assigns) do
    ~H"""
    <div id={@id} class="overflow-hidden rounded-2xl border border-line bg-card">
      <div
        role="tablist"
        aria-label="View"
        class="flex h-[45px] items-center gap-1 border-b border-cp-line pr-2 pl-3"
      >
        <button
          id={"tab-preview-" <> @id}
          type="button"
          role="tab"
          aria-selected="true"
          aria-controls={"pv-" <> @id}
          phx-click={show_panel(@id, :preview)}
          class={tab_class()}
        >
          Preview
        </button>
        <button
          id={"tab-code-" <> @id}
          type="button"
          role="tab"
          aria-selected="false"
          aria-controls={"code-" <> @id}
          phx-click={show_panel(@id, :code)}
          class={tab_class()}
        >
          HEEx
        </button>

        <span class="ml-auto flex gap-1">
          <button
            :if={@theme_switch}
            id={"theme-" <> @id}
            type="button"
            aria-pressed="false"
            aria-label="Preview this example in the other theme"
            phx-click={flip_preview_theme(@id)}
            class="group/theme inline-flex h-8 cursor-pointer items-center rounded-lg border border-line bg-card px-2.5 text-[12px] text-ink-2 hover:text-ink"
          >
            <span class="inline-flex items-center gap-1.5 group-aria-pressed/theme:hidden">
              <.icon name="sun-03" class="size-3.5" /> Light
            </span>
            <span class="hidden items-center gap-1.5 group-aria-pressed/theme:inline-flex">
              <.icon name="moon-02" class="size-3.5" /> Dark
            </span>
          </button>
          <button
            type="button"
            data-copy-text={@source}
            aria-label="Copy the code"
            class="group grid size-8 cursor-pointer place-items-center rounded-lg border border-line bg-card text-ink-2 hover:text-ink"
          >
            <.icon name="copy-01" class="size-3.5 group-data-[copied]:hidden" />
            <.icon name="tick-02" class="hidden size-3.5 text-tag-ok-text group-data-[copied]:block" />
          </button>
        </span>
      </div>

      <div
        id={"pv-" <> @id}
        role="tabpanel"
        aria-labelledby={"tab-preview-" <> @id}
        data-flip="false"
        class={["site-pv flex min-h-[234px]", @preview_class]}
      >
        {render_slot(@preview)}
      </div>

      <div
        id={"code-" <> @id}
        role="tabpanel"
        aria-labelledby={"tab-code-" <> @id}
        class="hidden max-h-[28rem] overflow-auto bg-code"
      >
        <CodeBlock.code_block
          tone={:dark}
          lang={:heex}
          code={@source}
          class="rounded-none! bg-transparent! px-[22px]! py-5! leading-[1.75]!"
        />
      </div>
    </div>
    """
  end

  defp tab_class,
    do:
      "h-8 cursor-pointer rounded-lg border border-transparent px-2.5 text-[13px] font-medium text-muted aria-selected:border-line aria-selected:bg-wrap aria-selected:text-ink"

  defp show_panel(id, :preview) do
    JS.remove_class("hidden", to: "#pv-" <> id)
    |> JS.add_class("hidden", to: "#code-" <> id)
    |> JS.set_attribute({"aria-selected", "true"}, to: "#tab-preview-" <> id)
    |> JS.set_attribute({"aria-selected", "false"}, to: "#tab-code-" <> id)
  end

  defp show_panel(id, :code) do
    JS.add_class("hidden", to: "#pv-" <> id)
    |> JS.remove_class("hidden", to: "#code-" <> id)
    |> JS.set_attribute({"aria-selected", "false"}, to: "#tab-preview-" <> id)
    |> JS.set_attribute({"aria-selected", "true"}, to: "#tab-code-" <> id)
  end

  defp flip_preview_theme(id) do
    JS.toggle_attribute({"data-flip", "true", "false"}, to: "#pv-" <> id)
    |> JS.toggle_attribute({"aria-pressed", "true", "false"}, to: "#theme-" <> id)
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
          preview_class="flex-col gap-3 p-4"
          theme_switch={false}
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
      class={[
        "flex flex-col gap-1 rounded-[14px] border border-line bg-card px-[18px] py-4 no-underline hover:border-line-strong",
        @side == :next && "text-right"
      ]}
    >
      <span class="text-[12px] text-muted">{pager_label(@side)}</span>
      <span class="text-[15px] font-medium text-ink">{@topic.title}</span>
    </.link>
    """
  end

  defp pager_label(:previous), do: "← Previous"
  defp pager_label(:next), do: "Next →"

  attr :module, :atom, required: true
  attr :heading, :boolean, default: false

  defp api(assigns) do
    assigns =
      assign(assigns,
        short: Reference.short(assigns.module),
        moduledoc: Reference.moduledoc(assigns.module),
        components: Reference.components(assigns.module)
      )

    ~H"""
    <div id={"api-" <> @short} class="mt-8 scroll-mt-24 first-of-type:mt-0">
      <div :if={@heading} class="mb-4 flex flex-col gap-2">
        <h3 class="m-0 flex flex-wrap items-baseline gap-3 text-2xl font-semibold tracking-[-0.03em] text-ink">
          {@short}
          <span class="font-mono text-sm font-normal text-muted">{inspect(@module)}</span>
        </h3>
        <Doc.markdown text={@moduledoc} />
      </div>
      <.component_reference
        :for={component <- @components}
        module={@module}
        short={@short}
        component={component}
      />
    </div>
    """
  end

  attr :module, :atom, required: true
  attr :short, :string, required: true
  attr :component, :map, required: true

  defp component_reference(assigns) do
    assigns =
      assign(assigns,
        required_slots: for(slot <- assigns.component.slots, slot.required, do: slot.name),
        rows: api_rows(assigns.component)
      )

    ~H"""
    <section
      id={"fn-#{String.downcase(@short)}-#{@component.name}"}
      class="mt-8 scroll-mt-24 first-of-type:mt-0"
    >
      <p
        :for={global <- @component.globals}
        class="m-0 mt-1.5 text-[15px] [line-height:normal] text-soft"
      >
        Other HTML attributes<span :if={global.include != []}> (<code class="font-mono text-[13px]">{Enum.join(global.include, ", ")}</code>)</span>
        pass straight to the root element.
      </p>
      <div class="mt-4 overflow-hidden rounded-[14px] border border-line bg-card">
        <div class="flex items-center gap-2.5 border-b border-cp-line px-4 py-3 font-mono text-[13px]">
          &lt;{@short}.{@component.name}&gt;
          <span :if={@required_slots != []} class="ml-auto font-sans text-xs text-muted">
            required slot: {Enum.join(@required_slots, ", ")}
          </span>
        </div>
        <div
          :if={@component.doc not in [nil, ""]}
          class="border-b border-cp-line px-4 py-3 text-[14px] leading-normal text-ink-2"
        >
          <Doc.markdown text={@component.doc} />
        </div>
        <div :if={@rows != []} class="overflow-x-auto">
          <table class="w-full min-w-[640px] table-fixed border-collapse text-left">
            <caption class="sr-only">
              Attributes of {@short}.{@component.name}
            </caption>
            <colgroup>
              <col class="w-[156px]" />
              <col class="w-[220px]" />
              <col class="w-[110px]" />
              <col />
            </colgroup>
            <thead>
              <tr class="bg-cp-th font-mono text-[11px] tracking-[0.05em] text-muted uppercase">
                <th scope="col" class="py-2.5 pl-4 text-left font-normal">Attribute</th>
                <th scope="col" class="py-2.5 text-left font-normal">Type</th>
                <th scope="col" class="py-2.5 text-left font-normal">Default</th>
                <th scope="col" class="py-2.5 pr-4 text-left font-normal">Options and notes</th>
              </tr>
            </thead>
            <tbody>
              <tr :for={row <- @rows} class="border-t border-cp-line align-baseline text-[14px]">
                <th
                  scope="row"
                  class="py-3 pl-4 text-left font-mono text-[13px] font-medium break-words text-ink"
                >
                  {row.name}<abbr
                    :if={row.required}
                    title="required"
                    class="text-tag-risk-text no-underline"
                  >*</abbr>
                </th>
                <td class="py-3 pr-2 font-mono text-xs break-words text-cp-type">{row.type}</td>
                <td class="py-3 pr-2 font-mono text-xs break-words text-soft">{row.default}</td>
                <td class="py-3 pr-4 leading-normal text-ink-2">
                  <Doc.inline :if={row.doc} text={row.doc} />
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </section>
    """
  end

  defp api_rows(component) do
    Enum.map(component.attrs, &attr_row(&1, nil)) ++
      Enum.flat_map(Enum.reject(component.slots, &inner_block?/1), &slot_rows/1)
  end

  defp inner_block?(%{name: :inner_block, required: true}), do: true
  defp inner_block?(_slot), do: false

  defp slot_rows(slot) do
    [
      %{name: ":#{slot.name}", required: slot.required, type: "slot", default: "-", doc: slot.doc}
      | Enum.map(slot.attrs, &attr_row(&1, slot.name))
    ]
  end

  defp attr_row(attr, slot) do
    %{
      name: attr_name(attr.name, slot),
      required: attr.required,
      type: type_text(attr),
      default: Reference.default(attr) || "-",
      doc: attr.doc
    }
  end

  defp attr_name(name, nil), do: to_string(name)
  defp attr_name(name, slot), do: ":#{slot}.#{name}"

  defp type_text(%{values: [_ | _] = values}), do: Enum.map_join(values, " | ", &inspect/1)
  defp type_text(attr), do: Reference.type_label(attr.type)

  defp available_screens(group),
    do: Enum.filter(group.screens, &ScreenHTML.source(group.slug, &1.slug))

  defp slugify(text), do: text |> String.downcase() |> String.replace(~r/[^a-z0-9]+/, "-")
end
