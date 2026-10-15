defmodule DevactionUISite.Icon do
  @moduledoc """
  The showcase's icons: Hugeicons Stroke Rounded (free), one sprite in `dev/static/images/hugeicons.svg`
  built by `mix icons.build` from `assets/icons.json`. The library itself ships no icons; it takes them as
  slots, and this is what the showcase puts in them.
  """
  use Phoenix.Component

  attr :name, :string, required: true
  attr :class, :string, default: nil
  attr :label, :string, default: nil
  attr :rest, :global

  def icon(assigns) do
    ~H"""
    <svg
      class={["shrink-0", @class]}
      role={@label && "img"}
      aria-label={@label}
      aria-hidden={is_nil(@label) && "true"}
      {@rest}
    >
      <use href={"/images/hugeicons.svg#hi-" <> @name} />
    </svg>
    """
  end
end
