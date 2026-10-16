defmodule DevactionUI.Skeleton do
  @moduledoc """
  A placeholder for what is loading: a bar (`:line`), a round shape (`:circle`, 36 px) or a block (`:block`,
  40 px), with a shimmer that stops under `prefers-reduced-motion` or with `animate={false}`. Size it with
  `class` (`h-4 w-40`).

  A single skeleton is decoration (`aria-hidden`). Wrap the placeholders of one loading area in
  `skeleton_group/1`, which tells assistive technology once that the area is busy.
  """
  use Phoenix.Component

  attr :shape, :atom, values: [:line, :circle, :block], default: :line
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
          "animate-shimmer bg-[linear-gradient(90deg,var(--line-soft)_0,var(--wrap)_50%,var(--line-soft)_100%)] bg-[length:800px_100%] motion-reduce:animate-none",
        shape_class(@shape),
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

  defp shape_class(:line), do: "h-3.5 w-full rounded-md"
  defp shape_class(:circle), do: "size-9 rounded-full"
  defp shape_class(:block), do: "h-10 w-full rounded-[10px]"
end
