defmodule DevactionUI.Stepper do
  @moduledoc """
  The steps of an onboarding or of a creation wizard, with the state of each: `:done`, `:current`, `:error` and
  `:todo`. Horizontal, each step is a bar over a dot, a label and a line of help; vertical, it is a checklist with
  a rail. The current step carries `aria-current="step"`, and the state is also written (not only coloured) for
  assistive technology.

  A step that failed keeps its number in the dot (or the `error_icon`) and its label turns red; when the failed
  step is also the one the wizard is at, `states/3` gives `:error`, never `:current`. The vertical checklist
  has no numbers: its dots hold the check of a finished step, the `error_icon` of a failed one, and are
  otherwise empty rings (the state is still written out for assistive technology). `state_labels` must carry
  the four keys, or the component raises.
  """
  use Phoenix.Component

  @type state :: :done | :current | :error | :todo

  @state_keys [:done, :current, :error, :todo]

  @doc "The state of each step of `labels` when the wizard is at `current` (counting from 1), with `error` the step that failed. The error wins over the current step."
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
    doc: "`%{done: .., current: .., error: .., todo: ..}`, read out; all four keys are required"

  slot :step, required: true do
    attr :state, :atom, required: true, doc: "`:done`, `:current`, `:error` or `:todo`"
    attr :label, :string, required: true
    attr :help, :string, doc: "a line of help under the label"
  end

  attr :rest, :global
  slot :done_icon, doc: "replaces the typographic ✓ of a finished step"
  slot :error_icon, doc: "replaces the number in the dot of a step that failed"

  @doc "The steps of a wizard, horizontal or as a vertical checklist."
  @spec stepper(map()) :: Phoenix.LiveView.Rendered.t()
  def stepper(assigns) do
    assigns |> assign(:state_labels, check_labels!(assigns.state_labels)) |> layout()
  end

  defp layout(%{orientation: :horizontal} = assigns) do
    ~H"""
    <ol id={@id} class={["stepper m-0 p-0", @class]} {@rest}>
      <li
        :for={{step, index} <- Enum.with_index(@step, 1)}
        class="step"
        data-state={step.state}
        aria-current={step.state == :current && "step"}
      >
        <span class="flex items-center gap-2.5">
          <span class="step-dot">
            <.mark state={step.state} index={index} done_icon={@done_icon} error_icon={@error_icon} />
          </span>
          <span class="flex min-w-0 flex-col">
            <span class={["text-sm", label_class(step.state)]}>
              {step.label}<span class="sr-only"> · {@state_labels[step.state]}</span>
            </span>
            <span :if={Map.get(step, :help)} class="text-xs text-muted">{step.help}</span>
          </span>
        </span>
      </li>
    </ol>
    """
  end

  defp layout(assigns) do
    ~H"""
    <ol id={@id} class={["m-0 flex list-none flex-col p-0", @class]} {@rest}>
      <li
        :for={{step, index} <- Enum.with_index(@step, 1)}
        class="step-row relative flex gap-3 [&:last-child_.step-text]:pb-0"
        data-state={step.state}
        aria-current={step.state == :current && "step"}
      >
        <span class="relative flex flex-col items-center">
          <span class="step-dot size-6" data-state={step.state}>
            <.rail_mark state={step.state} done_icon={@done_icon} error_icon={@error_icon} />
          </span>
          <span
            :if={index < length(@step)}
            class={[
              "mt-1 w-0.5 flex-1",
              (step.state == :done && "bg-ink") || "bg-line"
            ]}
            aria-hidden="true"
          />
        </span>
        <span class="step-text flex min-w-0 flex-col pt-0.5 pb-4">
          <span class={["text-[13px]", label_class(step.state)]}>
            {step.label}<span class="sr-only"> · {@state_labels[step.state]}</span>
          </span>
          <span :if={Map.get(step, :help)} class="text-xs text-muted">{step.help}</span>
        </span>
      </li>
    </ol>
    """
  end

  attr :state, :atom, required: true
  attr :index, :integer, required: true
  attr :done_icon, :list, required: true
  attr :error_icon, :list, required: true

  defp mark(%{state: :done} = assigns) do
    ~H"""
    {render_slot(@done_icon) || "✓"}
    """
  end

  defp mark(%{state: :error, error_icon: [_ | _]} = assigns) do
    ~H"""
    {render_slot(@error_icon)}
    """
  end

  defp mark(assigns) do
    ~H"""
    {@index}
    """
  end

  attr :state, :atom, required: true
  attr :done_icon, :list, required: true
  attr :error_icon, :list, required: true

  defp rail_mark(%{state: :done} = assigns) do
    ~H"""
    {render_slot(@done_icon) || "✓"}
    """
  end

  defp rail_mark(%{state: :error, error_icon: [_ | _]} = assigns) do
    ~H"""
    {render_slot(@error_icon)}
    """
  end

  defp rail_mark(assigns), do: ~H""

  defp label_class(:current), do: "font-semibold text-ink"
  defp label_class(:error), do: "font-medium text-tag-risk-text"
  defp label_class(:todo), do: "font-medium text-muted"
  defp label_class(:done), do: "font-medium text-ink"

  defp check_labels!(labels) do
    case Enum.all?(@state_keys, &Map.has_key?(labels, &1)) do
      true ->
        labels

      false ->
        raise ArgumentError,
              "Stepper state_labels needs the keys #{inspect(@state_keys)}, got: #{inspect(labels)}"
    end
  end
end
