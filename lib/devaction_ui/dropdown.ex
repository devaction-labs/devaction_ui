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

  The button is a bordered box by default (`variant: :outline`). `variant: :ghost` drops the border,
  `variant: :chip` is the amber pill of the mode or model of a `DevactionUI.Composer` and
  `variant: :icon` is a square with only an icon (the "more" menu of a row): give it a `trigger_label`, which is
  its accessible name. `trigger_class` adds classes to the button.

  `fixed` opens the menu with `position: fixed`, placed from the rectangle of the button (above it when there is
  no room below, kept inside the window), so the `overflow` of a table or a scroll area never cuts it; it closes
  when anything scrolls or the window is resized. `DevactionUI.RowMenu` is this, made for the "..." of a row.
  """
  use Phoenix.Component

  import DevactionUI.Kbd

  alias Phoenix.LiveView.JS

  attr :id, :string, required: true
  attr :label, :string, required: true, doc: "the name of the menu, for assistive technology"
  attr :align, :atom, values: [:start, :end], default: :start
  attr :size, :atom, values: [:sm, :md], default: :md, doc: "the height of the button: 38 or 42px"
  attr :variant, :atom, values: [:outline, :ghost, :icon, :chip], default: :outline

  attr :trigger_label, :string,
    default: nil,
    doc: "the accessible name of the button, for one that shows only an icon"

  attr :trigger_class, :any, default: nil, doc: "more classes for the button"

  attr :close_on_select, :boolean,
    default: true,
    doc: "false keeps the menu open after an item is chosen"

  attr :fixed, :boolean,
    default: false,
    doc:
      "opens the menu fixed to the window instead of inside the parent, so no `overflow` cuts it"

  attr :compact, :boolean,
    default: false,
    doc: "the menu of a row: 190px wide at least, 5px of padding and 34px items"

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
      data-fixed={to_string(@fixed)}
      data-align={@align}
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
        phx-mounted={JS.ignore_attributes(["hidden", "data-side", "style"])}
        class={[
          "flex flex-col border border-line bg-card shadow-menu",
          menu_size(@compact),
          menu_position(@fixed, @align)
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
          <.menu_item item={item} target={@target} compact={@compact} />
        <% end %>
      </div>
    </div>
    """
  end

  attr :item, :map, required: true, doc: "the slot entry of an item, with its attrs"
  attr :target, :any, default: nil
  attr :compact, :boolean, default: false, doc: "the 34px rows of the context menu"
  attr :rest, :global

  @doc "One item of a menu: what `dropdown/1` and `DevactionUI.ContextMenu` draw for each `:item` slot."
  @spec menu_item(map()) :: Phoenix.LiveView.Rendered.t()
  def menu_item(assigns) do
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
      class={item_class(@item, @compact)}
      {@values}
      {@rest}
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
      class={[item_class(@item, @compact), "group/item", @checked && "bg-wrap"]}
      {@values}
      {@rest}
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

  defp menu_size(true), do: "min-w-[190px] rounded-xl p-[5px]"
  defp menu_size(false), do: "w-55 rounded-[14px] p-1.5"

  defp menu_position(true, _align), do: "fixed top-0 left-0 z-50"

  defp menu_position(false, align) do
    [
      "absolute z-40 data-[side=bottom]:top-full data-[side=bottom]:mt-2 data-[side=top]:bottom-full data-[side=top]:mb-2",
      align_class(align)
    ]
  end

  defp align_class(:end), do: "right-0"
  defp align_class(:start), do: "left-0"

  defp value_attrs(item) do
    values = Map.get(item, :values) || %{}

    values
    |> Map.new(fn {key, value} -> {"phx-value-#{key}", value} end)
    |> put_choice(Map.get(item, :value))
  end

  defp put_choice(attrs, nil), do: attrs
  defp put_choice(attrs, value), do: Map.put(attrs, "phx-value-choice", value)

  defp link?(%{disabled: true}), do: false
  defp link?(item), do: Enum.any?([:navigate, :patch, :href], &(not is_nil(Map.get(item, &1))))

  defp trigger_class(:outline, :sm),
    do: "inline-flex h-[38px] rounded-[10px] border border-line-strong px-3 text-sm"

  defp trigger_class(:outline, :md),
    do: "inline-flex h-[42px] rounded-[11px] border border-line-strong px-3.5"

  defp trigger_class(:ghost, :sm), do: "inline-flex h-[38px] rounded-[10px] px-3 text-sm"
  defp trigger_class(:ghost, :md), do: "inline-flex h-[42px] rounded-[11px] px-3.5"

  defp trigger_class(:chip, _size),
    do: "composer-picker inline-flex h-8.5 rounded-[10px] border px-2.5 text-[13px] font-medium"

  defp trigger_class(:icon, :sm), do: "grid size-[38px] place-items-center rounded-[10px]"
  defp trigger_class(:icon, :md), do: "grid size-[42px] place-items-center rounded-[11px]"

  defp item_class(item, compact) do
    [
      (compact && "h-[34px] rounded-lg") || "h-[38px] rounded-[9px]",
      "flex w-full items-center justify-between gap-3 border-0 bg-transparent px-2.5 text-left text-sm no-underline outline-none disabled:cursor-not-allowed disabled:opacity-40 disabled:hover:bg-transparent",
      tone_class(Map.get(item, :danger))
    ]
  end

  defp tone_class(true),
    do: "text-tag-risk-text hover:bg-tag-risk-bg focus-visible:bg-tag-risk-bg"

  defp tone_class(_danger), do: "text-ink hover:bg-wrap focus-visible:bg-wrap"
end
