defmodule DevactionUI.Tag do
  @moduledoc """
  The small mono label of the canvas: EM RISCO, AGUARDANDO, EM DIA, APRENDIZADO, PLANEJADO.

  Geist Mono, uppercase, 0.06em tracking, 6px radius, 1px border. The five variants take their border,
  background and text from the `--tag-*` tokens, so they flip with the theme. The variant says what the
  tag means, not what color it is: `:risk`, `:warn`, `:ok`, `:info`, `:neutral`; `:indigo` and `:emerald` are the tints of people and review.

  `size` is `:xs` (10px, `3px 7px`, a count beside a name), `:sm` (11px, `2px 7px`, the count of an accordion
  or a stat), `:md` (11px, `3px 8px`, the tag of a table or a list, the default) and `:lg` (12px, `4px 9px`).

  `surface: :plain` puts it on a white background, for tags that sit inside a tinted card (a finding, a
  callout), where a tinted tag would vanish. `:soft` is the borderless chip on the grey of the page (a PR
  number on a kanban card), keeping the text color of its variant; `:flat` is the same without border but
  in the tint of its variant.

  `case: :normal` keeps the text as written, for a value that is code (`:risk`, `phx-click`) and would be
  wrong in capitals.
  """

  use Phoenix.Component

  alias DevactionUI.Tone

  attr :variant, :atom,
    values: [:risk, :warn, :ok, :info, :neutral, :indigo, :emerald],
    default: :neutral,
    doc: "what the tag means, which sets its border, background and text"

  attr :size, :atom,
    values: [:lg, :md, :sm, :xs],
    default: :md,
    doc:
      "`:lg` 12px, `:md` 11px for tables and lists, `:sm` 11px tighter for a count, `:xs` 10px for a count beside a name"

  attr :surface, :atom,
    values: [:tinted, :plain, :soft, :flat],
    default: :tinted,
    doc:
      "`:plain` for a tag inside a tinted card, `:soft` a borderless chip on grey, `:flat` a borderless tint"

  attr :case, :atom,
    values: [:upper, :normal],
    default: :upper,
    doc: "`:normal` for a value that is code and must keep its letters"

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc "A small mono label whose variant says what it means."
  @spec tag(map()) :: Phoenix.LiveView.Rendered.t()
  def tag(assigns) do
    ~H"""
    <span
      class={[
        "inline-flex items-center whitespace-nowrap rounded-md font-mono",
        case_class(@case),
        size_class(@size),
        tone(@variant, @surface),
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

  defp size_class(:lg), do: "px-[9px] py-1 text-xs"
  defp size_class(:md), do: "px-2 py-[3px] text-[11px]"
  defp size_class(:sm), do: "px-[7px] py-0.5 text-[11px]"
  defp size_class(:xs), do: "px-[7px] py-[3px] text-[10px]"

  defp tone(variant, :tinted), do: ["border", Tone.surface(variant), Tone.text(variant)]
  defp tone(variant, :plain), do: ["border", border(variant), "bg-card", Tone.text(variant)]
  defp tone(variant, :soft), do: ["bg-tag-neutral-bg", Tone.text(variant)]
  defp tone(variant, :flat), do: [Tone.bg(variant), Tone.text(variant)]

  defp border(:risk), do: "border-tag-risk-line"
  defp border(:warn), do: "border-tag-warn-line"
  defp border(:ok), do: "border-tag-ok-line"
  defp border(:info), do: "border-tag-info-line"
  defp border(:neutral), do: "border-tag-neutral-line"
  defp border(:indigo), do: "border-tag-indigo-line"
  defp border(:emerald), do: "border-tag-emerald-line"
end
