defmodule DevactionUI.Autocomplete do
  @moduledoc """
  Suggestions while you type, in groups (lessons, pull requests, tasks), with the part that matched in bold
  and an optional last row that asks the AI. The server owns the search: the field sends `event` (debounced by
  `debounce` ms) with the text, and the caller answers with `groups`; this component draws the field and the
  list and moves the active row with ↑ ↓, opens it with Enter and runs the AI row with ⌘ + Enter (or Ctrl +
  Enter). Esc closes the list, typing opens it again. The list also closes when the focus leaves the whole
  component, a moment after, so the click that chose a row still lands.

  A group is `%{label: "Lessons", items: [%{id: ..., label: ..., to: path, hint: "30", tone: :warn}]}`; each
  group is a `role="group"` named by its label. A row goes where `to` (a LiveView navigation), `patch` or
  `href` says (or sends `event` with its `id`); `hint` is a small mono badge, `tone` colors it, and
  `hint_style: :plain` draws it as bare mono text in the tone, with no background (the number of a pull request
  or an issue: `#142`). The AI row sends `ask_event` with the typed text
  in the `q` parameter (`phx-value-q`). `highlight/2` splits a label around the query, ignoring case and
  accents, for the bold part.

  While the server searches, `loading` shows `loading_label` (with the `loading_icon` slot, if any) instead of the
  "nothing found" text, keeps the rows it has, and sets `aria-busy` on the list. What a query that finds nothing
  says is `empty`, or the `empty_state` slot when it needs more than text (a link to create the thing); the slot
  gets the query.

  The field tells assistive technology the list is open only when there is a row in it: not for a query that
  found nothing and has no AI row. Icons are slots (`search_icon`, with a `⌕` when there is none) and the
  key caps are `DevactionUI.Kbd`: `ask_kbd` is the key of the AI row, written by the caller (`⌘↵` on a Mac,
  `Ctrl ↵` elsewhere).
  """
  use Phoenix.Component

  import DevactionUI.Kbd

  alias DevactionUI.Tone

  attr :id, :string, required: true
  attr :name, :string, default: "q"
  attr :value, :string, default: ""
  attr :label, :string, required: true, doc: "what is being searched, for assistive technology"
  attr :placeholder, :string, default: nil
  attr :event, :string, required: true, doc: "the event the field sends with the text, debounced"
  attr :debounce, :integer, default: 150, doc: "milliseconds the field waits before sending"

  attr :groups, :list,
    default: [],
    doc: "`%{label, items: [%{id, label, to | patch | href, hint, tone}]}`"

  attr :empty, :string, required: true, doc: "shown when a query finds nothing"

  attr :loading, :boolean,
    default: false,
    doc: "the server is searching: shows `loading_label` and marks the list busy"

  attr :loading_label, :string, default: nil, doc: "what the list says while `loading`"

  attr :ask_label, :string,
    default: nil,
    doc: "the text of the AI row, e.g. `Ask the AI about \"ecto\"`; no row when nil"

  attr :ask_event, :string, default: nil, doc: "the event the AI row sends with the text, as `q`"

  attr :ask_kbd, :string,
    default: nil,
    doc: "the key of the AI row, as a key cap: `⌘↵`; none when nil"

  attr :class, :any, default: nil

  attr :rest, :global
  slot :search_icon, doc: "the magnifier in the field"
  slot :loading_icon, doc: "turning icon before `loading_label`"
  slot :empty_state, doc: "replaces the `empty` text; gets the query"

  @spec autocomplete(map()) :: Phoenix.LiveView.Rendered.t()
  def autocomplete(assigns) do
    assigns =
      assign(
        assigns,
        :expanded,
        assigns.value != "" and (assigns.groups != [] or assigns.ask_label != nil)
      )

    ~H"""
    <div id={@id} phx-hook="DevactionUI.Autocomplete" class={["relative", @class]} {@rest}>
      <form id={"#{@id}-form"} phx-change={@event} phx-submit={@event} autocomplete="off" class="m-0">
        <label class="flex h-11 items-center gap-2.5 rounded-xl border border-line-strong bg-card px-3.5 focus-within:border-ink focus-within:ring-4 focus-within:ring-ink/10">
          <span class="sr-only">{@label}</span>
          <span class="size-4 shrink-0 text-muted" aria-hidden="true">
            {render_slot(@search_icon)}<span :if={@search_icon == []}>⌕</span>
          </span>
          <input
            type="search"
            name={@name}
            value={@value}
            role="combobox"
            aria-expanded={to_string(@expanded)}
            aria-controls={"#{@id}-list"}
            aria-autocomplete="list"
            placeholder={@placeholder}
            phx-debounce={@debounce}
            class="min-w-0 flex-1 border-0 bg-transparent p-0 text-[15px] text-ink outline-none placeholder:text-muted focus:ring-0"
          />
        </label>
      </form>

      <div
        :if={@value != ""}
        id={"#{@id}-list"}
        role="listbox"
        aria-label={@label}
        aria-busy={@loading && "true"}
        class="absolute z-40 mt-1.5 flex w-full flex-col rounded-[14px] border border-line bg-card p-1.5 shadow-pop"
      >
        <p
          :if={@loading}
          role="status"
          class="m-0 flex items-center gap-2 px-2.5 py-3 text-sm text-muted"
        >
          <span :if={@loading_icon != []} class="size-4 shrink-0 animate-spin" aria-hidden="true">
            {render_slot(@loading_icon)}
          </span>
          {@loading_label}
        </p>
        <div
          :if={@groups == [] and not @loading}
          role="status"
          class="m-0 px-2.5 py-3 text-sm text-muted"
        >
          {(@empty_state == [] && @empty) || render_slot(@empty_state, @value)}
        </div>
        <div
          :for={{group, index} <- Enum.with_index(@groups)}
          role="group"
          aria-labelledby={"#{@id}-group-#{index}"}
          class="flex flex-col"
        >
          <span
            id={"#{@id}-group-#{index}"}
            class="px-2.5 pt-2 pb-1 font-mono text-[11px] uppercase tracking-[0.08em] text-muted"
          >
            {group.label}
          </span>
          <.option
            :for={item <- group.items}
            id={"#{@id}-item-#{item.id}"}
            item={item}
            class="group flex min-h-10 items-center gap-2.5 rounded-[9px] px-2.5 text-sm text-ink no-underline data-[active]:bg-wrap"
          >
            <.hint item={item} />
            <span>{marked(item.label, @value)}</span>
            <.kbd tone={:bare} class="ml-auto hidden group-data-[active]:inline" aria-hidden="true">
              ↵
            </.kbd>
          </.option>
        </div>
        <.ask_row
          :if={@ask_label}
          id={@id}
          label={@ask_label}
          event={@ask_event}
          kbd={@ask_kbd}
          query={@value}
        />
      </div>
    </div>
    """
  end

  attr :id, :string, required: true

  attr :item, :map,
    required: true,
    doc: "`%{to | patch | href}` goes there; `%{event}` sends it with the item's `id`"

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc """
  One row of the list, for `DevactionUI.Autocomplete` and `DevactionUI.CommandPalette`: a link when the item has
  `to` (a LiveView navigation), `patch` or `href`, and a button that sends `event` with the item's `id` (as
  `id`) when it has `event`. It is a `role="option"` the hook can move over.
  """
  @spec option(map()) :: Phoenix.LiveView.Rendered.t()
  def option(%{item: %{event: event}} = assigns) do
    assigns = assign(assigns, :event, event)

    ~H"""
    <button
      type="button"
      id={@id}
      role="option"
      aria-selected="false"
      data-option
      phx-click={@event}
      phx-value-id={@item.id}
      class={[@class, "w-full text-left outline-none"]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  def option(assigns) do
    ~H"""
    <.link
      id={@id}
      role="option"
      aria-selected="false"
      navigate={Map.get(@item, :to)}
      patch={Map.get(@item, :patch)}
      href={Map.get(@item, :href)}
      data-option
      class={@class}
      {@rest}
    >
      {render_slot(@inner_block)}
    </.link>
    """
  end

  attr :item, :map,
    required: true,
    doc: "`%{hint, tone, hint_style}`; `hint_style` is `:badge` (default) or `:plain`"

  attr :rest, :global

  @doc false
  def hint(assigns) do
    ~H"""
    <span
      :if={Map.get(@item, :hint)}
      class={hint_class(Map.get(@item, :hint_style, :badge), Map.get(@item, :tone, :neutral))}
      {@rest}
    >
      {@item.hint}
    </span>
    """
  end

  defp hint_class(:badge, tone),
    do: ["rounded-[5px] px-1.5 py-0.5 font-mono text-[11px]", tone_class(tone)]

  defp hint_class(:plain, tone), do: ["font-mono text-xs", Tone.text(tone)]

  attr :id, :string, required: true
  attr :label, :string, required: true
  attr :event, :string, required: true
  attr :kbd, :string, default: nil
  attr :query, :string, required: true

  defp ask_row(assigns) do
    ~H"""
    <span class="mx-1 my-1.5 h-px bg-line-soft" aria-hidden="true" />
    <button
      type="button"
      id={"#{@id}-ask"}
      role="option"
      aria-selected="false"
      data-ask
      data-option
      phx-click={@event}
      phx-value-q={@query}
      class="flex min-h-10 items-center gap-2.5 rounded-[9px] px-2.5 text-left text-sm text-tag-warn-text outline-none data-[active]:bg-wrap"
    >
      <span class="size-2.5 rounded-full bg-ai" aria-hidden="true" />
      <span>{@label}</span>
      <.kbd :if={@kbd} tone={:bare} class="ml-auto" aria-hidden="true">{@kbd}</.kbd>
    </button>
    """
  end

  @doc false
  def marked(label, query) do
    label
    |> highlight(query)
    |> Enum.map(fn
      {:match, text} -> ["<strong class=\"font-semibold\">", escape(text), "</strong>"]
      {:text, text} -> escape(text)
    end)
    |> Phoenix.HTML.raw()
  end

  defp escape(text), do: text |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()

  @doc false
  def tone_class(tone), do: [Tone.text(tone), tone_bg(tone)]

  @doc false
  def tone_bg(:warn), do: "bg-tag-warn-bg"
  def tone_bg(:info), do: "bg-tag-info-bg"
  def tone_bg(:ok), do: "bg-tag-ok-bg"
  def tone_bg(:risk), do: "bg-tag-risk-bg"
  def tone_bg(:neutral), do: "bg-tag-neutral-bg"

  @doc """
  Splits `label` around the first place `query` appears, ignoring case and accents:
  `highlight("Ecto.Multi", "ecto")` is `[match: "Ecto", text: ".Multi"]`. No match, or a blank query, is the
  whole label as text.
  """
  @spec highlight(String.t(), String.t()) :: [{:text | :match, String.t()}]
  def highlight(label, query), do: split(label, fold(String.trim(query)))

  defp split(label, ""), do: [text: label]

  defp split(label, needle) do
    case find(label, needle) do
      nil -> [text: label]
      {start, len} -> around(label, start, len)
    end
  end

  defp around(label, start, len) do
    [
      text: String.slice(label, 0, start),
      match: String.slice(label, start, len),
      text: String.slice(label, start + len, String.length(label))
    ]
    |> Enum.reject(fn {_kind, text} -> text == "" end)
  end

  defp find(label, needle) do
    size = String.length(needle)
    graphemes = String.graphemes(label)

    Enum.find_value(0..max(length(graphemes) - 1, 0), fn start ->
      window = graphemes |> Enum.slice(start, size) |> Enum.join()
      matching?(window, needle, size) && {start, size}
    end)
  end

  defp matching?(window, needle, size),
    do: String.length(window) == size and fold(window) == needle

  defp fold(text) do
    text |> String.normalize(:nfd) |> String.replace(~r/\p{Mn}/u, "") |> String.downcase()
  end
end
