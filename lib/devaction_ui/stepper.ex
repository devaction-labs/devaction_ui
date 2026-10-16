defmodule DevactionUI.Stepper do
  @moduledoc """
  The steps of an onboarding or of a creation wizard, with the state of each: `:done`, `:current`, `:error` and
  `:todo`. Horizontal, each step is a bar over a dot, a label and a line of help; vertical, it is a checklist with
  a rail. The current step carries `aria-current="step"`, and the state is also written (not only coloured) for
  assistive technology.
  """
  use Phoenix.Component

  @type state :: :done | :current | :error | :todo

  @doc "The state of each step of `labels` when the wizard is at `current` (counting from 1), with `error` the step that failed."
  @spec states(pos_integer(), pos_integer(), pos_integer() | nil) :: [state()]
  def states(total, current, error \\ nil) do
    for index <- 1..total//1 do
      cond do
        index == error -> :error
        index < current -> :done
        index == current -> :current
        true -> :todo
      end
    end
  end

  attr :id, :string, required: true
  attr :orientation, :atom, values: [:horizontal, :vertical], default: :horizontal
  attr :class, :any, default: nil

  attr :state_labels, :map,
    required: true,
    doc: "`%{done: .., current: .., error: .., todo: ..}`, read out"

  slot :step, required: true do
    attr :state, :atom, required: true
    attr :label, :string, required: true
    attr :help, :string
  end

  attr :rest, :global
  slot :done_icon, doc: "replaces the typographic ✓ of a finished step"

  def stepper(%{orientation: :horizontal} = assigns) do
    ~H"""
    <ol id={@id} class={["stepper m-0 p-0", @class]} {@rest}>
      <li
        :for={{step, index} <- Enum.with_index(@step, 1)}
        class="step"
        data-state={step.state}
        aria-current={step.state == :current && "step"}
      >
        <span class="flex items-center gap-2.5">
          <span class="step-dot">{dot(step.state, index) || render_slot(@done_icon) || "✓"}</span>
          <span class="flex min-w-0 flex-col">
            <span class="text-sm font-medium text-ink">
              {step.label}<span class="sr-only"> · {@state_labels[step.state]}</span>
            </span>
            <span :if={Map.get(step, :help)} class="text-xs text-muted">{step.help}</span>
          </span>
        </span>
      </li>
    </ol>
    """
  end

  def stepper(assigns) do
    ~H"""
    <ol id={@id} class={["m-0 flex list-none flex-col p-0", @class]} {@rest}>
      <li
        :for={{step, index} <- Enum.with_index(@step, 1)}
        class="step-row relative flex gap-3 [&:last-child_.step-text]:pb-0"
        data-state={step.state}
        aria-current={step.state == :current && "step"}
      >
        <span class="relative flex flex-col items-center">
          <span class="step-dot" data-state={step.state}>{dot(step.state, index) ||
            render_slot(@done_icon) || "✓"}</span>
          <span
            :if={index < length(@step)}
            class={[
              "mt-1 w-px flex-1",
              (step.state == :done && "bg-ink") || "bg-line"
            ]}
            aria-hidden="true"
          />
        </span>
        <span class="step-text flex min-w-0 flex-col pt-0.5 pb-5">
          <span class={["text-sm font-medium", (step.state == :todo && "text-muted") || "text-ink"]}>
            {step.label}<span class="sr-only"> · {@state_labels[step.state]}</span>
          </span>
          <span :if={Map.get(step, :help)} class="text-xs text-muted">{step.help}</span>
        </span>
      </li>
    </ol>
    """
  end

  defp dot(:done, _index), do: nil
  defp dot(:error, _index), do: "!"
  defp dot(_state, index), do: index
end
