defmodule DevactionUI.Timer do
  @moduledoc """
  A timer of hours for a task: a small caption of its state, the time in large mono digits, what is being timed, and two round buttons: start or pause, and stop and log. The
  LiveView owns the truth (it is not lost on a reload): the seconds already counted (`base`) and, while it runs,
  the moment it started (`started_at`, in seconds since the epoch). The browser only draws the passing seconds
  between two updates (`DevactionUI.Timer` hook); `elapsed/3` is what the server counts when it logs.
  """
  use Phoenix.Component

  @doc "The seconds counted: `base` plus, while running, the time since `started_at`."
  @spec elapsed(non_neg_integer(), integer() | nil, integer()) :: non_neg_integer()
  def elapsed(base, nil, _now), do: base
  def elapsed(base, started_at, now), do: base + max(now - started_at, 0)

  @doc "Seconds as `H:MM:SS`."
  @spec format(non_neg_integer()) :: String.t()
  def format(seconds) do
    hours = div(seconds, 3600)
    minutes = seconds |> rem(3600) |> div(60)
    "#{hours}:#{pad(minutes)}:#{pad(rem(seconds, 60))}"
  end

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
          aria-pressed={to_string(@running?)}
          aria-label={(@running? && @pause_label) || @start_label}
          class={[
            "grid size-13 place-items-center rounded-full text-white outline-none hover:opacity-90 focus-visible:ring-4 focus-visible:ring-ink/10",
            (@running? && "bg-ink text-on-primary") || "bg-[#15803D]"
          ]}
        >
          {(@running? && render_slot(@pause_icon)) || render_slot(@start_icon)}
        </button>
        <button
          id={"#{@id}-log"}
          type="button"
          phx-click={@log_event}
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
end
