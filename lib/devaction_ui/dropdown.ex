defmodule DevactionUI.Dropdown do
  @moduledoc """
  A button that opens a menu of actions or a choice (sort by deadline, by value, by risk). The menu opens
  under the button (above it when there is no room below); ↑ ↓ Home End move between items, Enter or Space
  chooses, Esc closes and returns to the button, a click outside closes it (`DevactionUI.Dropdown` hook).

  An item is a plain action (`role="menuitem"`) or one of a group of choices (`checked` is not nil, then
  `role="menuitemradio"` with a 16px ring before the label, filled on the chosen one). It sends `event` with
  `choice`, or goes to `navigate`, `patch` or `href`. A `separator` puts a rule above the item, a `heading`
  puts a small caption above it (the name of a group of choices), `danger` colors it as destructive and
  `disabled` leaves it out of the keys and the clicks. Type a letter (or the first letters of a name) and the focus
  jumps to the next item that starts with it. An item may begin with an icon: it takes the color of the text,
  so a `danger` item has a red icon too.

  An item sends `value` as `choice`, and `values`, a map, as one `phx-value-*` each (`values={%{id: 7, kind:
  "task"}}` arrives as `"id"` and `"kind"`). The menu closes when an item is chosen and gives the focus back
  to the button; `close_on_select={false}` keeps it open (a menu of toggles).

  The button is a bordered box by default (`variant: :outline`). `variant: :ghost` drops the border and
  `variant: :icon` is a square with only an icon (the "more" menu of a row): give it a `trigger_label`, which is
  its accessible name. `trigger_class` adds classes to the button.
  """
  use Phoenix.Component

  import DevactionUI.Kbd

  alias Phoenix.LiveView.JS

  attr :id, :string, required: true
  attr :label, :string, required: true, doc: "the name of the menu, for assistive technology"
  attr :align, :atom, values: [:start, :end], default: :start
  attr :size, :atom, values: [:sm, :md], default: :md, doc: "the height of the button: 38 or 42px"
  attr :variant, :atom, values: [:outline, :ghost, :icon], default: :outline

  attr :trigger_label, :string,
    default: nil,
    doc: "the accessible name of the button, for one that shows only an icon"

  attr :trigger_class, :any, default: nil, doc: "more classes for the button"

  attr :close_on_select, :boolean,
    default: true,
    doc: "false keeps the menu open after an item is chosen"

  attr :class, :any, default: nil
  slot :trigger, required: true, doc: "what the button shows"

  slot :item, required: true do
    attr :event, :string
    attr :value, :string, doc: "sent as `choice`"
    attr :values, :map, doc: "one `phx-value-*` each, besides `choice`"
    attr :navigate, :string
    attr :patch, :string
    attr :href, :string
    attr :checked, :boolean, doc: "set (true or false) for a choice; leave out for an action"
    attr :danger, :boolean
    attr :disabled, :boolean
    attr :separator, :boolean
    attr :heading, :string, doc: "a caption above the item, for the group it starts"
    attr :shortcut, :string
  end

  attr :target, :any,
    default: nil,
    doc: "a `phx-target` (a `@myself`) when used inside a LiveComponent"

  attr :rest, :global

  @spec dropdown(map()) :: Phoenix.LiveView.Rendered.t()
  def dropdown(assigns) do
    ~H"""
    <div
      id={@id}
      phx-hook="DevactionUI.Dropdown"
      data-close-on-select={to_string(@close_on_select)}
      class={["relative inline-block", @class]}
      {@rest}
    >
      <button
        type="button"
        data-trigger
        aria-haspopup="menu"
        aria-expanded="false"
        aria-controls={"#{@id}-menu"}
        aria-label={@trigger_label}
        phx-mounted={JS.ignore_attributes(["aria-expanded"])}
        class={[
          "items-center gap-2 whitespace-nowrap bg-card text-ink outline-none hover:bg-wrap focus-visible:ring-4 focus-visible:ring-ink/10 aria-expanded:bg-wrap",
          trigger_class(@variant, @size),
          @trigger_class
        ]}
      >
        {render_slot(@trigger)}
      </button>
      <div
        id={"#{@id}-menu"}
        data-menu
        data-side="bottom"
        role="menu"
        aria-label={@label}
        hidden
        phx-mounted={JS.ignore_attributes(["hidden", "data-side"])}
        class={[
          "absolute z-40 flex w-55 flex-col rounded-[14px] border border-line bg-card p-1.5 shadow-menu",
          "data-[side=bottom]:top-full data-[side=bottom]:mt-2 data-[side=top]:bottom-full data-[side=top]:mb-2",
          (@align == :end && "right-0") || "left-0"
        ]}
      >
        <%= for item <- @item do %>
          <span
            :if={Map.get(item, :separator)}
            class="mx-1 my-1.5 h-px bg-line-soft"
            role="separator"
          />
          <span
            :if={Map.get(item, :heading)}
            role="presentation"
            class="px-2.5 pt-1.5 pb-1 font-mono text-[10px] uppercase tracking-[0.08em] text-muted"
          >
            {item.heading}
          </span>
          <.menu_item item={item} target={@target} />
        <% end %>
      </div>
    </div>
    """
  end

  attr :item, :map, required: true
  attr :target, :any, default: nil

  defp menu_item(assigns) do
    assigns =
      assigns
      |> assign(:checked, Map.get(assigns.item, :checked))
      |> assign(:values, value_attrs(assigns.item))

    ~H"""
    <.link
      :if={link?(@item)}
      navigate={Map.get(@item, :navigate)}
      patch={Map.get(@item, :patch)}
      href={Map.get(@item, :href)}
      phx-click={Map.get(@item, :event)}
      phx-target={@target}
      role="menuitem"
      tabindex="-1"
      class={item_class(@item)}
      {@values}
    >
      <span class="flex flex-1 items-center gap-2.5">{render_slot(@item)}</span>
      <.kbd_hint item={@item} />
    </.link>
    <button
      :if={not link?(@item)}
      type="button"
      role={(is_nil(@checked) && "menuitem") || "menuitemradio"}
      aria-checked={not is_nil(@checked) && to_string(@checked)}
      aria-disabled={Map.get(@item, :disabled) && "true"}
      disabled={Map.get(@item, :disabled)}
      tabindex="-1"
      phx-click={Map.get(@item, :event)}
      phx-target={@target}
      class={[item_class(@item), "group/item", @checked && "bg-wrap"]}
      {@values}
    >
      <span
        :if={not is_nil(@checked)}
        aria-hidden="true"
        class="size-4 shrink-0 rounded-full border border-line-strong group-aria-checked/item:border-[5px] group-aria-checked/item:border-ink"
      />
      <span class="flex flex-1 items-center gap-2.5">{render_slot(@item)}</span>
      <.kbd_hint item={@item} />
    </button>
    """
  end

  attr :item, :map, required: true

  defp kbd_hint(assigns) do
    ~H"""
    <.kbd :if={Map.get(@item, :shortcut)} tone={:bare}>{@item.shortcut}</.kbd>
    """
  end

  defp value_attrs(item) do
    item
    |> Map.get(:values, %{})
    |> Map.new(fn {key, value} -> {"phx-value-#{key}", value} end)
    |> put_choice(Map.get(item, :value))
  end

  defp put_choice(attrs, nil), do: attrs
  defp put_choice(attrs, value), do: Map.put(attrs, "phx-value-choice", value)

  defp link?(%{disabled: true}), do: false
  defp link?(item), do: Enum.any?([:navigate, :patch, :href], &Map.has_key?(item, &1))

  defp trigger_class(:outline, :sm),
    do: "inline-flex h-[38px] rounded-[10px] border border-line-strong px-3 text-sm"

  defp trigger_class(:outline, :md),
    do: "inline-flex h-[42px] rounded-[11px] border border-line-strong px-3.5"

  defp trigger_class(:ghost, :sm), do: "inline-flex h-[38px] rounded-[10px] px-3 text-sm"
  defp trigger_class(:ghost, :md), do: "inline-flex h-[42px] rounded-[11px] px-3.5"
  defp trigger_class(:icon, :sm), do: "grid size-[38px] place-items-center rounded-[10px]"
  defp trigger_class(:icon, :md), do: "grid size-[42px] place-items-center rounded-[11px]"

  defp item_class(item) do
    [
      "flex h-[38px] w-full items-center justify-between gap-3 rounded-[9px] border-0 bg-transparent px-2.5 text-left text-sm no-underline outline-none hover:bg-wrap focus-visible:bg-wrap disabled:cursor-not-allowed disabled:opacity-40 disabled:hover:bg-transparent",
      (Map.get(item, :danger) && "text-tag-risk-text") || "text-ink"
    ]
  end
end
