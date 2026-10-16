defmodule DevactionUI.Segmented do
  @moduledoc """
  A control to pick one of a few options that change the view at once (list or board, week or month): a pill with
  a segment per option. It is a `group` of toggle buttons with `aria-pressed`; the caller keeps the value and
  learns of a choice through `event` (`phx-value-value`). A segment can have an icon, a count, or only an icon
  (the label is then read by assistive technology). `full` stretches it to the width of its box. An option can
  be `disabled`, take its own `class`, and send `patch` or `navigate` (a path) instead of the `event`, for a
  filter that lives in the URL.

  The segments stay toggle buttons with `aria-pressed`; the `DevactionUI.Segmented` hook only eases the
  keyboard: one segment is in the Tab order (the pressed one, or the first that is not disabled) and the arrow
  keys, Home and End move the focus round the others, skipping disabled ones. Moving the focus does not choose:
  Enter or Space presses, as for any button.

  The segments are 34px high (`:md`) and 28px (`:sm`), as the canvas draws them: on a touch screen give the
  control room around it or use `:md` with `full`.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  attr :id, :string, required: true
  attr :label, :string, required: true, doc: "what the control chooses, for assistive technology"
  attr :value, :string, required: true, doc: "the value of the chosen option"

  attr :event, :string,
    default: nil,
    doc:
      "the event sent with `value` when an option is pressed; an option with `patch` or `navigate` sends none"

  attr :size, :atom, values: [:sm, :md], default: :md
  attr :full, :boolean, default: false
  attr :class, :any, default: nil

  slot :option, required: true do
    attr :value, :string, required: true
    attr :label, :string, required: true
    attr :count, :any
    attr :icon_only, :boolean
    attr :disabled, :boolean
    attr :class, :any
    attr :patch, :string, doc: "a path to patch to instead of sending the event"
    attr :navigate, :string, doc: "a path to navigate to instead of sending the event"
  end

  slot :icon, doc: "the icon of an option; gets `%{value: option value}`"

  attr :target, :any,
    default: nil,
    doc: "a `phx-target` (a `@myself`) when used inside a LiveComponent"

  attr :rest, :global

  def segmented(assigns) do
    assigns = assign(assigns, :stop, tab_stop(assigns.option, assigns.value))

    ~H"""
    <div
      id={@id}
      role="group"
      aria-label={@label}
      phx-hook="DevactionUI.Segmented"
      class={["segmented", @size == :sm && "segmented-sm", @full && "segmented-full", @class]}
      {@rest}
    >
      <button
        :for={option <- @option}
        id={"#{@id}-#{option.value}"}
        type="button"
        tabindex={tab_index(option, @stop)}
        aria-pressed={to_string(option.value == @value)}
        aria-label={Map.get(option, :icon_only) && option.label}
        disabled={Map.get(option, :disabled)}
        phx-click={click(option, @event)}
        phx-target={@target}
        phx-value-value={option.value}
        class={[
          "segment outline-none focus-visible:ring-4 focus-visible:ring-ink/10",
          Map.get(option, :icon_only) && "w-9 px-0",
          Map.get(option, :class)
        ]}
      >
        {render_slot(@icon, %{value: option.value})}
        <span :if={!Map.get(option, :icon_only)}>{option.label}</span>
        <span :if={Map.get(option, :count)} class="font-mono text-[11px] text-muted">
          {option.count}
        </span>
      </button>
    </div>
    """
  end

  defp tab_stop(options, value) do
    open = Enum.reject(options, &Map.get(&1, :disabled))
    Enum.find(open, &(&1.value == value)) || List.first(open)
  end

  defp tab_index(option, option), do: "0"
  defp tab_index(_option, _stop), do: "-1"

  defp click(%{patch: path}, _event), do: JS.patch(path)
  defp click(%{navigate: path}, _event), do: JS.navigate(path)
  defp click(_option, event), do: event
end
