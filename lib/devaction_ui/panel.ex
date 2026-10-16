defmodule DevactionUI.Panel do
  @moduledoc """
  The canvas card: a soft wrap around a bordered card, and the mono `eyebrow/1` caption that opens it. For the
  dashed box of a list with nothing in it, use `DevactionUI.EmptyState`.
  """
  use Phoenix.Component

  attr :id, :string,
    default: nil,
    doc: "optional; give one only when something targets the section"

  attr :label, :string,
    default: nil,
    doc: "the accessible name of the section, when the card has no heading"

  attr :class, :any, default: nil, doc: "classes of the outer wrap"

  attr :inner_class, :any,
    default: "p-6 gap-5",
    doc: "classes of the inner card; replaces the default padding and gap, so give both"

  attr :rest, :global
  slot :inner_block, required: true

  @doc "A bordered card inside a soft wrap."
  @spec panel(map()) :: Phoenix.LiveView.Rendered.t()
  def panel(assigns) do
    ~H"""
    <section
      id={@id}
      aria-label={@label}
      class={["rounded-[20px] bg-wrap p-1.5", @class]}
      {@rest}
    >
      <div class={["flex flex-col rounded-2xl border border-line bg-card", @inner_class]}>
        {render_slot(@inner_block)}
      </div>
    </section>
    """
  end

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
