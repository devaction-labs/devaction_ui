defmodule DevactionUI.CommandPalette do
  @moduledoc """
  The ⌘K palette as a library piece: a dialog near the top with a large field, an optional row of scopes
  (all, pull requests, tasks...), the results in groups with their hints, an "ask the AI" action with the typed
  text and a footer that teaches the keys. ↑ ↓ move the active row, ↵ opens it, ⌘↵ asks the AI and Esc closes it.

  The server owns the search, as in `DevactionUI.Autocomplete` (whose keyboard hook it shares and whose `groups`
  it takes). The LiveView decides when it is there (`:if={@open}`); it takes the focus in and keeps it inside.
  The library has no hook for the global ⌘K that opens it: the app listens for the key (a `phx-window-keydown`
  or a small hook) and sets the assign. To get the focus back where it was, the opener runs `JS.push_focus()`
  before it opens the palette; closing it runs `JS.pop_focus()`.

  A group is `%{label: "Pull requests", items: [item]}` and an item is
  `%{id: "p1", label: "Wrap tithes", to: "/pr/1", hint: "#1", tone: :risk, sub: "main", shortcut: "G P"}`.
  A row goes where `to` (a LiveView navigation), `patch` or `href` says, or sends `event` with the item's `id`
  (a command, such as "create a contract"). `hint` is a small mono badge colored by `tone`, `sub` is a second
  line under the label and `shortcut` is the key cap of the item at the right (the `↵` otherwise appears on the
  active row). The `item_icon` slot draws a 28px tile with the item's icon and gets the item. Each group is a
  `role="group"` named by its label, and the active row has `aria-selected`; the field's `aria-expanded` is
  false when there is no row at all.
  """
  use Phoenix.Component

  import DevactionUI.Kbd
  import DevactionUI.Segmented

  alias DevactionUI.Autocomplete
  alias Phoenix.LiveView.JS

  attr :id, :string, required: true
  attr :label, :string, required: true, doc: "the name of the dialog, for assistive technology"
  attr :query, :string, default: "", doc: "the text in the field, kept by the caller"
  attr :placeholder, :string, default: nil
  attr :search_event, :string, required: true, doc: "sent with the text, debounced"
  attr :debounce, :integer, default: 150, doc: "milliseconds the field waits before sending"
  attr :close_event, :string, required: true

  attr :groups, :list,
    default: [],
    doc: "`%{label, items: [%{id, label, to | patch | href | event, hint, tone, sub, shortcut}]}`"

  attr :empty, :string, required: true, doc: "shown, centered, when there is no row"
  attr :ask_label, :string, default: nil, doc: "the text of the AI row; no row when nil"
  attr :ask_event, :string, default: nil, doc: "the event the AI row sends with the text, as `q`"

  attr :ask_kbd, :string,
    default: nil,
    doc: "the key of the AI row, as a key cap: `⌘↵`; none when nil"

  attr :close_key, :string,
    default: "Esc",
    doc: "the key cap at the end of the field; none when nil"

  attr :scopes, :list, default: [], doc: "`%{value, label}` each; none draws no row"
  attr :scope, :string, default: nil, doc: "the `value` of the chosen scope"
  attr :scope_event, :string, default: nil, doc: "sent with the `value` of the scope pressed"

  attr :scope_label, :string,
    default: nil,
    doc: "the name of the scopes, for assistive technology"

  attr :keys, :list, default: [], doc: "`{keys, what}` for the footer: `{\"↑↓\", \"move\"}`"
  slot :search_icon
  slot :item_icon, doc: "the icon in the tile of an item; gets the item"

  attr :rest, :global

  @spec palette(map()) :: Phoenix.LiveView.Rendered.t()
  def palette(assigns) do
    assigns = assign(assigns, :expanded, assigns.groups != [] or assigns.ask_label != nil)

    ~H"""
    <div
      id={@id}
      phx-hook="DevactionUI.Autocomplete"
      class="fixed inset-0 z-50 flex items-start justify-center p-4 pt-[12vh]"
      phx-mounted={JS.focus(to: "##{@id}-input")}
      phx-window-keydown={JS.pop_focus() |> JS.push(@close_event)}
      phx-key="escape"
      {@rest}
    >
      <div
        class="modal-backdrop"
        phx-click={JS.pop_focus() |> JS.push(@close_event)}
        aria-hidden="true"
      />
      <.focus_wrap
        id={"#{@id}-panel"}
        role="dialog"
        aria-modal="true"
        aria-label={@label}
        class="cmdk relative z-50"
      >
        <form
          id={"#{@id}-form"}
          phx-change={@search_event}
          phx-submit={@search_event}
          autocomplete="off"
          class="m-0"
        >
          <label class="cmdk-input">
            <span class="size-[18px] shrink-0 text-muted" aria-hidden="true">
              {render_slot(@search_icon)}
            </span>
            <span class="sr-only">{@label}</span>
            <input
              id={"#{@id}-input"}
              type="search"
              name="query"
              value={@query}
              role="combobox"
              aria-expanded={to_string(@expanded)}
              aria-controls={"#{@id}-list"}
              aria-autocomplete="list"
              placeholder={@placeholder}
              phx-debounce={@debounce}
              class="min-w-0 flex-1 border-0 bg-transparent p-0 text-base text-ink outline-none placeholder:text-muted focus:ring-0"
            />
            <.kbd :if={@close_key} size={:md} aria-hidden="true">{@close_key}</.kbd>
          </label>
        </form>
        <div :if={@scopes != []} class="border-b border-line-soft px-3 py-2">
          <.segmented
            id={"#{@id}-scopes"}
            label={@scope_label || @label}
            value={@scope}
            event={@scope_event}
            size={:sm}
          >
            <:option :for={scope <- @scopes} value={scope.value} label={scope.label} />
          </.segmented>
        </div>
        <div
          id={"#{@id}-list"}
          role="listbox"
          aria-label={@label}
          class="max-h-[420px] overflow-y-auto p-1.5"
        >
          <p :if={@groups == []} class="m-0 px-2.5 py-7 text-center text-sm text-muted">{@empty}</p>
          <div
            :for={{group, index} <- Enum.with_index(@groups)}
            role="group"
            aria-labelledby={"#{@id}-group-#{index}"}
            class="flex flex-col"
          >
            <div id={"#{@id}-group-#{index}"} class="cmdk-group uppercase">{group.label}</div>
            <Autocomplete.option
              :for={item <- group.items}
              id={"#{@id}-item-#{item.id}"}
              item={item}
              class="cmdk-item group no-underline text-ink data-[active]:bg-wrap"
            >
              <span
                :if={@item_icon != []}
                class={[
                  "grid size-7 shrink-0 place-items-center rounded-lg",
                  Autocomplete.tone_class(Map.get(item, :tone, :neutral))
                ]}
                aria-hidden="true"
              >
                {render_slot(@item_icon, item)}
              </span>
              <span class="flex min-w-0 flex-1 flex-col">
                <span class="truncate">{Autocomplete.marked(item.label, @query)}</span>
                <span :if={Map.get(item, :sub)} class="truncate text-xs text-muted">{item.sub}</span>
              </span>
              <span
                :if={Map.get(item, :hint)}
                class={[
                  "rounded-[5px] px-1.5 py-0.5 font-mono text-[11px]",
                  Autocomplete.tone_class(Map.get(item, :tone, :neutral))
                ]}
              >
                {item.hint}
              </span>
              <.kbd :if={Map.get(item, :shortcut)} aria-hidden="true">{item.shortcut}</.kbd>
              <.kbd
                :if={not Map.has_key?(item, :shortcut)}
                tone={:bare}
                class="hidden group-data-[active]:inline"
                aria-hidden="true"
              >
                ↵
              </.kbd>
            </Autocomplete.option>
          </div>
          <button
            :if={@ask_label}
            id={"#{@id}-ask"}
            type="button"
            role="option"
            aria-selected="false"
            data-ask
            data-option
            phx-click={@ask_event}
            phx-value-q={@query}
            class="cmdk-item mt-1 w-full text-left text-tag-warn-text outline-none data-[active]:bg-wrap"
          >
            <span class="size-2.5 rounded-full bg-ai" aria-hidden="true" />
            <span>{@ask_label}</span>
            <.kbd :if={@ask_kbd} tone={:bare} class="ml-auto" aria-hidden="true">{@ask_kbd}</.kbd>
          </button>
        </div>
        <div :if={@keys != []} class="cmdk-footer">
          <span :for={{keys, what} <- @keys} class="flex items-center gap-1.5">
            <.kbd>{keys}</.kbd>
            {what}
          </span>
        </div>
      </.focus_wrap>
    </div>
    """
  end
end
