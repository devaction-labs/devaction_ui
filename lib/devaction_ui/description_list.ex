defmodule DevactionUI.DescriptionList do
  @moduledoc """
  A list of terms and their values, one row each, with a hairline between the rows: the facts of a client, a
  repository, a pull request. It is a real description list (`<dl>` with a `<dt>` and a `<dd>` per row), so a
  screen reader announces each value with its term.

  Each `item` slot is a row: `label` is the term (muted), the slot content is the value (medium weight). An
  item with `href` makes its value a link; `tone` colors the value (`:ok`, `:warn`, `:risk`, `:info`) and
  `mono` sets it in the monospace of a repository or a hash. `term_width` is the width of the term column;
  `layout: :stacked` puts the term over the value instead, for a narrow card.
  """
  use Phoenix.Component

  alias DevactionUI.Tone

  attr :layout, :atom,
    values: [:inline, :stacked],
    default: :inline,
    doc: "the term beside the value, or over it"

  attr :term_width, :string,
    default: "120px",
    doc: "the width of the term column when `layout` is `:inline`, as a CSS length"

  attr :divided, :boolean, default: true, doc: "a hairline between the rows"
  attr :class, :any, default: nil
  attr :rest, :global

  slot :item, required: true, doc: "a row: the slot content is the value" do
    attr :label, :string, required: true, doc: "the term"
    attr :href, :string, doc: "makes the value a link"
    attr :tone, :atom, doc: "colors the value: `:ok`, `:warn`, `:risk`, `:info`"
    attr :mono, :boolean, doc: "sets the value in the monospace"
  end

  @doc "Term and value rows in a `<dl>`, with hairlines between them."
  @spec list(map()) :: Phoenix.LiveView.Rendered.t()
  def list(assigns) do
    ~H"""
    <dl
      class={["m-0 text-sm", @class]}
      style={@layout == :inline && "--term-width: #{@term_width}"}
      {@rest}
    >
      <div
        :for={item <- @item}
        class={[
          "gap-x-3 py-2.5",
          layout_class(@layout),
          @divided && "border-b border-line-soft last:border-b-0"
        ]}
      >
        <dt class="text-muted">{item.label}</dt>
        <dd class={[
          "m-0 min-w-0 font-medium text-ink",
          item[:mono] && "font-mono text-[13px]",
          tone(item[:tone])
        ]}>
          <.value href={item[:href]}>{render_slot(item)}</.value>
        </dd>
      </div>
    </dl>
    """
  end

  attr :href, :string, default: nil
  slot :inner_block, required: true

  defp value(%{href: nil} = assigns), do: ~H"{render_slot(@inner_block)}"

  defp value(assigns) do
    ~H"""
    <a
      href={@href}
      class="underline underline-offset-[3px] outline-none hover:text-ink-2 focus-visible:rounded focus-visible:ring-4 focus-visible:ring-ink/10"
    >
      {render_slot(@inner_block)}
    </a>
    """
  end

  defp layout_class(:inline), do: "grid grid-cols-[var(--term-width)_1fr]"
  defp layout_class(:stacked), do: "flex flex-col gap-0.5"

  defp tone(nil), do: nil
  defp tone(tone), do: Tone.text(tone)
end
