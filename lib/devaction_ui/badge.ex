defmodule DevactionUI.Badge do
  @moduledoc """
  Two small signals: `count/1`, the round bubble with a number (4 pull requests waiting), and `dot/1`, the
  status dot (connected, running). A dot can pulse, and stops under `prefers-reduced-motion`.
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
        "inline-flex h-[22px] min-w-[22px] items-center justify-center rounded-full px-1.5 text-xs font-medium",
        (@tone == :risk && "bg-missing text-white") || "bg-ink text-on-primary",
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

  attr :tone, :atom, values: [:ok, :warn, :risk, :info, :neutral], default: :ok
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
        Tone.fill(@tone),
        @pulse && "animate-pulse motion-reduce:animate-none",
        @class
      ]}
      {@rest}
    />
    """
  end
end
