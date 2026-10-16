defmodule DevactionUI.DateRange do
  @moduledoc """
  A button that shows a range of dates and opens, in a `DevactionUI.Popover`, a panel to change it: a column of
  ready-made ranges (`Today`, `Last 7 days`, `This month`, a milestone of the project, `Custom`), two months side by
  side with the band of the range, a dot on today and a preview of the range under the pointer, and a footer with how
  many days are picked, `Cancel` and `Apply`. An optional column on the right (the `aside` slot) takes whatever goes
  with the range, such as `DevactionUI.TimeField`.

  What is picked stays pending until `Apply`: it then goes into two hidden inputs, `name_from` and `name_to`, as ISO
  dates, the trigger shows it (`1 Oct – 15 Oct 2026`, written by the browser's `Intl` in the `locale` given) and the
  hook fires `input` so `phx-change` hears it. `Cancel`, Esc and a press outside drop what was picked. The keys are those
  of `DevactionUI.DatePicker`: arrows move a day or a week, PageUp and PageDown a month, Home and End the week, Enter
  picks; the pure date logic is `dates.js`, shared with it.

  The server gives it what only it knows: `today` in the workspace's time zone, the `min`, and the presets as ISO
  dates (a preset whose range is the picked one is shown pressed, and `Custom`, the preset with no dates, when none
  is). The element keeps the browser's months and text, so a new `value` is not drawn: give it a new `id`, or send it
  `JS.dispatch("devaction:date-range-set", to: "#period", detail: %{from: "2026-10-01", to: "2026-10-15"})`.
  Every word is an attr or a slot.
  """
  use Phoenix.Component

  alias DevactionUI.Button
  alias DevactionUI.Popover
  alias Phoenix.LiveView.JS

  attr :id, :string, required: true

  attr :name, :string,
    required: true,
    doc: "the hidden inputs are `name_from` and `name_to`, with ISO dates"

  attr :label, :string, required: true, doc: "names the panel, e.g. `Choose the period`"

  attr :value, :any,
    default: nil,
    doc: "the applied range: `{from, to}` of ISO dates or `Date`s, or nil"

  attr :today, :string, required: true, doc: "today's ISO date in the workspace's time zone"
  attr :min, :string, default: nil, doc: "the first ISO date that can be picked"

  attr :locale, :string,
    default: "en",
    doc: "the language of the month and day names and of the trigger"

  attr :week_start, :integer, default: 0, doc: "0 for Sunday, 1 for Monday"

  attr :capitalize, :boolean,
    default: false,
    doc: "upper-case the first letter of each month title"

  attr :align, :atom,
    values: [:start, :end],
    default: :start,
    doc: "the edge of the trigger the panel lines up with"

  attr :portal, :boolean,
    default: false,
    doc:
      "draw the panel at the level of `document.body`, so a container with `overflow` does not clip it (see `DevactionUI.Popover`)"

  attr :placeholder, :string,
    required: true,
    doc: "what the trigger says while there is no range, e.g. `Choose the period`"

  attr :previous_label, :string, required: true
  attr :next_label, :string, required: true

  attr :presets_label, :string,
    default: nil,
    doc: "names the column of ready-made ranges for assistive technology"

  attr :count_label, :string,
    required: true,
    doc:
      "the footer text for a range of days; `%{count}` is filled in, as in `%{count} days selected`"

  attr :one_label, :string,
    default: nil,
    doc: "the footer text for a range of one day (`1 day selected`); `count_label` when empty"

  attr :pending_label, :string,
    default: nil,
    doc: "the footer text once the start is picked and the end is not, e.g. `Pick the end date`"

  attr :cancel_label, :string, required: true
  attr :apply_label, :string, required: true
  attr :class, :any, default: nil

  slot :icon, doc: "the calendar icon at the start of the trigger; it gets 16px"
  slot :prev_icon, doc: "the icon of the previous month button"
  slot :next_icon, doc: "the icon of the next month button"

  slot :preset,
    doc:
      "a ready-made range; its text is the content. One with no `from` and `to` is the `Custom` entry, shown pressed when no other fits" do
    attr :from, :string, doc: "an ISO date"
    attr :to, :string, doc: "an ISO date"
  end

  slot :aside, doc: "the column on the right of the months, e.g. a `DevactionUI.TimeField`"
  attr :rest, :global

  def picker(assigns) do
    {from, to} = bounds(assigns.value)
    assigns = assign(assigns, from: from, to: to)

    ~H"""
    <div
      id={@id}
      phx-hook="DevactionUI.DateRange"
      data-today={@today}
      data-min={@min}
      data-locale={@locale}
      data-week-start={@week_start}
      data-capitalize={to_string(@capitalize)}
      data-from={@from}
      data-to={@to}
      data-placeholder={@placeholder}
      data-previous={@previous_label}
      data-next={@next_label}
      data-count={@count_label}
      data-one={@one_label}
      data-pending={@pending_label}
      class={["inline-block", @class]}
      {@rest}
    >
      <template data-previous-icon>{render_slot(@prev_icon)}</template>
      <template data-next-icon>{render_slot(@next_icon)}</template>
      <input
        type="hidden"
        name={@name <> "_from"}
        value={@from}
        data-from-input
        phx-mounted={JS.ignore_attributes(["value"])}
      />
      <input
        type="hidden"
        name={@name <> "_to"}
        value={@to}
        data-to-input
        phx-mounted={JS.ignore_attributes(["value"])}
      />
      <Popover.popover
        id={@id <> "-popover"}
        label={@label}
        align={@align}
        portal={@portal}
        panel_class="w-auto border-0! bg-transparent! p-0! shadow-none!"
      >
        <:trigger>
          <button
            type="button"
            class="inline-flex h-[38px] items-center gap-2 rounded-[10px] border border-line-strong bg-card px-3 text-sm text-ink outline-none hover:border-ink focus-visible:ring-4 focus-visible:ring-ink/10 aria-expanded:border-ink aria-expanded:ring-[3px] aria-expanded:ring-ink/10"
          >
            <span
              :if={@icon != []}
              aria-hidden="true"
              class="grid size-4 flex-none place-items-center [&>*]:size-full"
            >
              {render_slot(@icon)}
            </span>
            <span id={@id <> "-label"} data-range-label phx-update="ignore">{@placeholder}</span>
          </button>
        </:trigger>
        <div class="flex w-max max-w-[calc(100vw-1rem)] flex-col overflow-hidden rounded-2xl border border-line bg-card shadow-pop">
          <div class="flex overflow-x-auto">
            <div
              role="group"
              aria-label={@presets_label}
              class="flex w-[190px] flex-none flex-col gap-0.5 border-r border-line-soft px-2.5 py-3.5"
            >
              <button
                :for={preset <- @preset}
                type="button"
                data-preset
                data-from={preset[:from]}
                data-to={preset[:to]}
                aria-pressed="false"
                phx-mounted={JS.ignore_attributes(["aria-pressed"])}
                class="h-[34px] cursor-pointer rounded-lg px-2.5 text-left text-sm text-ink-2 outline-none hover:bg-wrap focus-visible:ring-2 focus-visible:ring-ink/20 aria-pressed:bg-wrap aria-pressed:font-medium aria-pressed:text-ink"
              >
                {render_slot(preset)}
              </button>
            </div>
            <div
              id={@id <> "-months"}
              data-range-months
              phx-update="ignore"
              class="grid grid-cols-[repeat(2,266px)] items-start gap-7 px-[22px] py-[18px]"
            >
            </div>
            <div
              :if={@aside != []}
              class="flex w-[300px] flex-none flex-col gap-3.5 border-l border-line-soft px-5 py-[18px]"
            >
              {render_slot(@aside)}
            </div>
          </div>
          <div class="flex items-center gap-2 border-t border-line-soft px-5 py-3.5 text-[13px] text-ink-2">
            <span id={@id <> "-count"} data-range-count phx-update="ignore" role="status"></span>
            <Button.button
              type="button"
              variant={:secondary}
              size={:sm}
              class="ml-auto h-9! px-3.5! text-sm!"
              data-range-cancel
            >
              {@cancel_label}
            </Button.button>
            <Button.button
              type="button"
              variant={:primary}
              size={:sm}
              class="h-9! px-3.5! text-sm! disabled:cursor-not-allowed disabled:opacity-40"
              data-range-apply
              phx-mounted={JS.ignore_attributes(["disabled"])}
            >
              {@apply_label}
            </Button.button>
          </div>
        </div>
      </Popover.popover>
    </div>
    """
  end

  defp bounds({from, to}), do: {iso(from), iso(to)}
  defp bounds(nil), do: {nil, nil}
  defp bounds(from), do: {iso(from), nil}

  defp iso(nil), do: nil
  defp iso(%Date{} = date), do: Date.to_iso8601(date)
  defp iso(iso) when is_binary(iso), do: iso
end
