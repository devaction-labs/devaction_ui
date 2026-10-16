defmodule DevactionUI.Shell do
  @moduledoc """
  The frame of an app: a sidebar that collapses to a rail, a header and a panel with the page. `⌘B` (or Ctrl+B)
  and the toggle button switch the sidebar between open (248px) and a rail of icons (60px) whose items show their
  name on hover; below 1024px the sidebar is a drawer over the page, closed by the backdrop, Esc or following a
  link. The choice is kept in the `dui_sidebar` cookie, so `DevactionUI.Shell.SidebarCookie` and `on_mount/4`
  render it right on the first paint (`sidebar_open`); the open or closed state of each group is kept in the
  local storage. The hook is `DevactionUI.Shell` and the shell tells LiveView to leave its own attributes alone,
  so a patch does not undo what the person chose.

  `variant` is the layout: `"classic"` (a sidebar beside the panel), `"topbar"` (the sidebar becomes a bar on top),
  `"split"` (a `list` column between the sidebar and the panel, for list and detail), `"centered"` (the page in a
  narrow centred column) and `"docs"` (a `toc` column at the end). `content_width="read"` limits the page to the
  reading width. The shell is as tall as the screen; to put it in a box, set `--shell-h` (`style="--shell-h: 460px"`).

  The slots are `sidebar` (built from `sidebar_head/1`, `sidebar_search/1`, `sidebar_nav/1`, `sidebar_group/1`,
  `sidebar_item/1`, `sidebar_foot/1` and `sidebar_user/1`), `header` (usually a `DevactionUI.Breadcrumb`), `header_actions`, `list`, `toc`, and the
  page itself. A shell with a `sidebar` needs `sidebar_label`, `open_label` and `close_label` (the toggle button
  says which one by its state); without them it raises, so the library carries no language of its own. The
  toggle's icon is the `toggle_icon` slot.

      <Shell.shell
        id="app"
        sidebar_open={@sidebar_open}
        sidebar_label="Main"
        open_label="Open menu"
        close_label="Collapse menu"
      >
        <:sidebar>
          <Shell.sidebar_head name="Acme" subtitle="Workspace"><:logo>A</:logo></Shell.sidebar_head>
          <Shell.sidebar_nav>
            <Shell.sidebar_item tip="Projects" navigate="/projects" current>Projects</Shell.sidebar_item>
          </Shell.sidebar_nav>
        </:sidebar>
        <:header><Breadcrumb.breadcrumb label="You are here" items={[%{label: "Projects"}]} /></:header>
        The page.
      </Shell.shell>
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  @doc """
  The `on_mount` that puts `@sidebar_open` in every LiveView of a `live_session`, from the session value
  `DevactionUI.Shell.SidebarCookie` wrote.
  """
  @spec on_mount(:sidebar, map(), map(), Phoenix.LiveView.Socket.t()) ::
          {:cont, Phoenix.LiveView.Socket.t()}
  def on_mount(:sidebar, _params, session, socket),
    do: {:cont, assign(socket, :sidebar_open, Map.get(session, "sidebar_open", true))}

  attr :id, :string, default: "shell"
  attr :variant, :string, default: "classic", values: ~w(classic topbar split centered docs)

  attr :sidebar_open, :boolean,
    default: true,
    doc: "the state the server renders; the browser keeps what the person chose after that"

  attr :sidebar_label, :string, default: nil, doc: "names the sidebar for assistive technology"
  attr :open_label, :string, default: nil, doc: "the toggle button when the sidebar is collapsed"
  attr :close_label, :string, default: nil, doc: "the toggle button when the sidebar is open"
  attr :content_width, :string, default: nil, values: [nil, "read"]
  attr :class, :any, default: nil
  attr :rest, :global

  slot :sidebar
  slot :header
  slot :header_actions
  slot :list, doc: "the middle column of the `split` variant"
  slot :toc, doc: "the page index of the `docs` variant"
  slot :toggle_icon, doc: "the icon of the toggle button; a typographic glyph when empty"
  slot :inner_block, required: true

  @doc "The shell: sidebar, header and panel."
  @spec shell(map()) :: Phoenix.LiveView.Rendered.t()
  def shell(%{sidebar: [_ | _], sidebar_label: nil}),
    do: raise(ArgumentError, "shell: a sidebar needs a `sidebar_label`")

  def shell(%{sidebar: [_ | _], open_label: nil}),
    do: raise(ArgumentError, "shell: a sidebar needs an `open_label` and a `close_label`")

  def shell(%{sidebar: [_ | _], close_label: nil}),
    do: raise(ArgumentError, "shell: a sidebar needs an `open_label` and a `close_label`")

  def shell(assigns) do
    ~H"""
    <div
      id={@id}
      class={["shell", @class]}
      data-variant={@variant}
      data-sidebar={state(@sidebar_open)}
      phx-hook="DevactionUI.Shell"
      phx-mounted={JS.ignore_attributes(["data-sidebar", "data-mobile-open"])}
      {@rest}
    >
      <aside
        :if={@sidebar != []}
        id={"#{@id}-sidebar"}
        class="shell-sidebar"
        aria-label={@sidebar_label}
      >
        {render_slot(@sidebar)}
      </aside>
      <div :if={@sidebar != []} class="shell-backdrop" data-sidebar-backdrop></div>
      <aside :if={@list != []} class="shell-list">{render_slot(@list)}</aside>
      <main class="shell-panel">
        <header class="shell-header">
          <button
            :if={@sidebar != []}
            type="button"
            class="shell-icon-btn"
            data-sidebar-toggle
            aria-controls={"#{@id}-sidebar"}
            aria-expanded={to_string(@sidebar_open)}
            aria-label={toggle_label(@sidebar_open, @open_label, @close_label)}
            aria-keyshortcuts="Meta+B Control+B"
            data-label-open={@open_label}
            data-label-close={@close_label}
            phx-mounted={JS.ignore_attributes(["aria-expanded", "aria-label"])}
          >
            {(@toggle_icon != [] && render_slot(@toggle_icon)) || "≡"}
          </button>
          <span :if={@sidebar != []} class="shell-divider" aria-hidden="true"></span>
          {render_slot(@header)}
          <div :if={@header_actions != []} class="shell-header-actions">
            {render_slot(@header_actions)}
          </div>
        </header>
        <div class="shell-content" data-width={@content_width}>{render_slot(@inner_block)}</div>
      </main>
      <aside :if={@toc != []} class="shell-toc">{render_slot(@toc)}</aside>
    </div>
    """
  end

  defp state(true), do: "open"
  defp state(false), do: "rail"

  defp toggle_label(true, _open, close), do: close
  defp toggle_label(false, open, _close), do: open

  attr :name, :string, required: true
  attr :subtitle, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :logo, required: true, doc: "the mark of the workspace, 30px"
  slot :menu, doc: "a button at the end, such as a workspace switcher; hidden in the rail"

  @doc "The head of the sidebar: the workspace. The text goes away in the rail."
  @spec sidebar_head(map()) :: Phoenix.LiveView.Rendered.t()
  def sidebar_head(assigns) do
    ~H"""
    <div class={["sidebar-head", @class]} {@rest}>
      <span class="sidebar-logo">{render_slot(@logo)}</span>
      <span class="sidebar-head-text">
        <span class="sidebar-head-name">{@name}</span>
        <span :if={@subtitle} class="sidebar-head-sub">{@subtitle}</span>
      </span>
      <span :if={@menu != []} class="sidebar-head-menu">{render_slot(@menu)}</span>
    </div>
    """
  end

  attr :class, :any, default: nil
  attr :rest, :global

  slot :inner_block,
    required: true,
    doc: "a search field, such as an `InputGroup` with a `⌘K` hint"

  @doc "A row under the head for a search field; it goes away in the rail."
  @spec sidebar_search(map()) :: Phoenix.LiveView.Rendered.t()
  def sidebar_search(assigns) do
    ~H"""
    <div class={["sidebar-search", @class]} {@rest}>{render_slot(@inner_block)}</div>
    """
  end

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc "The scrolling list of the sidebar's groups and items."
  @spec sidebar_nav(map()) :: Phoenix.LiveView.Rendered.t()
  def sidebar_nav(assigns) do
    ~H"""
    <nav class={["sidebar-nav", @class]} {@rest}>{render_slot(@inner_block)}</nav>
    """
  end

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc "The foot of the sidebar: settings, the account."
  @spec sidebar_foot(map()) :: Phoenix.LiveView.Rendered.t()
  def sidebar_foot(assigns) do
    ~H"""
    <div class={["sidebar-foot", @class]} {@rest}>{render_slot(@inner_block)}</div>
    """
  end

  attr :name, :string, required: true
  attr :email, :string, required: true
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(navigate patch href method)
  slot :avatar, required: true, doc: "the person's avatar, 32px"
  slot :icon, doc: "the end of the card, such as a chevron; it goes away in the rail"

  @doc "The account card at the foot of the sidebar: avatar, name and e-mail. Only the avatar stays in the rail."
  @spec sidebar_user(map()) :: Phoenix.LiveView.Rendered.t()
  def sidebar_user(assigns) do
    ~H"""
    <.link class={["sidebar-user", @class]} aria-label={@name} {@rest}>
      <span class="sidebar-user-avatar">{render_slot(@avatar)}</span>
      <span class="sidebar-user-text">
        <span class="sidebar-user-name">{@name}</span>
        <span class="sidebar-user-email">{@email}</span>
      </span>
      <span :if={@icon != []} class="sidebar-user-icon" aria-hidden="true">
        {render_slot(@icon)}
      </span>
    </.link>
    """
  end

  attr :id, :string, required: true, doc: "also the key the open state is kept under"
  attr :label, :string, required: true
  attr :open, :boolean, default: true
  attr :class, :any, default: nil
  attr :rest, :global
  slot :icon, doc: "the chevron of the heading; it turns when the group closes"
  slot :inner_block, required: true

  @doc """
  A group of items under a heading that collapses. In the rail the heading goes and the group is a block
  between two lines.
  """
  @spec sidebar_group(map()) :: Phoenix.LiveView.Rendered.t()
  def sidebar_group(assigns) do
    ~H"""
    <div
      class={["sidebar-group", @class]}
      data-sidebar-group={@id}
      data-collapsed={!@open && ""}
      phx-mounted={JS.ignore_attributes(["data-collapsed"])}
      {@rest}
    >
      <button
        type="button"
        class="sidebar-group-toggle"
        data-group-toggle
        aria-expanded={to_string(@open)}
        aria-controls={"#{@id}-group"}
        phx-mounted={JS.ignore_attributes(["aria-expanded"])}
      >
        {@label}
        <span class="sidebar-group-chevron" aria-hidden="true">
          {(@icon != [] && render_slot(@icon)) || "▾"}
        </span>
      </button>
      <div
        id={"#{@id}-group"}
        class="sidebar-group-body"
        data-group-body
        hidden={!@open}
        phx-mounted={JS.ignore_attributes(["hidden"])}
      >
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  attr :tip, :string,
    required: true,
    doc: "the name of the item in the rail, where the text is hidden; also its accessible name"

  attr :current, :boolean, default: false
  attr :badge, :any, default: nil
  attr :badge_tone, :string, default: nil, values: [nil, "ai"]

  attr :dot, :boolean,
    default: false,
    doc: "marks the item in the rail, such as a PR with a block"

  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(navigate patch href method)
  slot :icon, doc: "the 18px icon"
  slot :inner_block, required: true
  slot :sub, doc: "indented items under this one, with a line on the left"

  @doc "An item of the sidebar: a link to `navigate`, `patch` or `href`."
  @spec sidebar_item(map()) :: Phoenix.LiveView.Rendered.t()
  def sidebar_item(assigns) do
    ~H"""
    <.link
      class={["sidebar-item", @class]}
      aria-current={@current && "page"}
      aria-label={@tip}
      data-tip={@tip}
      data-dot={@dot && ""}
      {@rest}
    >
      <span :if={@icon != []} class="sidebar-icon" aria-hidden="true">{render_slot(@icon)}</span>
      <span class="sidebar-label">{render_slot(@inner_block)}</span>
      <span :if={@badge} class="sidebar-item-badge" data-tone={@badge_tone}>{@badge}</span>
    </.link>
    <div :if={@sub != []} class="sidebar-sub">{render_slot(@sub)}</div>
    """
  end
end
