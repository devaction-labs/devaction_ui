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
  not drawn: give the picker a new `id` to reset it, or send it the dates without a new id:

      JS.dispatch("devaction:date-picker-set", to: "#due-picker", detail: %{from: "2026-10-16", to: nil})

  The month title is capitalised unless `capitalize` is false; the arrows are the `prev_icon` and `next_icon`
  slots (a typographic arrow when empty). Leave `name` out when something else owns the form value, as the
  fields below do: the hidden inputs then have no name and are not sent.

  `date_input/1` and `date_range/1` are the fields of a form: a text field with a mask in the order of the dates of the
  language (`order` `:dmy`, `:mdy` or `:ymd`, and the `separator`) and a button that opens a calendar in a
  `DevactionUI.Popover`. What is sent is a hidden input with the ISO date (`name` for a day, `name_from` and
  `name_to` for a range); the visible text has no name. Typing fills the calendar and picking in the calendar
  fills the text, and `phx-change` hears one `input` per change. The label, the description and the error are
  attrs (`error` is the message, shown under the field and tied to it with `aria-describedby`), and `relative`
  is the text on the right of the field (`in 3 days`), which the server computes, so it follows the value when
  the form is sent back. A day that does not exist, or one before `min`, is marked `aria-invalid` as it is
  typed. In a range the end cannot be before the start.

  `due_chip/1` compares a date with `today` and draws it late (red), due today (amber) or later (neutral); with
  `recurring` it is a grey chip for a repeating deadline, with its own icon (a `↻` when the slot is empty).
  """
  use Phoenix.Component

  import DevactionUI.InputGroup

  alias DevactionUI.FormField

  alias DevactionUI.Popover

  attr :id, :string, default: nil, doc: "required unless a `field` gives it"

  attr :field, Phoenix.HTML.FormField,
    default: nil,
    doc: "a form field (`@form[:due_on]`): gives the `id`, the `name`, the date and the error"

  attr :name, :string,
    default: nil,
    doc: "the name of the hidden inputs; without it they are not sent"

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
    assigns =
      assigns
      |> FormField.put(value: (assigns.mode == :single && :text) || nil)
      |> FormField.require!([:id], "date_picker/1")

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
      <input :if={@mode == :range} type="hidden" name={to_name(@name)} value={@to} data-to-input />
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

  defp from_name(_mode, nil), do: nil
  defp from_name(:range, name), do: name <> "_from"
  defp from_name(:single, name), do: name

  defp to_name(nil), do: nil
  defp to_name(name), do: name <> "_to"

  defp bounds({from, to}), do: {from, to}
  defp bounds(nil), do: {nil, nil}
  defp bounds(from) when is_binary(from), do: {from, nil}

  @orders [:dmy, :mdy, :ymd]

  attr :id, :string, default: nil, doc: "required unless a `field` gives it"

  attr :field, Phoenix.HTML.FormField,
    default: nil,
    doc: "a form field (`@form[:due_on]`): gives the `id`, the `name`, the date and the error"

  attr :name, :string,
    default: nil,
    doc:
      "the name of the hidden input that carries the ISO date; required unless a `field` gives it"

  attr :label, :string, required: true, doc: "the visible label of the field"
  attr :value, :any, default: nil, doc: "an ISO date, a `Date` or nil"
  attr :today, :string, required: true, doc: "today's ISO date in the workspace's time zone"
  attr :min, :string, default: nil, doc: "the first ISO date that can be picked or typed"

  attr :locale, :string,
    default: "en",
    doc: "the language of the month and day names in the calendar"

  attr :week_start, :integer, default: 0, doc: "0 for Sunday, 1 for Monday"

  attr :order, :atom,
    values: @orders,
    default: :dmy,
    doc: "the order of day, month and year in the text"

  attr :separator, :string, default: "/", doc: "the character between the parts of the text"

  attr :placeholder, :string,
    default: nil,
    doc: "e.g. `dd/mm/yyyy`, written in the language of the person"

  attr :description, :string, default: nil, doc: "help text under the field"
  attr :error, :string, default: nil, doc: "the message under the field; marks it invalid"
  attr :relative, :string, default: nil, doc: "text on the right of the field, e.g. `in 3 days`"
  attr :disabled, :boolean, default: false
  attr :required, :boolean, default: false

  attr :calendar_label, :string,
    required: true,
    doc: "names the button and the panel of the calendar"

  attr :previous_label, :string, required: true
  attr :next_label, :string, required: true
  attr :class, :any, default: nil

  slot :icon,
    doc: "the calendar icon at the start of the field; it is the button that opens the calendar"

  slot :prev_icon, doc: "the icon of the previous month button"
  slot :next_icon, doc: "the icon of the next month button"

  slot :shortcut do
    attr :date, :string, required: true, doc: "an ISO date"
  end

  attr :rest, :global, doc: "goes to the box around the label and the field"

  def date_input(assigns) do
    assigns =
      assigns
      |> FormField.put(value: :text)
      |> FormField.require!([:id, :name], "date_input/1")

    assigns = assign(assigns, :error, FormField.error(assigns))
    iso = iso(assigns.value)

    assigns =
      assign(assigns,
        iso: iso,
        text: format_date(iso, assigns.order, assigns.separator),
        describedby: describedby(assigns)
      )

    ~H"""
    <div
      id={@id}
      phx-hook="DevactionUI.DateInput"
      data-mode="single"
      data-order={@order}
      data-separator={@separator}
      data-min={@min}
      class={["flex flex-col gap-1.5", @class]}
      {@rest}
    >
      <label for={"#{@id}-text"} class="text-[13px] font-medium text-ink">{@label}</label>
      <.input_group
        id={"#{@id}-text"}
        value={@text}
        inputmode="numeric"
        autocomplete="off"
        maxlength={10}
        placeholder={@placeholder}
        disabled={@disabled}
        required={@required}
        invalid={@error != nil}
        aria-describedby={@describedby}
        data-date-text="from"
      >
        <:icon>
          <.calendar_popover
            id={@id}
            mode={:single}
            value={@iso}
            today={@today}
            min={@min}
            locale={@locale}
            week_start={@week_start}
            disabled={@disabled}
            calendar_label={@calendar_label}
            previous_label={@previous_label}
            next_label={@next_label}
            icon={@icon}
            prev_icon={@prev_icon}
            next_icon={@next_icon}
            shortcut={@shortcut}
          />
        </:icon>
        <:hint :if={@relative}>
          <span class="text-[13px] whitespace-nowrap text-muted">{@relative}</span>
        </:hint>
      </.input_group>
      <input type="hidden" name={@name} value={@iso} data-date-value="from" />
      <.field_notes id={@id} description={@description} error={@error} />
    </div>
    """
  end

  attr :id, :string, required: true
  attr :name, :string, required: true, doc: "`name_from` and `name_to` are the hidden inputs"
  attr :label, :string, required: true, doc: "the visible label of the pair"
  attr :value, :any, default: nil, doc: "`{from, to}` of ISO dates or `Date`s, or nil"
  attr :today, :string, required: true, doc: "today's ISO date in the workspace's time zone"
  attr :min, :string, default: nil
  attr :locale, :string, default: "en"
  attr :week_start, :integer, default: 0
  attr :order, :atom, values: @orders, default: :dmy
  attr :separator, :string, default: "/"
  attr :placeholder, :string, default: nil, doc: "the placeholder of both fields"
  attr :from_label, :string, required: true, doc: "names the start field for assistive technology"
  attr :to_label, :string, required: true, doc: "names the end field for assistive technology"

  attr :inside_label, :string,
    default: nil,
    doc: "added to the days between the ends, in the calendar"

  attr :description, :string, default: nil
  attr :error, :string, default: nil
  attr :disabled, :boolean, default: false
  attr :required, :boolean, default: false
  attr :calendar_label, :string, required: true
  attr :previous_label, :string, required: true
  attr :next_label, :string, required: true
  attr :class, :any, default: nil
  slot :icon, doc: "the calendar icon at the start of the first field; it opens the calendar"
  slot :arrow, doc: "between the two fields; a `→` when empty"
  slot :prev_icon
  slot :next_icon

  slot :shortcut do
    attr :date, :string, required: true, doc: "an ISO date"
  end

  attr :rest, :global

  def date_range(assigns) do
    {from, to} = bounds(assigns.value)
    from = iso(from)
    to = iso(to)

    assigns =
      assign(assigns,
        from: from,
        to: to,
        from_text: format_date(from, assigns.order, assigns.separator),
        to_text: format_date(to, assigns.order, assigns.separator),
        describedby: describedby(assigns)
      )

    ~H"""
    <div
      id={@id}
      role="group"
      aria-label={@label}
      phx-hook="DevactionUI.DateInput"
      data-mode="range"
      data-order={@order}
      data-separator={@separator}
      data-min={@min}
      class={["flex flex-col gap-1.5", @class]}
      {@rest}
    >
      <span class="text-[13px] font-medium text-ink">{@label}</span>
      <div class="grid grid-cols-[minmax(0,1fr)_auto_minmax(0,1fr)] items-center gap-2">
        <.input_group
          id={"#{@id}-from"}
          value={@from_text}
          inputmode="numeric"
          autocomplete="off"
          maxlength={10}
          placeholder={@placeholder}
          disabled={@disabled}
          required={@required}
          invalid={@error != nil}
          aria-label={@from_label}
          aria-describedby={@describedby}
          data-date-text="from"
          class="font-mono text-sm [&>input]:font-mono"
        >
          <:icon>
            <.calendar_popover
              id={@id}
              mode={:range}
              value={{@from, @to}}
              today={@today}
              min={@min}
              locale={@locale}
              week_start={@week_start}
              inside_label={@inside_label}
              disabled={@disabled}
              calendar_label={@calendar_label}
              previous_label={@previous_label}
              next_label={@next_label}
              icon={@icon}
              prev_icon={@prev_icon}
              next_icon={@next_icon}
              shortcut={@shortcut}
            />
          </:icon>
        </.input_group>
        <span aria-hidden="true" class="text-muted">{(@arrow != [] && render_slot(@arrow)) || "→"}</span>
        <.input_group
          id={"#{@id}-to"}
          value={@to_text}
          inputmode="numeric"
          autocomplete="off"
          maxlength={10}
          placeholder={@placeholder}
          disabled={@disabled}
          required={@required}
          invalid={@error != nil}
          aria-label={@to_label}
          aria-describedby={@describedby}
          data-date-text="to"
          class="font-mono text-sm [&>input]:font-mono"
        />
      </div>
      <input type="hidden" name={@name <> "_from"} value={@from} data-date-value="from" />
      <input type="hidden" name={@name <> "_to"} value={@to} data-date-value="to" />
      <.field_notes id={@id} description={@description} error={@error} />
    </div>
    """
  end

  attr :id, :string, required: true
  attr :mode, :atom, required: true
  attr :value, :any, required: true
  attr :today, :string, required: true
  attr :min, :string, default: nil
  attr :locale, :string, required: true
  attr :week_start, :integer, required: true
  attr :inside_label, :string, default: nil
  attr :disabled, :boolean, required: true
  attr :calendar_label, :string, required: true
  attr :previous_label, :string, required: true
  attr :next_label, :string, required: true
  attr :icon, :list, required: true
  attr :prev_icon, :list, required: true
  attr :next_icon, :list, required: true
  attr :shortcut, :list, required: true

  defp calendar_popover(assigns) do
    ~H"""
    <Popover.popover
      id={"#{@id}-popover"}
      label={@calendar_label}
      panel_class="w-auto border-0! bg-transparent! p-0! shadow-none!"
    >
      <:trigger>
        <button
          type="button"
          disabled={@disabled}
          aria-label={@calendar_label}
          class="grid size-[18px] place-items-center rounded text-muted outline-none focus-visible:ring-2 focus-visible:ring-ink/20 disabled:cursor-not-allowed [&>*]:size-full"
        >
          {(@icon != [] && render_slot(@icon)) || "▾"}
        </button>
      </:trigger>
      <.date_picker
        id={"#{@id}-picker"}
        mode={@mode}
        value={@value}
        today={@today}
        min={@min}
        locale={@locale}
        week_start={@week_start}
        previous_label={@previous_label}
        next_label={@next_label}
        inside_label={@inside_label}
        shadow
        data-date-picker
      >
        <:prev_icon :if={@prev_icon != []}>{render_slot(@prev_icon)}</:prev_icon>
        <:next_icon :if={@next_icon != []}>{render_slot(@next_icon)}</:next_icon>
        <:shortcut :for={shortcut <- @shortcut} date={shortcut.date}>
          {render_slot(shortcut)}
        </:shortcut>
      </.date_picker>
    </Popover.popover>
    """
  end

  attr :id, :string, required: true
  attr :description, :string, default: nil
  attr :error, :string, default: nil

  defp field_notes(assigns) do
    ~H"""
    <p :if={@description} id={"#{@id}-description"} class="m-0 text-[13px] text-muted">
      {@description}
    </p>
    <p :if={@error} id={"#{@id}-error"} class="m-0 text-[13px] text-missing">{@error}</p>
    """
  end

  defp describedby(assigns) do
    [
      assigns.description && "#{assigns.id}-description",
      assigns.error && "#{assigns.id}-error"
    ]
    |> Enum.filter(& &1)
    |> join_ids()
  end

  defp join_ids([]), do: nil
  defp join_ids(ids), do: Enum.join(ids, " ")

  defp iso(nil), do: nil
  defp iso(%Date{} = date), do: Date.to_iso8601(date)
  defp iso(iso) when is_binary(iso), do: iso

  @doc """
  An ISO date (or a `Date`) as the text of a date field: `16/10/2026` for `:dmy` and `"/"`, nothing for nil.

      iex> DevactionUI.DatePicker.format_date("2026-10-16", :mdy, "/")
      "10/16/2026"
  """
  @spec format_date(Date.t() | String.t() | nil, :dmy | :mdy | :ymd, String.t()) :: String.t()
  def format_date(nil, _order, _separator), do: ""

  def format_date(date, order, separator) do
    [year, month, day] = date |> iso() |> String.split("-")
    order |> arrange(year, month, day) |> Enum.join(separator)
  end

  defp arrange(:dmy, year, month, day), do: [day, month, year]
  defp arrange(:mdy, year, month, day), do: [month, day, year]
  defp arrange(:ymd, year, month, day), do: [year, month, day]

  attr :date, :any, default: nil, doc: "a `Date`; not needed for a recurring chip"

  attr :today, :any,
    default: nil,
    doc: "a `Date`: today in the workspace's time zone; not needed for a recurring chip"

  attr :text, :string, required: true, doc: "what the chip says, already in the person's language"
  attr :recurring, :boolean, default: false, doc: "a grey chip for a repeating deadline"
  attr :class, :any, default: nil
  slot :icon, doc: "the icon of a recurring chip; a `↻` when empty"
  attr :rest, :global

  def due_chip(assigns) do
    assigns = assign(assigns, :state, chip_state(assigns))

    ~H"""
    <span
      data-state={@state}
      class={[
        "inline-flex h-7 items-center gap-1.5 rounded-lg px-2.5 text-xs",
        chip_class(@state),
        @class
      ]}
      {@rest}
    >
      <span :if={@recurring} aria-hidden="true">{(@icon != [] && render_slot(@icon)) || "↻"}</span>
      {@text}
    </span>
    """
  end

  defp chip_state(%{recurring: true}), do: :recurring
  defp chip_state(%{date: date, today: today}), do: state(date, today)

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
  defp chip_class(:recurring), do: "bg-wrap text-ink-2"
end
