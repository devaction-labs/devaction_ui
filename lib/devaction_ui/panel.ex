defmodule DevactionUI.Panel do
  @moduledoc """
  The canvas card: a soft wrap around a bordered card, and the mono `eyebrow/1` caption that opens it. The card
  inside takes the `card` colour in both themes, so it reads against the `wrap` around it. Its padding and gap
  follow `size` (`:sm` 22px and 14px, `:md` 24px and 20px, `:lg` 26px and 20px); `inner_class` overrides them.
  For the dashed box of a list with nothing in it, use `DevactionUI.EmptyState`.
  """
  use Phoenix.Component

  attr :id, :string,
    default: nil,
    doc: "optional; give one only when something targets the section"

  attr :label, :string,
    default: nil,
    doc: "the accessible name of the section, when the card has no heading"

  attr :class, :any, default: nil, doc: "classes of the outer wrap"

  attr :size, :atom,
    values: [:sm, :md, :lg],
    default: :md,
    doc: "the padding and gap of the inner card, by the density of what it holds"

  attr :inner_class, :any,
    default: nil,
    doc: "classes of the inner card; replace the padding and gap of `size`, so give both"

  attr :rest, :global
  slot :inner_block, required: true

  @doc "A bordered card inside a soft wrap."
  @spec panel(map()) :: Phoenix.LiveView.Rendered.t()
  def panel(assigns) do
    ~H"""
    <section
      id={@id}
      aria-label={@label}
      class={["rounded-wrap bg-wrap p-1.5", @class]}
      {@rest}
    >
      <div class={[
        "flex flex-col rounded-card border border-line bg-card",
        @inner_class || size_class(@size)
      ]}>
        {render_slot(@inner_block)}
      </div>
    </section>
    """
  end

  defp size_class(:sm), do: "p-[22px] gap-3.5"
  defp size_class(:md), do: "p-6 gap-5"
  defp size_class(:lg), do: "p-[26px] gap-5"

  attr :class, :any, default: nil
  slot :inner_block, required: true

  attr :rest, :global

  @doc "The mono caption that says what a card holds."
  @spec eyebrow(map()) :: Phoenix.LiveView.Rendered.t()
  def eyebrow(assigns) do
    ~H"""
    <div class={["font-mono text-xs uppercase tracking-[0.08em] text-muted", @class]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end
end
