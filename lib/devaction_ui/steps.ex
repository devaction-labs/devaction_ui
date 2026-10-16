defmodule DevactionUI.Steps do
  @moduledoc """
  A row of steps with connectors: done (ink, with a check), the current one (amber ring) and those still
  to come (a thin outline). `current` counts from 1; the labels are the caller's text.

  A `current` below 1 leaves every step to come and one past the last leaves every step done. The step named
  by `error` is drawn with a red ring and keeps its number (or the `error_icon`), whatever its place relative
  to `current`; give an `error_label` so assistive technology reads that it failed. A wizard that needs help
  lines and a vertical layout uses `DevactionUI.Stepper`. The connectors have a minimum width of 24px so a
  long row wraps its labels instead of squeezing them.
  """
  use Phoenix.Component

  attr :labels, :list, required: true, doc: "the text of each step, in order"
  attr :current, :integer, required: true, doc: "the step the person is on, counting from 1"

  attr :error, :integer,
    default: nil,
    doc: "the step that failed, counting from 1; it wins over `current`"

  attr :error_label, :string,
    default: nil,
    doc: "read out after the label of the failed step, such as `Failed`"

  attr :class, :any, default: nil

  attr :rest, :global
  slot :done_icon, doc: "replaces the typographic ✓ of a finished step"
  slot :error_icon, doc: "replaces the number in the dot of the failed step"

  @doc "The row of steps."
  @spec steps(map()) :: Phoenix.LiveView.Rendered.t()
  def steps(assigns) do
    entries =
      for {label, index} <- Enum.with_index(assigns.labels, 1),
          do: {label, index, state(index, assigns.current, assigns.error)}

    assigns = assign(assigns, :entries, entries)

    ~H"""
    <ol class={["m-0 flex list-none items-center gap-2 p-0 text-[13px]", @class]} {@rest}>
      <%= for {label, index, state} <- @entries do %>
        <li
          aria-current={state == :current && "step"}
          class={["flex items-center gap-2", state == :todo && "text-muted"]}
        >
          <span class={[
            "flex size-[22px] shrink-0 items-center justify-center rounded-full text-[11px]",
            dot_class(state)
          ]}>
            <span :if={state == :done} aria-hidden="true">{render_slot(@done_icon) || "✓"}</span>
            <span :if={state == :error and @error_icon != []}>{render_slot(@error_icon)}</span>
            <span :if={state != :done and not (state == :error and @error_icon != [])}>{index}</span>
          </span>
          <span class={label_class(state)}>
            {label}<span :if={state == :error and @error_label} class="sr-only"> · {@error_label}</span>
          </span>
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

  defp state(index, _current, index), do: :error
  defp state(index, current, _error) when index < current, do: :done
  defp state(index, index, _error), do: :current
  defp state(_index, _current, _error), do: :todo

  defp dot_class(:done), do: "bg-ink text-on-primary"
  defp dot_class(:current), do: "border-2 border-ai"
  defp dot_class(:error), do: "border-2 border-missing text-missing"
  defp dot_class(:todo), do: "border border-line-dashed"

  defp label_class(:current), do: "font-semibold text-ink"
  defp label_class(:error), do: "text-tag-risk-text"
  defp label_class(_state), do: nil
end
