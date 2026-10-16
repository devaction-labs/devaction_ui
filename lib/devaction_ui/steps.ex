defmodule DevactionUI.Steps do
  @moduledoc """
  A row of steps with connectors: done (ink, with a check), the current one (amber ring) and those still
  to come (a thin outline). `current` counts from 1; the labels are the caller's text.

  A `current` below 1 leaves every step to come and one past the last leaves every step done. There is no
  error state here: a wizard whose steps can fail uses `DevactionUI.Stepper`. The connectors have a minimum
  width of 24px so a long row wraps its labels instead of squeezing them.
  """
  use Phoenix.Component

  attr :labels, :list, required: true, doc: "the text of each step, in order"
  attr :current, :integer, required: true, doc: "the step the person is on, counting from 1"
  attr :class, :any, default: nil

  attr :rest, :global
  slot :done_icon, doc: "replaces the typographic ✓ of a finished step"

  @doc "The row of steps."
  @spec steps(map()) :: Phoenix.LiveView.Rendered.t()
  def steps(assigns) do
    ~H"""
    <ol class={["m-0 flex list-none items-center gap-2 p-0 text-[13px]", @class]} {@rest}>
      <%= for {label, index} <- Enum.with_index(@labels, 1) do %>
        <li
          aria-current={index == @current && "step"}
          class={["flex items-center gap-2", index > @current && "text-muted"]}
        >
          <span class={[
            "flex size-[22px] shrink-0 items-center justify-center rounded-full text-[11px]",
            index < @current && "bg-ink text-on-primary",
            index == @current && "border-2 border-ai",
            index > @current && "border border-done-cell"
          ]}>
            <span :if={index < @current} aria-hidden="true">{render_slot(@done_icon) || "✓"}</span>
            <span :if={index >= @current}>{index}</span>
          </span>
          <span class={index == @current && "font-semibold text-ink"}>{label}</span>
        </li>
        <li
          :if={index < length(@labels)}
          aria-hidden="true"
          class={["h-px min-w-6 flex-1", (index < @current && "bg-ink") || "bg-line"]}
        />
      <% end %>
    </ol>
    """
  end
end
