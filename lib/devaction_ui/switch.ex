defmodule DevactionUI.Switch do
  @moduledoc """
  A switch for what takes effect at once, with no save button (for a choice that only counts after saving, use a
  checkbox). It is a `<button role="switch">`: `aria-checked` says the state, the keyboard toggles it and the
  caller does the work in its own `phx-click`. While the change is being kept, `saving` makes the thumb pulse and
  the control ignore presses; `saved_note/1` is the "saved now" the caller shows after.

  Colors: the default ink, `:ai` (amber) and `:ok` (green). Sizes: `:sm`, `:md`, `:lg`.
  """
  use Phoenix.Component

  attr :id, :string, required: true
  attr :checked, :boolean, default: false
  attr :size, :atom, values: [:sm, :md, :lg], default: :md
  attr :tone, :atom, values: [:default, :ai, :ok], default: :default

  attr :saving, :boolean,
    default: false,
    doc: "the change is being kept: the thumb pulses and presses are ignored"

  attr :disabled, :boolean, default: false
  attr :label, :string, default: nil, doc: "the accessible name when there is no visible one"
  attr :labelledby, :string, default: nil, doc: "the id of the text that names it"
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(phx-click phx-value-id phx-value-key phx-target)

  def switch(assigns) do
    ~H"""
    <button
      type="button"
      id={@id}
      role="switch"
      aria-checked={to_string(@checked)}
      aria-label={@label}
      aria-labelledby={@labelledby}
      aria-busy={@saving && "true"}
      aria-disabled={(@disabled or @saving) && "true"}
      class={["switch", size_class(@size), tone_class(@tone), @class]}
      {disabled_rest(@rest, @disabled or @saving)}
    ></button>
    """
  end

  defp disabled_rest(rest, true), do: Map.drop(rest, [:"phx-click"])
  defp disabled_rest(rest, false), do: rest

  defp size_class(:sm), do: "switch-sm"
  defp size_class(:md), do: nil
  defp size_class(:lg), do: "switch-lg"

  defp tone_class(:default), do: nil
  defp tone_class(:ai), do: "switch-ai"
  defp tone_class(:ok), do: "switch-ok"

  attr :id, :string, required: true
  attr :checked, :boolean, default: false
  attr :label, :string, required: true
  attr :description, :string, default: nil
  attr :tone, :atom, values: [:default, :ai, :ok], default: :default
  attr :saving, :boolean, default: false
  attr :disabled, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(phx-click phx-value-id phx-value-key phx-target)

  @doc "A row of settings: the label and its description on the left, the switch on the right."
  def switch_row(assigns) do
    ~H"""
    <div class={["switch-row", @class]}>
      <span class="flex min-w-0 flex-1 flex-col gap-0.5">
        <span id={"#{@id}-label"} class="font-medium text-ink">{@label}</span>
        <span :if={@description} class="text-[13px] text-muted">{@description}</span>
      </span>
      <.switch
        id={@id}
        checked={@checked}
        tone={@tone}
        saving={@saving}
        disabled={@disabled}
        labelledby={"#{@id}-label"}
        {@rest}
      />
    </div>
    """
  end

  attr :id, :string, required: true
  attr :checked, :boolean, default: false
  attr :label, :string, required: true
  attr :description, :string, default: nil
  attr :tone, :atom, values: [:default, :ai, :ok], default: :default
  attr :saving, :boolean, default: false
  attr :disabled, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(phx-click phx-value-id phx-value-key phx-target)
  slot :icon, doc: "a mark at the start of the card"

  @doc "A card that is the switch: it gets the border and the wash of \"on\" when the switch is on."
  def switch_card(assigns) do
    ~H"""
    <div class={["switch-card", @class]}>
      <span :if={@icon != []} class="size-5 shrink-0 text-ink-2">{render_slot(@icon)}</span>
      <span class="flex min-w-0 flex-1 flex-col gap-0.5">
        <span id={"#{@id}-label"} class="font-medium text-ink">{@label}</span>
        <span :if={@description} class="text-[13px] text-muted">{@description}</span>
      </span>
      <.switch
        id={@id}
        checked={@checked}
        tone={@tone}
        saving={@saving}
        disabled={@disabled}
        labelledby={"#{@id}-label"}
        {@rest}
      />
    </div>
    """
  end

  attr :id, :string, required: true
  attr :class, :any, default: nil
  slot :inner_block, required: true, doc: "the confirmation, such as \"Saved now\""
  slot :icon

  @doc "The confirmation of a change that was kept, read out by assistive technology without taking focus."
  attr :rest, :global

  def saved_note(assigns) do
    ~H"""
    <div
      id={@id}
      role="status"
      class={["flex items-center gap-2 text-[13px] text-tag-ok-text", @class]}
      {@rest}
    >
      {render_slot(@icon)}{render_slot(@inner_block)}
    </div>
    """
  end
end
