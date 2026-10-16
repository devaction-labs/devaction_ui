defmodule DevactionUI.Badge do
  @moduledoc """
  Three small signals: `count/1`, the round bubble with a number (4 pull requests waiting), `dot/1`, the
  status dot (connected, reviewing) and `chip/1`, the pill with a small avatar and a name. A dot can pulse,
  and stops under `prefers-reduced-motion`; it is drawn in the brighter `dot` shade of its tone.
  """
  use Phoenix.Component

  alias DevactionUI.Tone

  attr :value, :integer, required: true
  attr :max, :integer, default: 99, doc: "above this the bubble reads `99+`"
  attr :tone, :atom, values: [:neutral, :risk], default: :neutral
  attr :class, :any, default: nil
  attr :rest, :global

  def count(assigns) do
    ~H"""
    <span
      class={[
        "inline-flex h-[22px] min-w-[22px] items-center justify-center rounded-full px-[7px] text-xs font-semibold",
        (@tone == :risk && "bg-missing text-on-finding") || "bg-ink text-on-primary",
        @class
      ]}
      {@rest}
    >
      {shown(@value, @max)}
    </span>
    """
  end

  defp shown(value, max) when value > max, do: "#{max}+"
  defp shown(value, _max), do: value

  attr :tone, :atom,
    values: [:ok, :warn, :risk, :info, :neutral, :indigo, :emerald],
    default: :ok

  attr :pulse, :boolean, default: false

  attr :label, :string,
    default: nil,
    doc: "what the dot says, for assistive technology; without it the dot is decoration"

  attr :class, :any, default: nil
  attr :rest, :global

  def dot(assigns) do
    ~H"""
    <span
      role={@label && "img"}
      aria-label={@label}
      aria-hidden={is_nil(@label) && "true"}
      class={[
        "inline-block size-2 rounded-full",
        Tone.dot(@tone),
        @pulse && "animate-pulse-dot motion-reduce:animate-none",
        @class
      ]}
      {@rest}
    />
    """
  end

  attr :initials, :string,
    default: nil,
    doc: "the letters in the small avatar; ignored when the `avatar` slot is given"

  attr :tone, :atom,
    values: [:indigo, :emerald, :risk, :warn, :ok, :info, :neutral],
    default: :indigo,
    doc: "the tint of the small avatar"

  attr :class, :any, default: nil
  attr :rest, :global
  slot :avatar, doc: "replaces the initials, drawn by the caller in a 22 px circle"
  slot :inner_block, required: true, doc: "the name"

  @doc "A pill with a small avatar and a name, for a person assigned to something."
  def chip(assigns) do
    ~H"""
    <span
      class={[
        "inline-flex items-center gap-1.5 rounded-full bg-tag-neutral-bg py-1 pr-2.5 pl-1 text-[13px] text-ink",
        @class
      ]}
      {@rest}
    >
      <span
        class={[
          "flex size-[22px] shrink-0 items-center justify-center overflow-hidden rounded-full font-mono text-[10px]",
          Tone.bg(@tone),
          Tone.text(@tone)
        ]}
        aria-hidden="true"
      >
        {(@avatar != [] && render_slot(@avatar)) || @initials}
      </span>
      {render_slot(@inner_block)}
    </span>
    """
  end
end
