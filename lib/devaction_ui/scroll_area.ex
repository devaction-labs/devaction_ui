defmodule DevactionUI.ScrollArea do
  @moduledoc """
  An area that scrolls on its own, with a thin bar and a shadow only at the edges that still have content behind
  them: the left one shows once you have scrolled right, the right one while there is more to the right. Under a
  sticky table header it also adds a shadow once the rows have moved under it. The `DevactionUI.ScrollArea` hook
  marks the root with `data-more-left`, `data-more-right`, `data-more-top`, `data-more-bottom` and
  `data-scrolled-y`, and LiveView is told to leave those alone.

  `max_h` is a CSS length (`"560px"`) that limits the height, so it scrolls vertically too. A table with sticky
  columns fixes their width in `edge_left` and `edge_right`, so the shadow starts after them. The viewport is
  focusable, so the keyboard can scroll it; name it with `label`, which makes it a region.

      <ScrollArea.scroll_area id="projects" max_h="360px" label="Projects" edge_right="56px">
        <table>...</table>
      </ScrollArea.scroll_area>
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  @edges [
    "data-more-left",
    "data-more-right",
    "data-more-top",
    "data-more-bottom",
    "data-scrolled-y"
  ]

  attr :id, :string, required: true
  attr :label, :string, default: nil, doc: "names the scrolling region for assistive technology"

  attr :max_h, :string,
    default: nil,
    doc: "a CSS length; without it the area grows with its content"

  attr :bare, :boolean, default: false, doc: "no border and no rounded corners"
  attr :edge_left, :string, default: nil, doc: "the width of a fixed column on the left"
  attr :edge_right, :string, default: nil, doc: "the width of a fixed column on the right"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc "The scroll area."
  @spec scroll_area(map()) :: Phoenix.LiveView.Rendered.t()
  def scroll_area(assigns) do
    assigns = assign(assigns, :vars, vars(assigns))

    ~H"""
    <div
      id={@id}
      class={["scroll-area", @class]}
      data-bare={@bare && ""}
      phx-hook="DevactionUI.ScrollArea"
      phx-mounted={edge_attrs()}
      {@vars}
      {@rest}
    >
      <div
        class="scroll-area-viewport"
        data-viewport
        tabindex="0"
        role={@label && "region"}
        aria-label={@label}
      >
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  defp edge_attrs, do: JS.ignore_attributes(@edges)

  defp vars(assigns) do
    [
      {"--max-h", assigns.max_h},
      {"--edge-left", assigns.edge_left},
      {"--edge-right", assigns.edge_right}
    ]
    |> Enum.reject(fn {_name, value} -> is_nil(value) end)
    |> Enum.map_join("; ", fn {name, value} -> "#{name}: #{value}" end)
    |> presence()
  end

  defp presence(""), do: []
  defp presence(style), do: [style: style]
end
