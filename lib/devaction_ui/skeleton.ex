defmodule DevactionUI.Skeleton do
  @moduledoc """
  A placeholder for what is loading: a bar (`:line`), a round shape (`:circle`) or a block (`:block`),
  with a shimmer that stops under `prefers-reduced-motion`. Size it with `class` (`h-4 w-40`).
  """
  use Phoenix.Component

  attr :shape, :atom, values: [:line, :circle, :block], default: :line
  attr :class, :any, default: nil
  attr :rest, :global

  def skeleton(assigns) do
    ~H"""
    <span
      aria-hidden="true"
      class={[
        "block animate-shimmer bg-line-soft bg-[linear-gradient(90deg,var(--line-soft)_0,var(--wrap)_50%,var(--line-soft)_100%)] bg-[length:800px_100%] motion-reduce:animate-none",
        shape_class(@shape),
        @class
      ]}
      {@rest}
    />
    """
  end

  defp shape_class(:line), do: "h-3.5 w-full rounded-md"
  defp shape_class(:circle), do: "size-10 rounded-full"
  defp shape_class(:block), do: "h-20 w-full rounded-xl"
end
