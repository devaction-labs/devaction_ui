defmodule DevactionUI.Steps do
  @moduledoc """
  A row of steps with connectors: done (ink, with a check), the current one (amber ring) and those still
  to come (a thin outline). `current` counts from 1; the labels are the caller's text.
  """
  use Phoenix.Component

  attr :labels, :list, required: true
  attr :current, :integer, required: true
  attr :class, :any, default: nil

  attr :rest, :global

  def steps(assigns) do
    ~H"""
    <ol class={["m-0 flex list-none items-center gap-2 p-0 text-sm", @class]} {@rest}>
      <%= for {label, index} <- Enum.with_index(@labels, 1) do %>
        <li
          aria-current={index == @current && "step"}
          class={["flex items-center gap-2", index > @current && "text-muted"]}
        >
          <span class={[
            "flex size-[22px] shrink-0 items-center justify-center rounded-full text-[11px]",
            index < @current && "bg-ink text-on-primary",
            index == @current && "border-2 border-ai text-ink",
            index > @current && "border border-line-strong"
          ]}>
            <span :if={index < @current} aria-hidden="true">✓</span>
            <span :if={index >= @current}>{index}</span>
          </span>
          <span class={index == @current && "font-medium text-ink"}>{label}</span>
        </li>
        <li :if={index < length(@labels)} aria-hidden="true" class="h-px min-w-6 flex-1 bg-line" />
      <% end %>
    </ol>
    """
  end
end
