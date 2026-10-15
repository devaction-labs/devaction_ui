defmodule DevactionUI.Panel do
  @moduledoc "The canvas card: a soft wrap around a bordered white panel."
  use Phoenix.Component

  attr :id, :string, required: true
  attr :label, :string, default: nil, doc: "accessible name of the section"
  attr :class, :any, default: nil
  attr :inner_class, :any, default: "p-6 gap-5"
  attr :rest, :global
  slot :inner_block, required: true

  def panel(assigns) do
    ~H"""
    <section
      id={@id}
      aria-label={@label}
      class={["rounded-[20px] bg-wrap p-1.5", @class]}
      {@rest}
    >
      <div class={["flex flex-col rounded-2xl border border-line bg-panel", @inner_class]}>
        {render_slot(@inner_block)}
      </div>
    </section>
    """
  end

  attr :class, :any, default: nil
  slot :inner_block, required: true

  attr :rest, :global

  def eyebrow(assigns) do
    ~H"""
    <div class={["font-mono text-xs uppercase tracking-[0.08em] text-muted", @class]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :id, :string, required: true
  slot :inner_block, required: true

  attr :rest, :global

  def empty(assigns) do
    ~H"""
    <p
      id={@id}
      class="rounded-xl border border-dashed border-line-strong px-4 py-6 text-sm text-muted"
      {@rest}
    >
      {render_slot(@inner_block)}
    </p>
    """
  end
end
