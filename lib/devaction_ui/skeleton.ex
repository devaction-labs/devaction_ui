defmodule DevactionUI.Skeleton do
  @moduledoc """
  A placeholder for what is loading: a bar (`:line`), a round shape (`:circle`, 36 px) or a block (`:block`,
  40 px), with a shimmer that stops under `prefers-reduced-motion` or with `animate={false}`. A line has
  three heights, `size` `:md` (14 px, a text line), `:sm` (12 px, a row of a list) and `:xs` (10 px, the label
  of a number); for anything else size it with `class` (`h-4 w-40`). The shimmer runs from the soft line
  to the `--shimmer` token and back.

  A single skeleton is decoration (`aria-hidden`). Wrap the placeholders of one loading area in
  `skeleton_group/1`, which tells assistive technology once that the area is busy.
  """
  use Phoenix.Component

  attr :shape, :atom, values: [:line, :circle, :block], default: :line

  attr :size, :atom,
    values: [:md, :sm, :xs],
    default: :md,
    doc: "the height of a `:line`: 14, 12 or 10 px"

  attr :animate, :boolean, default: true, doc: "`false` for a still placeholder"
  attr :class, :any, default: nil
  attr :rest, :global

  @doc "One placeholder shape."
  def skeleton(assigns) do
    ~H"""
    <span
      aria-hidden="true"
      class={[
        "block bg-line-soft",
        @animate &&
          "animate-shimmer bg-[linear-gradient(90deg,var(--line-soft)_0,var(--shimmer)_50%,var(--line-soft)_100%)] bg-[length:800px_100%] motion-reduce:animate-none",
        shape_class(@shape, @size),
        @class
      ]}
      {@rest}
    />
    """
  end

  attr :label, :string, required: true, doc: "what is loading, for assistive technology"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true, doc: "the skeletons of the area"

  @doc "The area the skeletons stand for: a busy status that is named once."
  def skeleton_group(assigns) do
    ~H"""
    <div role="status" aria-busy="true" aria-label={@label} class={@class} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp shape_class(:line, :md), do: "h-3.5 w-full rounded-md"
  defp shape_class(:line, :sm), do: "h-3 w-full rounded"
  defp shape_class(:line, :xs), do: "h-2.5 w-full rounded"
  defp shape_class(:circle, _size), do: "size-9 rounded-full"
  defp shape_class(:block, _size), do: "h-10 w-full rounded-[10px]"
end
