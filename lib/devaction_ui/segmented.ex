defmodule DevactionUI.Segmented do
  @moduledoc """
  A control to pick one of a few options that change the view at once (list or board, week or month): a pill with
  a segment per option. It is a `group` of toggle buttons with `aria-pressed`; the caller keeps the value and
  learns of a choice through `event` (`phx-value-value`). A segment can have an icon, a count, or only an icon
  (the label is then read by assistive technology). `full` stretches it to the width of its box. An option can
  be `disabled`, take its own `class`, and send `patch` or `navigate` (a path) instead of the `event`, for a
  filter that lives in the URL.

  The segments are toggle buttons, one stop each in the Tab order, not a radio group with arrow keys. They are
  34px high (`:md`) and 28px (`:sm`), as the canvas draws them: on a touch screen give the control room around
  it or use `:md` with `full`.
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
    ~H"""
    <div
      id={@id}
      role="group"
      aria-label={@label}
      class={["segmented", @size == :sm && "segmented-sm", @full && "segmented-full", @class]}
      {@rest}
    >
      <button
        :for={option <- @option}
        id={"#{@id}-#{option.value}"}
        type="button"
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

  defp click(%{patch: path}, _event), do: JS.patch(path)
  defp click(%{navigate: path}, _event), do: JS.navigate(path)
  defp click(_option, event), do: event
end
