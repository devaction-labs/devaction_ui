defmodule DevactionUI.Autocomplete do
  @moduledoc """
  Suggestions while you type, in groups (lessons, pull requests, tasks), with the part that matched in bold
  and an optional last row that asks the AI. The server owns the search: the field sends `event` (debounced)
  with the text, and the caller answers with `groups`; this component draws the field and the list and
  moves the active row with ↑ ↓, opens it with Enter (the row is a link) and runs the AI row with ⌘ + Enter
  (or Ctrl + Enter). Esc closes the list, typing opens it again.

  A group is `%{label: "Lessons", items: [%{id: ..., label: ..., to: path, hint: "30", tone: :warn}]}`;
  `hint` is a small mono badge, `tone` colors it. `highlight/2` splits a label around the query, ignoring
  case and accents, for the bold part.
  """
  use Phoenix.Component

  alias DevactionUI.Tone

  attr :id, :string, required: true
  attr :name, :string, default: "q"
  attr :value, :string, default: ""
  attr :label, :string, required: true, doc: "what is being searched, for assistive technology"
  attr :placeholder, :string, default: nil
  attr :event, :string, required: true, doc: "the event the field sends with the text, debounced"
  attr :groups, :list, default: []
  attr :empty, :string, required: true, doc: "shown when a query finds nothing"

  attr :ask_label, :string,
    default: nil,
    doc: "the text of the AI row, e.g. `Ask the AI about \"ecto\"`; no row when nil"

  attr :ask_event, :string, default: nil, doc: "the event the AI row sends with the text"
  attr :class, :any, default: nil

  attr :rest, :global

  def autocomplete(assigns) do
    ~H"""
    <div id={@id} phx-hook="DevactionUI.Autocomplete" class={["relative", @class]} {@rest}>
      <form id={"#{@id}-form"} phx-change={@event} phx-submit={@event} autocomplete="off" class="m-0">
        <label class="flex h-[46px] items-center gap-2.5 rounded-xl border border-line-strong bg-card px-3.5 focus-within:border-ink focus-within:ring-4 focus-within:ring-ink/10">
          <span class="sr-only">{@label}</span>
          <span class="text-muted" aria-hidden="true">⌕</span>
          <input
            type="search"
            name={@name}
            value={@value}
            role="combobox"
            aria-expanded={to_string(@value != "")}
            aria-controls={"#{@id}-list"}
            aria-autocomplete="list"
            placeholder={@placeholder}
            phx-debounce="150"
            class="min-w-0 flex-1 border-0 bg-transparent p-0 text-[15px] text-ink outline-none placeholder:text-muted focus:ring-0"
          />
        </label>
      </form>

      <div
        :if={@value != ""}
        id={"#{@id}-list"}
        role="listbox"
        aria-label={@label}
        class="absolute z-40 mt-1.5 flex w-full flex-col rounded-[14px] border border-line bg-card p-1.5 shadow-[0_16px_40px_rgba(24,24,27,0.12)]"
      >
        <p :if={@groups == []} class="m-0 px-2.5 py-3 text-sm text-muted">{@empty}</p>
        <%= for group <- @groups do %>
          <span class="px-2.5 pt-2 pb-1 font-mono text-[11px] uppercase tracking-[0.08em] text-muted">
            {group.label}
          </span>
          <.link
            :for={item <- group.items}
            id={"#{@id}-item-#{item.id}"}
            role="option"
            navigate={item.to}
            data-option
            class="group flex min-h-10 items-center gap-2.5 rounded-[9px] px-2.5 text-sm text-ink no-underline data-[active]:bg-wrap"
          >
            <span
              :if={Map.get(item, :hint)}
              class={[
                "rounded-[5px] px-1.5 py-0.5 font-mono text-[11px]",
                tone_class(Map.get(item, :tone, :neutral))
              ]}
            >
              {item.hint}
            </span>
            <span>{marked(item.label, @value)}</span>
            <kbd
              class="ml-auto hidden font-mono text-[11px] text-muted group-data-[active]:inline"
              aria-hidden="true"
            >↵</kbd>
          </.link>
        <% end %>
        <.ask_row :if={@ask_label} id={@id} label={@ask_label} event={@ask_event} query={@value} />
      </div>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :label, :string, required: true
  attr :event, :string, required: true
  attr :query, :string, required: true

  defp ask_row(assigns) do
    ~H"""
    <span class="mx-1 my-1.5 h-px bg-line-soft" aria-hidden="true" />
    <button
      type="button"
      id={"#{@id}-ask"}
      role="option"
      data-ask
      data-option
      phx-click={@event}
      phx-value-q={@query}
      class="flex min-h-10 items-center gap-2.5 rounded-[9px] px-2.5 text-left text-sm text-tag-warn-text outline-none data-[active]:bg-wrap"
    >
      <span class="size-2.5 rounded-full bg-ai" aria-hidden="true" />
      <span>{@label}</span>
      <kbd class="ml-auto font-mono text-[11px]" aria-hidden="true">⌘↵</kbd>
    </button>
    """
  end

  defp marked(label, query) do
    label
    |> highlight(query)
    |> Enum.map(fn
      {:match, text} -> ["<strong class=\"font-semibold\">", escape(text), "</strong>"]
      {:text, text} -> escape(text)
    end)
    |> Phoenix.HTML.raw()
  end

  defp escape(text), do: text |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()

  defp tone_class(tone), do: [Tone.text(tone), tone_bg(tone)]
  defp tone_bg(:warn), do: "bg-tag-warn-bg"
  defp tone_bg(:info), do: "bg-tag-info-bg"
  defp tone_bg(:ok), do: "bg-tag-ok-bg"
  defp tone_bg(:risk), do: "bg-tag-risk-bg"
  defp tone_bg(:neutral), do: "bg-tag-neutral-bg"

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
