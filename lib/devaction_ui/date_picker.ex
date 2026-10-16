defmodule DevactionUI.DatePicker do
  @moduledoc """
  A month calendar that picks one day or a range, and the small chip that says how near a deadline is.

  `date_picker/1` is drawn by a hook, so the months turn without the server. The server gives it only what it
  alone knows: the day that is *today* in the workspace's time zone (`today`), the shortcuts (`Today`,
  `Friday`, `+7 days`, `End of the milestone`, each with its ISO date) and the texts. Month and weekday names
  come from the browser's `Intl` in the `locale` given. The choice goes into hidden inputs (`name` for one
  day, `name_from` and `name_to` for a range), as ISO dates, and the hook fires `input` so `phx-change` hears it.

  Keys: ← → move a day, ↑ ↓ a week, PageUp and PageDown a month, Home and End the week, Enter or Space
  picks. Days before `min` are dimmed and cannot be picked, and the keyboard lands on `min` when today is
  before it. The days are buttons in a labelled group, not a `grid`.

  The element is `phx-update="ignore"` (the browser owns the month on show), so a new `value` from the server is
  not drawn: give the picker a new `id` to reset it. The month title is capitalised unless `capitalize` is
  false; the arrows are the `prev_icon` and `next_icon` slots (a typographic arrow when empty).

  `due_chip/1` compares a date with `today` and draws it late (red), due today (amber) or later (neutral).
  """
  use Phoenix.Component

  attr :id, :string, required: true
  attr :name, :string, required: true
  attr :mode, :atom, values: [:single, :range], default: :single
  attr :value, :any, default: nil, doc: "an ISO date, or `{from, to}` for a range, or nil"
  attr :today, :string, required: true, doc: "today's ISO date in the workspace's time zone"
  attr :min, :string, default: nil, doc: "the first ISO date that can be picked"
  attr :locale, :string, default: "en"
  attr :week_start, :integer, default: 0, doc: "0 for Sunday, 1 for Monday"
  attr :previous_label, :string, required: true
  attr :next_label, :string, required: true
  attr :capitalize, :boolean, default: true, doc: "upper-case the first letter of the month title"

  attr :inside_label, :string,
    default: nil,
    doc: "added to the name of the days between the ends of a range, e.g. `in the range`"

  attr :shadow, :boolean, default: false, doc: "the panel's shadow, for use inside a popover"
  attr :class, :any, default: nil
  slot :prev_icon, doc: "the icon of the previous month button"
  slot :next_icon, doc: "the icon of the next month button"

  slot :shortcut do
    attr :date, :string, required: true, doc: "an ISO date"
  end

  attr :rest, :global

  def date_picker(assigns) do
    {from, to} = bounds(assigns.value)
    assigns = assign(assigns, from: from, to: to)

    ~H"""
    <div
      id={@id}
      phx-hook="DevactionUI.DatePicker"
      phx-update="ignore"
      data-mode={@mode}
      data-today={@today}
      data-min={@min}
      data-locale={@locale}
      data-week-start={@week_start}
      data-from={@from}
      data-to={@to}
      data-previous={@previous_label}
      data-next={@next_label}
      data-capitalize={to_string(@capitalize)}
      data-inside={@inside_label}
      class={[
        "flex w-[300px] flex-col gap-2.5 rounded-[14px] border border-line bg-card p-3.5",
        @shadow && "shadow-pop",
        @class
      ]}
      {@rest}
    >
      <input
        type="hidden"
        name={from_name(@mode, @name)}
        value={@from}
        data-from-input
      />
      <input :if={@mode == :range} type="hidden" name={@name <> "_to"} value={@to} data-to-input />
      <template data-previous-icon>{render_slot(@prev_icon)}</template>
      <template data-next-icon>{render_slot(@next_icon)}</template>
      <div data-calendar></div>
      <div :if={@shortcut != []} class="flex flex-wrap gap-1.5 border-t border-line-soft pt-2">
        <button
          :for={shortcut <- @shortcut}
          type="button"
          data-shortcut={shortcut.date}
          class="inline-flex h-7 items-center rounded-full bg-wrap px-2.5 text-xs text-ink outline-none hover:bg-line focus-visible:ring-2 focus-visible:ring-ink/20"
        >
          {render_slot(shortcut)}
        </button>
      </div>
    </div>
    """
  end

  defp from_name(:range, name), do: name <> "_from"
  defp from_name(:single, name), do: name

  defp bounds({from, to}), do: {from, to}
  defp bounds(nil), do: {nil, nil}
  defp bounds(from) when is_binary(from), do: {from, nil}

  attr :date, :any, required: true, doc: "a `Date`"
  attr :today, :any, required: true, doc: "a `Date`: today in the workspace's time zone"
  attr :text, :string, required: true, doc: "what the chip says, already in the person's language"
  attr :class, :any, default: nil
  attr :rest, :global

  def due_chip(assigns) do
    assigns = assign(assigns, :state, state(assigns.date, assigns.today))

    ~H"""
    <span
      data-state={@state}
      class={[
        "inline-flex h-7 items-center rounded-lg px-2.5 text-xs",
        chip_class(@state),
        @class
      ]}
      {@rest}
    >
      {@text}
    </span>
    """
  end

  @doc "`:late`, `:today` or `:later`."
  @spec state(Date.t(), Date.t()) :: :late | :today | :later
  def state(date, today) do
    case Date.compare(date, today) do
      :lt -> :late
      :eq -> :today
      :gt -> :later
    end
  end

  defp chip_class(:late), do: "bg-tag-risk-bg text-tag-risk-text"
  defp chip_class(:today), do: "bg-tag-warn-bg text-tag-warn-text"
  defp chip_class(:later), do: "bg-wrap text-ink-2"
end
