defmodule DevactionUI.TimeField do
  @moduledoc """
  A start time and an end time with the suggestions around the one being edited and how long the span is: what a
  time sheet or a booking asks for. The fields are text inputs with a clock icon that take digits and lay them out
  as `HH:MM` (`930` becomes `09:30` when the field is left); under them a list shows the steps around the time of
  the field in focus, each with its length from the start when the end is being edited (`10:30 · 1 h 30 min`), the
  chosen one inverted; below, a `Duration` row and a note, such as the time zone and the step.

  The keys are those of a combobox: ↑ and ↓ move the time one step, Enter completes what was typed, a click on a
  suggestion picks it. The fields have the names (`start_name`, `end_name`) and hold `HH:MM` text, so a form with
  `phx-change` hears them; the list and the length are drawn by the `DevactionUI.TimeField` hook from the pure
  logic in `clock.js`. Every word is an attr: `hours_label` and `minutes_label` are patterns with `%{count}`
  (`%{count} h`, `%{count} min`) that write both the suggestions and the duration.
  """
  use Phoenix.Component

  attr :id, :string, required: true
  attr :start_name, :string, required: true, doc: "the name of the start field"
  attr :end_name, :string, required: true, doc: "the name of the end field"
  attr :start_value, :string, default: "09:00", doc: "the start as `HH:MM`"
  attr :end_value, :string, default: "10:00", doc: "the end as `HH:MM`"
  attr :start_label, :string, required: true, doc: "the label of the start field, e.g. `Start`"
  attr :end_label, :string, required: true, doc: "the label of the end field, e.g. `End`"
  attr :list_label, :string, required: true, doc: "names the list of suggestions, e.g. `Times`"

  attr :duration_label, :string,
    required: true,
    doc: "the row that says the length, e.g. `Duration`"

  attr :hours_label, :string,
    required: true,
    doc: "writes a number of hours, `%{count}` filled in, e.g. `%{count} h`"

  attr :minutes_label, :string,
    required: true,
    doc: "writes a number of minutes, `%{count}` filled in, e.g. `%{count} min`"

  attr :step, :integer, default: 15, doc: "the minutes between two suggestions"

  attr :note, :string,
    default: nil,
    doc: "the line at the bottom, e.g. `Zone: America/Bahia (UTC-3) · 15 min steps`"

  attr :disabled, :boolean, default: false
  attr :class, :any, default: nil
  slot :icon, doc: "the clock icon of both fields; it gets 15px"
  attr :rest, :global

  def input(assigns) do
    assigns =
      assign(assigns,
        fields: [
          {"start", assigns.start_label, assigns.start_name, assigns.start_value},
          {"end", assigns.end_label, assigns.end_name, assigns.end_value}
        ]
      )

    ~H"""
    <div
      id={@id}
      phx-hook="DevactionUI.TimeField"
      data-step={@step}
      data-hours={@hours_label}
      data-minutes={@minutes_label}
      class={["flex flex-col gap-3.5", @class]}
      {@rest}
    >
      <div class="grid grid-cols-2 gap-2.5">
        <label
          :for={{side, label, name, value} <- @fields}
          class="flex flex-col gap-1.5 text-[13px] text-ink-2"
        >
          {label}
          <span class="flex h-10 items-center gap-2 rounded-[10px] border border-line-strong bg-card px-3 focus-within:border-ink focus-within:ring-[3px] focus-within:ring-ink/10 has-[:disabled]:opacity-50">
            <span
              :if={@icon != []}
              aria-hidden="true"
              class="grid size-[15px] flex-none place-items-center text-muted [&>*]:size-full"
            >
              {render_slot(@icon)}
            </span>
            <input
              type="text"
              name={name}
              value={value}
              data-time={side}
              inputmode="numeric"
              autocomplete="off"
              maxlength="5"
              disabled={@disabled}
              role="combobox"
              aria-autocomplete="list"
              aria-expanded="true"
              aria-controls={@id <> "-list"}
              class="min-w-0 flex-1 border-0 bg-transparent p-0 font-mono text-[15px] text-ink outline-none"
            />
          </span>
        </label>
      </div>
      <div
        id={@id <> "-list"}
        role="listbox"
        aria-label={@list_label}
        data-time-list
        phx-update="ignore"
        class="h-[252px] overflow-auto rounded-[10px] border border-line p-1"
      >
      </div>
      <div class="flex items-center justify-between rounded-[10px] bg-wrap p-3 text-sm">
        <span class="text-ink-2">{@duration_label}</span>
        <span
          id={@id <> "-length"}
          data-time-length
          phx-update="ignore"
          role="status"
          class="font-mono font-medium text-ink"
        ></span>
      </div>
      <p :if={@note} class="m-0 text-xs text-muted">{@note}</p>
    </div>
    """
  end
end
