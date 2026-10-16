defmodule DevactionUI.Timer do
  @moduledoc """
  A timer of hours for a task: a small caption of its state, the time in large mono digits, what is being timed, and two round buttons: start or pause, and stop and log. The
  LiveView owns the truth (it is not lost on a reload): the seconds already counted (`base`) and, while it runs,
  the moment it started (`started_at`, in seconds since the epoch). The browser only draws the passing seconds
  between two updates (`DevactionUI.Timer` hook); `elapsed/3` is what the server counts when it logs.
  The stop-and-log button stays disabled while nothing has been counted (`log_event` is not sent then).

  `timer_mini/1` is the same clock made small for the bar of the app: a dot (green while it runs) and `HH:MM` in
  mono, drawn by the same hook. `time_log/1` is the list of what was logged today, each entry with its time in mono
  on the right (`HH:MM`, or what the `duration` function of the caller makes of the seconds).
  """
  use Phoenix.Component

  @doc "The seconds counted: `base` plus, while running, the time since `started_at`."
  @spec elapsed(non_neg_integer(), integer() | nil, integer()) :: non_neg_integer()
  def elapsed(base, nil, _now), do: base
  def elapsed(base, started_at, now), do: base + max(now - started_at, 0)

  @doc "Seconds as `HH:MM:SS`."
  @spec format(non_neg_integer()) :: String.t()
  def format(seconds) do
    hours = div(seconds, 3600)
    minutes = seconds |> rem(3600) |> div(60)
    "#{pad(hours)}:#{pad(minutes)}:#{pad(rem(seconds, 60))}"
  end

  @doc "Seconds as `HH:MM`, the seconds dropped."
  @spec format_short(non_neg_integer()) :: String.t()
  def format_short(seconds), do: seconds |> format() |> String.slice(0, 5)

  defp state(true), do: "running"
  defp state(false), do: "paused"

  defp pad(number), do: number |> Integer.to_string() |> String.pad_leading(2, "0")

  attr :id, :string, required: true
  attr :base, :integer, required: true, doc: "seconds counted before the last start"

  attr :started_at, :integer,
    default: nil,
    doc: "when it was started (seconds since the epoch); nil when paused"

  attr :now, :integer,
    default: nil,
    doc: "the server's clock in seconds; read when the component is drawn (given only in tests)"

  attr :label, :string, required: true, doc: "what is timed, e.g. `Time on DIA-142`"
  attr :toggle_event, :string, required: true, doc: "sent by the start/pause button"
  attr :log_event, :string, required: true, doc: "sent by the log button"

  attr :start_label, :string,
    required: true,
    doc: "names the start button for assistive technology"

  attr :pause_label, :string,
    required: true,
    doc: "names the pause button for assistive technology"

  attr :log_label, :string,
    required: true,
    doc: "names the stop-and-log button for assistive technology"

  attr :running_text, :string,
    default: nil,
    doc: "the small caption while it runs, e.g. `RUNNING`"

  attr :paused_text, :string,
    default: nil,
    doc: "the small caption while it is paused, e.g. `PAUSED`"

  attr :class, :any, default: nil
  slot :start_icon, doc: "the icon of the round start button"
  slot :pause_icon, doc: "the icon of the round pause button"
  slot :log_icon, doc: "the icon of the round stop-and-log button"

  attr :target, :any,
    default: nil,
    doc: "a `phx-target` (a `@myself`) when used inside a LiveComponent"

  attr :rest, :global

  def timer(assigns) do
    now = assigns.now || System.os_time(:second)
    seconds = elapsed(assigns.base, assigns.started_at, now)
    assigns = assign(assigns, now: now, seconds: seconds, running?: assigns.started_at != nil)

    ~H"""
    <div
      id={@id}
      phx-hook="DevactionUI.Timer"
      data-base={@base}
      data-started-at={@started_at}
      data-now={@now}
      data-running={to_string(@running?)}
      data-state={state(@running?)}
      role="group"
      aria-label={@label}
      class={["timer", @class]}
      {@rest}
    >
      <span
        :if={@running_text || @paused_text}
        data-kicker
        class={[
          "font-mono text-[11px] tracking-[0.08em] uppercase",
          (@running? && "text-ok-fg") || "text-muted"
        ]}
      >
        {(@running? && @running_text) || @paused_text}
      </span>
      <span class="timer-time" role="timer" aria-live="off">
        <span data-time phx-update="ignore" id={"#{@id}-time"}>{format(@seconds)}</span>
      </span>
      <span class="text-[13px] text-ink-2">{@label}</span>
      <div class="mt-2 flex items-center gap-2">
        <button
          id={"#{@id}-toggle"}
          type="button"
          phx-click={@toggle_event}
          phx-target={@target}
          aria-label={(@running? && @pause_label) || @start_label}
          class={[
            "grid size-13 place-items-center rounded-full outline-none hover:opacity-90 focus-visible:ring-4 focus-visible:ring-ink/10",
            (@running? && "bg-ink text-on-primary") || "bg-ok-fg text-on-finding"
          ]}
        >
          {(@running? && render_slot(@pause_icon)) || render_slot(@start_icon)}
        </button>
        <button
          id={"#{@id}-log"}
          type="button"
          phx-click={@log_event}
          phx-target={@target}
          disabled={@seconds == 0}
          aria-label={@log_label}
          class="grid size-13 place-items-center rounded-full border border-line-strong bg-card text-ink outline-none hover:bg-wrap focus-visible:ring-4 focus-visible:ring-ink/10 disabled:cursor-not-allowed disabled:opacity-40"
        >
          {render_slot(@log_icon)}
        </button>
      </div>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :base, :integer, required: true, doc: "seconds counted before the last start"

  attr :started_at, :integer,
    default: nil,
    doc: "when it was started (seconds since the epoch); nil when paused"

  attr :now, :integer, default: nil, doc: "the server's clock in seconds; given only in tests"

  attr :label, :string,
    required: true,
    doc: "names the clock for assistive technology, e.g. `Timer running`"

  attr :class, :any, default: nil
  attr :rest, :global, doc: "e.g. `phx-click`"

  def timer_mini(assigns) do
    now = assigns.now || System.os_time(:second)
    seconds = elapsed(assigns.base, assigns.started_at, now)
    assigns = assign(assigns, now: now, seconds: seconds, running?: assigns.started_at != nil)

    ~H"""
    <span
      id={@id}
      phx-hook="DevactionUI.Timer"
      data-base={@base}
      data-started-at={@started_at}
      data-now={@now}
      data-format="short"
      data-running={to_string(@running?)}
      data-state={state(@running?)}
      role="group"
      aria-label={@label}
      class={["inline-flex items-center gap-2.5", @class]}
      {@rest}
    >
      <span
        aria-hidden="true"
        class={["size-2 shrink-0 rounded-full", (@running? && "bg-ok-fg") || "bg-muted-2"]}
      />
      <span role="timer" aria-live="off" class="font-mono text-[13px] tabular-nums">
        <span data-time phx-update="ignore" id={"#{@id}-time"}>{format_short(@seconds)}</span>
      </span>
    </span>
    """
  end

  attr :id, :string, required: true
  attr :title, :string, required: true, doc: "the caption of the list, e.g. `LOGGED TODAY`"
  attr :entries, :list, required: true, doc: "`%{id, label, seconds}` each"

  attr :duration, :any,
    default: nil,
    doc: "a function of the seconds returning the text of the time; `HH:MM` when nil"

  attr :class, :any, default: nil
  attr :rest, :global

  def time_log(assigns) do
    ~H"""
    <section
      id={@id}
      aria-labelledby={"#{@id}-title"}
      class={["flex flex-col gap-0.5", @class]}
      {@rest}
    >
      <h4
        id={"#{@id}-title"}
        class="m-0 pb-1 font-mono text-[11px] font-normal tracking-[0.08em] text-muted uppercase"
      >
        {@title}
      </h4>
      <ul class="m-0 flex list-none flex-col p-0">
        <li
          :for={entry <- @entries}
          id={"#{@id}-#{entry.id}"}
          class="flex justify-between gap-2.5 border-t border-line-soft py-2 text-[13px]"
        >
          <span class="min-w-0 truncate text-ink-2">{entry.label}</span>
          <span class="shrink-0 font-mono text-ink">{duration(@duration, entry.seconds)}</span>
        </li>
      </ul>
    </section>
    """
  end

  defp duration(nil, seconds), do: format_short(seconds)
  defp duration(fun, seconds), do: fun.(seconds)
end
