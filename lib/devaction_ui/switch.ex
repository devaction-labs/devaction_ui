defmodule DevactionUI.Switch do
  @moduledoc """
  A switch for what takes effect at once, with no save button (for a choice that only counts after saving, use a
  checkbox). It is a `<button role="switch">`: `aria-checked` says the state, the keyboard toggles it and the
  caller does the work in its own `phx-click`. It writes no hidden input, so it does not take part in a form's
  submit: the state is the LiveView's, kept by the click. While the change is being kept, `saving` puts a
  spinner in the thumb and the control ignores presses; `saved_note/1` is the "saved now" the caller shows after.

  Colors: the default ink, `:ai` (amber) and `:ok` (green). Sizes: `:sm`, `:md`, `:lg`. The track has a hit
  area of 44px high; in `switch_row/1` and `switch_card/1` the text is a `<label>`, so pressing it toggles too.
  """
  use Phoenix.Component

  attr :id, :string, required: true
  attr :checked, :boolean, default: false
  attr :size, :atom, values: [:sm, :md, :lg], default: :md
  attr :tone, :atom, values: [:default, :ai, :ok], default: :default

  attr :saving, :boolean,
    default: false,
    doc: "the change is being kept: a spinner shows in the thumb and presses are ignored"

  attr :disabled, :boolean, default: false
  attr :label, :string, default: nil, doc: "the accessible name when there is no visible one"
  attr :labelledby, :string, default: nil, doc: "the id of the text that names it"
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(phx-click phx-value-id phx-value-key phx-target)

  slot :icon,
    doc:
      "a mark in the thumb, coloured by the tone (a check when on, a cross when off); gets `%{checked: boolean}`"

  @doc "The switch itself, a button that takes the press and says its state."
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
    >
      <span class="switch-thumb" aria-hidden="true">
        <span
          :if={@saving}
          class="size-2.5 animate-spin rounded-full border-2 border-current border-t-transparent motion-reduce:animate-none"
        ></span>
        {!@saving && render_slot(@icon, %{checked: @checked})}
      </span>
    </button>
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
  slot :thumb_icon, doc: "a mark in the thumb, as the `icon` of `switch/1`"

  @doc "A row of settings: the label and its description on the left, the switch on the right. A disabled row is dimmed whole."
  def switch_row(assigns) do
    ~H"""
    <div class={["switch-row", @class]} data-disabled={@disabled && "true"}>
      <label for={@id} class="flex min-w-0 flex-1 cursor-pointer flex-col gap-[3px]">
        <span id={"#{@id}-label"} class="font-medium text-ink">{@label}</span>
        <span
          :if={@description}
          id={"#{@id}-description"}
          class="text-[13px] leading-[1.45] text-muted"
        >
          {@description}
        </span>
      </label>
      <.switch
        id={@id}
        checked={@checked}
        tone={@tone}
        saving={@saving}
        disabled={@disabled}
        labelledby={"#{@id}-label"}
        aria-describedby={@description && "#{@id}-description"}
        class="mt-0.5"
        {@rest}
      >
        <:icon :let={state} :if={@thumb_icon != []}>{render_slot(@thumb_icon, state)}</:icon>
      </.switch>
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

  slot :icon,
    doc: "a mark in a 40px badge at the start of the card; it takes the colour of \"on\""

  slot :thumb_icon, doc: "a mark in the thumb, as the `icon` of `switch/1`"

  @doc "A card that is the switch: it gets the border and the wash of \"on\" when the switch is on."
  def switch_card(assigns) do
    ~H"""
    <div class={["switch-card", @class]} data-disabled={@disabled && "true"}>
      <span :if={@icon != []} class="switch-card-mark" aria-hidden="true">
        {render_slot(@icon)}
      </span>
      <label for={@id} class="flex min-w-0 flex-1 cursor-pointer flex-col gap-0.5">
        <span id={"#{@id}-label"} class="text-sm font-semibold text-ink">{@label}</span>
        <span
          :if={@description}
          id={"#{@id}-description"}
          class="text-xs leading-[1.45] text-muted"
        >
          {@description}
        </span>
      </label>
      <.switch
        id={@id}
        checked={@checked}
        tone={@tone}
        saving={@saving}
        disabled={@disabled}
        labelledby={"#{@id}-label"}
        aria-describedby={@description && "#{@id}-description"}
        {@rest}
      >
        <:icon :let={state} :if={@thumb_icon != []}>{render_slot(@thumb_icon, state)}</:icon>
      </.switch>
    </div>
    """
  end

  attr :id, :string, required: true

  attr :show, :boolean,
    default: true,
    doc:
      "whether the band with the text is there; the live region itself always is, so the text is announced when it comes in"

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true, doc: "the confirmation, such as \"Saved now\""
  slot :icon

  @doc "The confirmation of a change that was kept, read out by assistive technology without taking focus. Render it always and flip `show`."
  def saved_note(assigns) do
    ~H"""
    <div id={@id} role="status" {@rest}>
      <div
        :if={@show}
        class={[
          "flex items-center gap-2 rounded-[10px] border border-ok-line bg-ok-bg px-3 py-2.5 text-[13px] text-ok-fg",
          @class
        ]}
      >
        {render_slot(@icon)}{render_slot(@inner_block)}
      </div>
    </div>
    """
  end
end
