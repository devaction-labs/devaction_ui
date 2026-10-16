defmodule DevactionUI.Aura do
  @moduledoc """
  A turning ring of light around something, for the AI at work. It wraps its content, which keeps its own
  surface; the ring is the wrapper's padding, painted by a conic gradient whose angle is animated.

  `tone` picks the color (`:ai` amber, `:learning` violet, `:ok`, `:risk`). `variant` is `:spin` (one light
  going round), `:dual` (two tones going round, the second one `learning`) or `:glow` (no ring, a halo that
  breathes). `size` is the ring's width (`:xs` 1px, `:sm` 1.5px, `:md` 2px, `:lg` 2.5px). `shape` is the
  outline of the ring and of the content it hugs: `:card` rounded corners, `:pill` and `:circle` fully round
  (a `:circle` needs square content). `speed` is `:normal` (a turn in 2.6 s, 3.2 s for `:dual`) or `:fast`
  (1.4 s, the canvas's small chip). The animation stops under `prefers-reduced-motion`, leaving the ring still.

  The ring is drawn from the tone's own colour (`currentColor` over a faint trail, with the lighter spark), so
  it is the amber, violet, green or red of the tone in both themes, and the `:dual` ring's trail is the `line`
  token: nothing in it is a fixed colour. The canvas paints one amber gradient; here the same gradient follows
  the tone.

  The ring is decoration. When it marks work in progress, say so on the wrapper with `aria-busy="true"`
  (it goes through `rest`). The spin needs the `@property --aura-angle` rule of `devaction_ui.css`: without
  it the angle cannot be animated and the ring stays still.
  """
  use Phoenix.Component

  attr :tone, :atom, values: [:ai, :learning, :ok, :risk], default: :ai
  attr :variant, :atom, values: [:spin, :dual, :glow], default: :spin
  attr :size, :atom, values: [:xs, :sm, :md, :lg], default: :sm
  attr :shape, :atom, values: [:card, :pill, :circle], default: :card
  attr :speed, :atom, values: [:normal, :fast], default: :normal
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def aura(assigns) do
    ~H"""
    <div
      class={[
        "relative motion-reduce:animate-none",
        tone(@tone),
        look(@variant, @speed),
        outline(@shape, @variant, @size),
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

  defp look(:spin, speed),
    do: [
      spin(speed),
      "bg-[conic-gradient(from_var(--aura-angle),color-mix(in_oklab,currentColor_28%,transparent)_0_62%,currentColor_78%,color-mix(in_oklab,currentColor_40%,white)_82%,color-mix(in_oklab,currentColor_28%,transparent)_92%)]"
    ]

  defp look(:dual, speed),
    do: [
      dual(speed),
      "bg-[conic-gradient(from_var(--aura-angle),var(--line)_0_10%,currentColor_22%,var(--line)_34%_60%,var(--aura-2,var(--color-learning))_72%,var(--line)_84%)]"
    ]

  defp look(:glow, _speed),
    do: "animate-aura-glow [--aura-g:color-mix(in_oklab,currentColor_55%,transparent)]"

  defp spin(:normal), do: "animate-aura-spin"
  defp spin(:fast), do: "animate-aura-spin-fast"

  defp dual(:normal), do: "animate-aura-spin-slow"
  defp dual(:fast), do: "animate-aura-spin-fast"

  defp outline(:card, :glow, _size), do: "rounded-[14px] [&>*]:rounded-[14px]"
  defp outline(:card, _variant, :xs), do: "rounded-[15px] [&>*]:rounded-[14px]"
  defp outline(:card, _variant, :sm), do: "rounded-[15.5px] [&>*]:rounded-[14px]"
  defp outline(:card, _variant, :md), do: "rounded-2xl [&>*]:rounded-[14px]"
  defp outline(:card, _variant, :lg), do: "rounded-[16.5px] [&>*]:rounded-[14px]"
  defp outline(_round, _variant, _size), do: "rounded-full [&>*]:rounded-full"

  defp width(:glow, _size), do: nil
  defp width(_variant, :xs), do: "p-px"
  defp width(_variant, :sm), do: "p-[1.5px]"
  defp width(_variant, :md), do: "p-0.5"
  defp width(_variant, :lg), do: "p-[2.5px]"
end
