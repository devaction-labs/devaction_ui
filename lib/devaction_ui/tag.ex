defmodule DevactionUI.Tag do
  @moduledoc """
  The small mono label of the canvas: EM RISCO, AGUARDANDO, EM DIA, APRENDIZADO, PLANEJADO.

  Geist Mono, uppercase, 0.06em tracking, 6px radius, 1px border. The five variants take their border,
  background and text from the `--tag-*` tokens, so they flip with the theme. The variant says what the
  tag means, not what color it is: `:risk`, `:warn`, `:ok`, `:info`, `:neutral`.

  `size: :sm` is the 11px tag of lists and cards; `surface: :plain` puts it on a white background, for
  tags that sit inside a tinted card (a finding, a callout), where a tinted tag would vanish.

  `case: :normal` keeps the text as written, for a value that is code (`:risk`, `phx-click`) and would be
  wrong in capitals.
  """

  use Phoenix.Component

  attr :variant, :atom, values: [:risk, :warn, :ok, :info, :neutral], default: :neutral
  attr :size, :atom, values: [:md, :sm], default: :md

  attr :surface, :atom,
    values: [:tinted, :plain],
    default: :tinted,
    doc: "`:plain` for a tag inside a tinted card"

  attr :case, :atom,
    values: [:upper, :normal],
    default: :upper,
    doc: "`:normal` for a value that is code and must keep its letters"

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def tag(assigns) do
    ~H"""
    <span
      class={[
        "inline-flex items-center whitespace-nowrap rounded-md border font-mono",
        case_class(@case),
        size_class(@size),
        variant_class(@variant, @surface),
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end

  defp case_class(:upper), do: "uppercase tracking-[0.06em]"
  defp case_class(:normal), do: "normal-case"

  defp size_class(:md), do: "px-[9px] py-1 text-xs"
  defp size_class(:sm), do: "px-2 py-[3px] text-[11px]"

  defp variant_class(variant, :tinted), do: tone(variant)

  defp variant_class(variant, :plain),
    do: String.replace(tone(variant), ~r/bg-tag-\w+-bg/, "bg-card")

  defp tone(:risk), do: "border-tag-risk-line bg-tag-risk-bg text-tag-risk-text"
  defp tone(:warn), do: "border-tag-warn-line bg-tag-warn-bg text-tag-warn-text"
  defp tone(:ok), do: "border-tag-ok-line bg-tag-ok-bg text-tag-ok-text"
  defp tone(:info), do: "border-tag-info-line bg-tag-info-bg text-tag-info-text"
  defp tone(:neutral), do: "border-tag-neutral-line bg-tag-neutral-bg text-tag-neutral-text"
end
