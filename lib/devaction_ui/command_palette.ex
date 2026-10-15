defmodule DevactionUI.CommandPalette do
  @moduledoc """
  The ⌘K palette as a library piece: a dialog near the top with a large field, an optional row of scopes
  (all, pull requests, tasks...), the results in groups with their hints, an "ask the AI" action with the typed
  text and a footer that teaches the keys. ↑ ↓ move the active row, ↵ opens it, ⌘↵ asks the AI and Esc closes it.

  The server owns the search, as in `DevactionUI.Autocomplete` (whose keyboard hook it shares and whose `groups`
  it takes). The LiveView decides when it is there (`:if={@open}`); it takes the focus in and keeps it inside.
  """
  use Phoenix.Component

  import DevactionUI.Segmented

  alias DevactionUI.Autocomplete
  alias DevactionUI.Tone
  alias Phoenix.LiveView.JS

  attr :id, :string, required: true
  attr :label, :string, required: true, doc: "the name of the dialog, for assistive technology"
  attr :query, :string, default: ""
  attr :placeholder, :string, default: nil
  attr :search_event, :string, required: true, doc: "sent with the text, debounced"
  attr :close_event, :string, required: true

  attr :groups, :list,
    default: [],
    doc: "as in `Autocomplete`: `%{label, items: [%{id, label, to, hint, tone}]}`"

  attr :empty, :string, required: true
  attr :ask_label, :string, default: nil
  attr :ask_event, :string, default: nil
  attr :scopes, :list, default: [], doc: "`%{value, label}` each; none draws no row"
  attr :scope, :string, default: nil
  attr :scope_event, :string, default: nil
  attr :scope_label, :string, default: nil
  attr :keys, :list, default: [], doc: "`{keys, what}` for the footer: `{\"↑↓\", \"move\"}`"
  slot :search_icon

  attr :rest, :global

  def palette(assigns) do
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
              aria-expanded="true"
              aria-controls={"#{@id}-list"}
              aria-autocomplete="list"
              placeholder={@placeholder}
              phx-debounce="150"
              class="min-w-0 flex-1 border-0 bg-transparent p-0 text-base text-ink outline-none placeholder:text-muted focus:ring-0"
            />
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
          class="max-h-[50vh] overflow-y-auto p-1.5"
        >
          <p :if={@groups == []} class="m-0 px-2.5 py-3 text-sm text-muted">{@empty}</p>
          <%= for group <- @groups do %>
            <div class="cmdk-group">{group.label}</div>
            <.link
              :for={item <- group.items}
              id={"#{@id}-item-#{item.id}"}
              role="option"
              navigate={item.to}
              data-option
              class="cmdk-item group no-underline text-ink data-[active]:bg-wrap"
            >
              <span
                :if={Map.get(item, :hint)}
                class={[
                  "rounded-[5px] px-1.5 py-0.5 font-mono text-[11px]",
                  Tone.text(Map.get(item, :tone, :neutral)),
                  tone_bg(Map.get(item, :tone, :neutral))
                ]}
              >
                {item.hint}
              </span>
              <span>{marked(item.label, @query)}</span>
              <kbd
                class="ml-auto hidden font-mono text-[11px] text-muted group-data-[active]:inline"
                aria-hidden="true"
              >↵</kbd>
            </.link>
          <% end %>
          <button
            :if={@ask_label}
            id={"#{@id}-ask"}
            type="button"
            role="option"
            data-ask
            data-option
            phx-click={@ask_event}
            phx-value-q={@query}
            class="cmdk-item mt-1 w-full text-left text-tag-warn-text outline-none data-[active]:bg-wrap"
          >
            <span class="size-2.5 rounded-full bg-ai" aria-hidden="true" />
            <span>{@ask_label}</span>
            <kbd class="ml-auto font-mono text-[11px]" aria-hidden="true">⌘↵</kbd>
          </button>
        </div>
        <div :if={@keys != []} class="cmdk-footer">
          <span :for={{keys, what} <- @keys} class="flex items-center gap-1.5">
            <kbd class="rounded border border-line-strong bg-card px-1.5 font-mono text-[11px] text-ink-2">
              {keys}
            </kbd>
            {what}
          </span>
        </div>
      </.focus_wrap>
    </div>
    """
  end

  defp marked(label, query) do
    label
    |> Autocomplete.highlight(query)
    |> Enum.map(fn
      {:match, text} -> ["<strong class=\"font-semibold\">", escape(text), "</strong>"]
      {:text, text} -> escape(text)
    end)
    |> Phoenix.HTML.raw()
  end

  defp escape(text), do: text |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()

  defp tone_bg(:warn), do: "bg-tag-warn-bg"
  defp tone_bg(:info), do: "bg-tag-info-bg"
  defp tone_bg(:ok), do: "bg-tag-ok-bg"
  defp tone_bg(:risk), do: "bg-tag-risk-bg"
  defp tone_bg(:neutral), do: "bg-tag-neutral-bg"
end
