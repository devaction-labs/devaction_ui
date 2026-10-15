defmodule DevactionUI.Segmented do
  @moduledoc """
  A control to pick one of a few options that change the view at once (list or board, week or month): a pill with
  a segment per option. It is a `group` of toggle buttons with `aria-pressed`; the caller keeps the value and
  learns of a choice through `event` (`phx-value-value`). A segment can have an icon, a count, or only an icon
  (the label is then read by assistive technology). `full` stretches it to the width of its box.
  """
  use Phoenix.Component

  attr :id, :string, required: true
  attr :label, :string, required: true, doc: "what the control chooses, for assistive technology"
  attr :value, :string, required: true, doc: "the value of the chosen option"

  attr :event, :string,
    required: true,
    doc: "the event sent with `value` when an option is pressed"

  attr :size, :atom, values: [:sm, :md], default: :md
  attr :full, :boolean, default: false
  attr :class, :any, default: nil

  slot :option, required: true do
    attr :value, :string, required: true
    attr :label, :string, required: true
    attr :count, :any
    attr :icon_only, :boolean
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
      class={["segmented", @full && "segmented-full", @class]}
      {@rest}
    >
      <button
        :for={option <- @option}
        id={"#{@id}-#{option.value}"}
        type="button"
        aria-pressed={to_string(option.value == @value)}
        aria-label={Map.get(option, :icon_only) && option.label}
        phx-click={@event}
        phx-target={@target}
        phx-value-value={option.value}
        class={[
          "segment outline-none focus-visible:ring-4 focus-visible:ring-ink/10",
          @size == :sm && "h-7 px-2.5 text-[13px]",
          Map.get(option, :icon_only) && "w-9 px-0"
        ]}
      >
        {render_slot(@icon, %{value: option.value})}
        <span :if={!Map.get(option, :icon_only)}>{option.label}</span>
        <span
          :if={Map.get(option, :count)}
          class="rounded-md bg-wrap px-1.5 font-mono text-[11px] text-muted"
        >
          {option.count}
        </span>
      </button>
    </div>
    """
  end
end
