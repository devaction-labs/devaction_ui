defmodule DevactionUI.Resizable do
  @moduledoc """
  Panels side by side (or one above the other) with a divider between each two that the person moves: drag it with a
  mouse, a pen or a finger, press ← → (↑ ↓ in a vertical group; Shift takes a larger step) or Home and End on it,
  and a double click shares the two panels around it equally (`DevactionUI.Resizable` hook). Each panel has a
  size in percent, the sizes of the group add up to 100, and a panel may have a `min` and a `max`; moving a divider
  gives what one panel gains to the next and never takes either past its limits.

  Nothing is stored. The panels follow the divider at once, and when a move ends (the pointer is let go, a key is released,
  a double click) `event` (`"resize"`) is sent to the LiveView, or to `target` inside a LiveComponent, with
  `%{"sizes" => %{panel_id => percent}}`; the server may keep it and give it back as the `size` of the panels, which then
  win over what the page shows. A text such as `DIFF · 58%` is the caller's: put `<span data-size-value>58</span>`
  in the panel and the hook keeps that number current.

  Every divider is a `role="separator"` that can take the focus, with `aria-orientation`, `aria-valuenow` (the size
  of the panel before it), `aria-valuemin` and `aria-valuemax` (how far it can go, given the limits of both panels) and
  `aria-controls`. `orientation` is the way the panels lie: `:horizontal` is side by side, with a vertical divider.
  The caller's `handle_label` names the dividers. The grip is two small bars, drawn by the component.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  attr :id, :string, required: true
  attr :label, :string, required: true, doc: "the name of the group, for assistive technology"

  attr :handle_label, :string,
    required: true,
    doc: "the name of a divider, such as `Resize panels`"

  attr :orientation, :atom,
    values: [:horizontal, :vertical],
    default: :horizontal,
    doc: "`:horizontal` puts the panels side by side, `:vertical` one above the other"

  attr :event, :string,
    default: "resize",
    doc: "the event sent when a move ends, with `sizes`, a map of panel id to percent"

  attr :target, :any,
    default: nil,
    doc: "a `phx-target` (a `@myself`) when used inside a LiveComponent"

  attr :class, :any,
    default: nil,
    doc: "classes of the group; give it a height (`h-72`), which the panels share"

  slot :panel, required: true, doc: "a panel; its body is what it shows" do
    attr :id, :string, required: true, doc: "the key of its size in the event"

    attr :size, :any,
      doc: "its size in percent, a number; the panels without one share the group equally"

    attr :min, :any, doc: "the smallest it may be, in percent (default 0)"
    attr :max, :any, doc: "the largest it may be, in percent (default 100)"
    attr :class, :any, doc: "classes of the panel, such as a background"
  end

  attr :rest, :global

  @spec group(map()) :: Phoenix.LiveView.Rendered.t()
  def group(assigns) do
    assigns = assign(assigns, :panels, panels(assigns.panel))

    ~H"""
    <div
      id={@id}
      phx-hook="DevactionUI.Resizable"
      phx-target={@target}
      role="group"
      aria-label={@label}
      data-event={@event}
      data-orientation={@orientation}
      class={[
        "flex overflow-hidden rounded-xl border border-line",
        @orientation == :vertical && "flex-col",
        @class
      ]}
      {@rest}
    >
      <%= for {panel, index} <- Enum.with_index(@panels) do %>
        <.divider
          :if={index > 0}
          id={"#{@id}-divider-#{index - 1}"}
          before={Enum.at(@panels, index - 1)}
          after={panel}
          label={@handle_label}
          group={@id}
          orientation={@orientation}
        />
        <div
          id={"#{@id}-#{panel.id}"}
          data-panel
          data-id={panel.id}
          data-size={panel.size}
          data-min={panel.min}
          data-max={panel.max}
          style={"flex: #{panel.size} 1 0%"}
          phx-mounted={JS.ignore_attributes(["style"])}
          class={["min-h-0 min-w-0 overflow-hidden", panel.class]}
        >
          {render_slot(panel.slot)}
        </div>
      <% end %>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :before, :map, required: true
  attr :after, :map, required: true
  attr :label, :string, required: true
  attr :group, :string, required: true
  attr :orientation, :atom, required: true

  defp divider(assigns) do
    assigns = assign(assigns, :values, values(assigns.before, assigns.after))

    ~H"""
    <div
      id={@id}
      data-divider
      role="separator"
      tabindex="0"
      aria-label={@label}
      aria-orientation={(@orientation == :horizontal && "vertical") || "horizontal"}
      aria-valuenow={@values.now}
      aria-valuemin={@values.min}
      aria-valuemax={@values.max}
      aria-controls={"#{@group}-#{@before.id}"}
      phx-mounted={
        JS.ignore_attributes(["data-dragging", "aria-valuenow", "aria-valuemin", "aria-valuemax"])
      }
      class={[
        "flex flex-none touch-none items-center justify-center border-line bg-wrap outline-none select-none hover:bg-line-soft focus-visible:ring-4 focus-visible:ring-ink/10 focus-visible:ring-inset data-[dragging]:bg-line-soft",
        (@orientation == :horizontal && "w-3 cursor-col-resize border-x") ||
          "h-3 cursor-row-resize flex-col border-y"
      ]}
    >
      <span
        aria-hidden="true"
        class={["flex gap-1.5", (@orientation == :horizontal && "flex-col") || "flex-row"]}
      >
        <span class={["rounded bg-done", grip(@orientation)]} />
        <span class={["rounded bg-ink", grip(@orientation)]} />
      </span>
    </div>
    """
  end

  defp grip(:horizontal), do: "h-[18px] w-2.5"
  defp grip(:vertical), do: "h-2.5 w-[18px]"

  defp panels(slots) do
    share = Float.round(100 / length(slots), 2)

    Enum.map(slots, fn slot ->
      %{
        id: slot.id,
        size: Map.get(slot, :size) || share,
        min: Map.get(slot, :min) || 0,
        max: Map.get(slot, :max) || 100,
        class: Map.get(slot, :class),
        slot: slot
      }
    end)
  end

  defp values(before, next) do
    total = before.size + next.size

    %{
      now: round(before.size),
      min: ceil(max(before.min, total - next.max)),
      max: floor(min(before.max, total - next.min))
    }
  end
end
