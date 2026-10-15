defmodule DevactionUI.Aura do
  @moduledoc """
  A turning ring of light around something, for the AI at work. It wraps its content, which keeps its own
  surface; the ring is the wrapper's padding, painted by a conic gradient whose angle is animated.

  `tone` picks the color (`:ai` amber, `:learning` violet, `:ok`, `:risk`). `variant` is `:spin` (one light
  going round), `:dual` (two tones going round, the second one `learning`) or `:glow` (no ring, a halo that
  breathes). `size` is the ring's width. The animation stops under `prefers-reduced-motion`, leaving the
  ring still.
  """
  use Phoenix.Component

  attr :tone, :atom, values: [:ai, :learning, :ok, :risk], default: :ai
  attr :variant, :atom, values: [:spin, :dual, :glow], default: :spin
  attr :size, :atom, values: [:xs, :sm, :lg], default: :sm
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def aura(assigns) do
    ~H"""
    <div
      class={[
        "relative motion-reduce:animate-none [&>*]:rounded-[14px]",
        tone(@tone),
        look(@variant),
        width(@variant, @size),
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp tone(:ai), do: "text-ai"
  defp tone(:learning), do: "text-learning"
  defp tone(:ok), do: "text-tag-ok-text"
  defp tone(:risk), do: "text-missing"

  defp look(:spin),
    do:
      "animate-aura-spin bg-[conic-gradient(from_var(--aura-angle),color-mix(in_oklab,currentColor_28%,transparent)_0_62%,currentColor_78%,color-mix(in_oklab,currentColor_40%,white)_82%,color-mix(in_oklab,currentColor_28%,transparent)_92%)]"

  defp look(:dual),
    do:
      "animate-aura-spin-slow bg-[conic-gradient(from_var(--aura-angle),var(--line)_0_10%,currentColor_22%,var(--line)_34%_60%,var(--aura-2,var(--color-learning))_72%,var(--line)_84%)]"

  defp look(:glow),
    do:
      "animate-aura-glow rounded-[14px] [--aura-g:color-mix(in_oklab,currentColor_55%,transparent)]"

  defp width(:glow, _size), do: nil
  defp width(_variant, :xs), do: "rounded-[15px] p-px"
  defp width(_variant, :sm), do: "rounded-[15.5px] p-[1.5px]"
  defp width(_variant, :lg), do: "rounded-[16.5px] p-[2.5px]"
end
