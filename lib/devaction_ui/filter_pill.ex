defmodule DevactionUI.FilterPill do
  @moduledoc """
  The round pills of a filter bar: on or off, with a ×, and the dashed one that adds a filter.

  `filter_pill/1` is a filter that is on or off (`active` fills it with ink; `tone={:warn}` is the amber one for
  what needs a look) and, with `remove_event`, carries a × that takes it away; `add_pill/1` is the dashed
  "+ Filter" that opens the choice of a new one. They are the canvas's "pills com estado".

  A pill is a toggle button with `aria-pressed`; the caller keeps the state and learns of a press through
  `event` (`phx-value-value`, the `value` or the label). The × is a second button named by `remove_label`,
  where `%{label}` is the text of the pill, so a screen reader hears "Remove SGE" and not N equal buttons. For
  the field where the person types the pills, see `DevactionUI.Pillbox`.
  """
  use Phoenix.Component

  attr :id, :string, default: nil
  attr :label, :string, required: true
  attr :value, :string, default: nil, doc: "sent as `phx-value-value`; the label when not given"
  attr :active, :boolean, default: false, doc: "the filter is on: filled with ink"

  attr :tone, :atom,
    values: [:neutral, :warn],
    default: :neutral,
    doc: "the look of an inactive pill; `:warn` is the amber one"

  attr :event, :string, default: nil, doc: "sent when the pill is pressed"
  attr :remove_event, :string, default: nil, doc: "shows the × and is sent when it is pressed"

  attr :remove_label, :string,
    default: nil,
    doc: "names the ×, as in `\"Remove %{label}\"`; required with `remove_event`"

  attr :target, :any,
    default: nil,
    doc: "a `phx-target` (a `@myself`) when used inside a LiveComponent"

  attr :class, :any, default: nil
  attr :rest, :global
  slot :icon, doc: "a mark before the label"
  slot :remove_icon, doc: "replaces the typographic × that removes the pill"

  def filter_pill(assigns) do
    ~H"""
    <span
      id={@id}
      data-active={@active && "true"}
      class={[
        "inline-flex h-[30px] items-center gap-1.5 rounded-full border text-[13px]",
        look(@active, @tone),
        @remove_event && "pr-1",
        @class
      ]}
      {@rest}
    >
      <button
        type="button"
        aria-pressed={to_string(@active)}
        phx-click={@event}
        phx-target={@target}
        phx-value-value={@value || @label}
        class={[
          "inline-flex h-full cursor-pointer items-center gap-1.5 rounded-full bg-transparent pl-2.5 text-inherit outline-none focus-visible:ring-4 focus-visible:ring-ink/10",
          label_padding(@remove_event)
        ]}
      >
        <span :if={@icon != []} aria-hidden="true">{render_slot(@icon)}</span>
        {@label}
      </button>
      <button
        :if={@remove_event}
        type="button"
        aria-label={fill_label(@remove_label, @label)}
        phx-click={@remove_event}
        phx-target={@target}
        phx-value-value={@value || @label}
        class="grid size-[22px] cursor-pointer place-items-center rounded-full bg-transparent text-inherit opacity-70 outline-none hover:opacity-100 focus-visible:ring-2 focus-visible:ring-ink/20"
      >
        <span aria-hidden="true">{render_slot(@remove_icon) || "×"}</span>
      </button>
    </span>
    """
  end

  attr :label, :string, required: true, doc: "what it adds, such as \"Filter\""
  attr :event, :string, default: nil, doc: "sent when the pill is pressed"
  attr :target, :any, default: nil, doc: "a `phx-target` (a `@myself`) inside a LiveComponent"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :icon, doc: "replaces the typographic + before the label"

  def add_pill(assigns) do
    ~H"""
    <button
      type="button"
      phx-click={@event}
      phx-target={@target}
      class={[
        "inline-flex h-[30px] cursor-pointer items-center gap-1.5 rounded-full border border-dashed border-line-dashed bg-transparent px-2.5 text-[13px] text-ink-2 outline-none hover:border-ink hover:text-ink focus-visible:ring-4 focus-visible:ring-ink/10",
        @class
      ]}
      {@rest}
    >
      <span aria-hidden="true">{render_slot(@icon) || "+"}</span>
      {@label}
    </button>
    """
  end

  defp label_padding(nil), do: "pr-2.5"
  defp label_padding(_remove_event), do: "pr-0.5"

  defp look(true, _tone), do: "border-ink bg-ink text-on-primary"
  defp look(false, :neutral), do: "border-line-strong bg-transparent text-ink"
  defp look(false, :warn), do: "border-warn-line bg-warn-bg text-warn-fg"

  defp fill_label(nil, _label), do: nil
  defp fill_label(pattern, label), do: String.replace(pattern, "%{label}", label)
end
