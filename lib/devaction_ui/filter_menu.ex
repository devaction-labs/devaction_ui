defmodule DevactionUI.FilterMenu do
  @moduledoc """
  A button that opens a menu of filter groups; a group opens a submenu of ticks, checkboxes or radios. Ticking
  does not close the menu. The menu is a form: it sends on Apply (`phx-submit`), or on every tick with
  `phx-change`, as `%{"filters" => %{"status" => ["progress"], "who" => ["CA"]}}`. A count on each group and on the
  button follows the ticks, except for an option marked `default`, which is what the filter already means.

  A group is `%{key: "status", label: "Status", type: :checkbox, options: [...]}`; `type` is `:checkbox` or
  `:radio` and anything else raises. An option is
  `%{value: "progress", label: "In progress", count: 2, checked: true, default: false, avatar: "CA"}`; `count`,
  `checked`, `default` and `avatar` are optional, and the `option_icon` slot draws an icon or a color dot before
  the label of each option.

  The count on the button is the number of filters that were applied: the ones sent by the last Apply (or, when
  the form has `phx-change`, every tick). The counts on the groups follow the ticks, and the Apply button shows
  how many changes it would send. Applying gives the focus back to the button; the menu also closes when the
  focus leaves it. Arrows move, → opens a submenu, ← and Esc go back, Enter and Space tick. Words are
  attributes and icons are slots.

  Clear (`reset_label`) unticks every option, back to the `default` ones. With `reset_submits` it then submits
  the form, so the server hears the empty filters at once; without it, it only unticks, and Apply (or
  `phx-change`) sends them. The count on the button is only for what was applied, so it drops when Clear
  submits.

  `align` is the side of the button the panel lines up with; the submenus open to the right of the panel for
  `:start` and to the left for `:end`, and turn to the other side when there is no room on the screen. `class`
  goes to the root; `phx-submit`, `phx-change`, `phx-target` and the other global attributes go to the form.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  attr :id, :string, required: true
  attr :label, :string, required: true, doc: "the button's text and the menu's name"
  attr :groups, :list, required: true
  attr :apply_label, :string, required: true
  attr :reset_label, :string, required: true
  attr :close_label, :string, required: true
  attr :align, :atom, values: [:start, :end], default: :start

  attr :reset_submits, :boolean,
    default: false,
    doc:
      "Clear also submits the form, which sends the empty filters and applies them; false only unticks (and sends `phx-change`, if the form has it)"

  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(phx-submit phx-change phx-target)
  slot :trigger_icon, doc: "the icon of the button"
  slot :group_icon, doc: "the icon of a group's row; gets the group"
  slot :chevron_icon, doc: "the arrow at the end of a group's row"
  slot :check_icon, doc: "the mark of a ticked option"
  slot :close_icon, doc: "the icon of the close button"

  slot :option_icon,
    doc: "an icon or a color dot before an option; gets `%{group: key, option: option}`"

  @spec filter_menu(map()) :: Phoenix.LiveView.Rendered.t()

  def filter_menu(assigns) do
    ~H"""
    <div
      id={@id}
      class={["filter-menu", @class]}
      phx-hook="DevactionUI.FilterMenu"
      data-reset={(@reset_submits && "submit") || "change"}
    >
      <button
        type="button"
        class="menu-trigger"
        data-menu-trigger
        aria-haspopup="menu"
        aria-expanded="false"
        aria-controls={@id <> "-menu"}
        phx-mounted={keep_client_attributes()}
      >
        {render_slot(@trigger_icon)}{@label}<span
          class="menu-badge"
          data-count-total
          hidden
          phx-mounted={keep_client_attributes()}
        >0</span>
      </button>
      <form
        id={@id <> "-menu"}
        class="menu-panel"
        role="menu"
        aria-label={@label}
        data-menu
        data-align={@align}
        hidden
        phx-mounted={keep_client_attributes()}
        {@rest}
      >
        <div class="menu-head">
          <span>{@label}</span>
          <button
            type="button"
            data-menu-close
            aria-label={@close_label}
            class="grid size-7.5 place-items-center rounded-lg text-ink-2 hover:bg-wrap"
          >
            {render_slot(@close_icon)}
          </button>
        </div>
        <div class="menu-list">
          <button
            :for={group <- @groups}
            type="button"
            role="menuitem"
            class="menu-row"
            data-submenu-trigger={group.key}
            aria-haspopup="menu"
            aria-expanded="false"
            phx-mounted={keep_client_attributes()}
          >
            {render_slot(@group_icon, group)}
            <span class="flex-1">{group.label}</span>
            <span
              class="menu-count"
              data-count-for={group.key}
              hidden
              phx-mounted={keep_client_attributes()}
            >0</span>
            {render_slot(@chevron_icon)}
          </button>
        </div>
        <div
          :for={group <- @groups}
          class="menu-sub"
          role="menu"
          aria-label={group.label}
          data-submenu={group.key}
          data-align={sub_side(@align)}
          data-side={sub_side(@align)}
          hidden
          phx-mounted={keep_client_attributes()}
        >
          <label
            :for={option <- group.options}
            class="menu-check"
            role={item_role(group)}
            aria-checked={to_string(option[:checked] == true)}
            tabindex="-1"
            phx-mounted={keep_client_attributes()}
          >
            <input
              type={input_type(group)}
              name={"filters[#{group.key}][]"}
              value={option.value}
              checked={option[:checked] == true}
              data-group={group.key}
              data-default={option[:default] == true && ""}
              tabindex="-1"
            />
            <span
              :if={@option_icon != []}
              class="grid size-4 shrink-0 place-items-center"
              aria-hidden="true"
            >
              {render_slot(@option_icon, %{group: group.key, option: option})}
            </span>
            <span :if={option[:avatar]} class="avatar avatar-xs">{option.avatar}</span>
            <span class="flex-1">{option.label}</span>
            <span :if={option[:count]} class="menu-check-meta">{option.count}</span>
            <span class="menu-check-mark">{render_slot(@check_icon)}</span>
          </label>
        </div>
        <div class="menu-footer">
          <button
            type="button"
            data-menu-reset
            class="h-9.5 cursor-pointer rounded-[10px] border border-line-strong bg-card px-4 text-sm font-medium text-ink hover:bg-wrap"
          >
            {@reset_label}
          </button>
          <button
            type="submit"
            class="inline-flex h-9.5 cursor-pointer items-center justify-center rounded-[10px] bg-ink px-4 text-sm font-medium text-on-primary hover:opacity-90"
          >
            {@apply_label}<span
              class="ml-2 grid h-4.5 min-w-4.5 place-items-center rounded-full bg-on-primary/20 px-1.25 text-[11px] font-semibold"
              data-count-pending
              hidden
              phx-mounted={keep_client_attributes()}
            >0</span>
          </button>
        </div>
      </form>
    </div>
    """
  end

  defp input_type(%{type: :radio}), do: "radio"
  defp input_type(%{type: :checkbox}), do: "checkbox"

  defp item_role(%{type: :radio}), do: "menuitemradio"
  defp item_role(%{type: :checkbox}), do: "menuitemcheckbox"

  defp sub_side(:start), do: "right"
  defp sub_side(:end), do: "left"

  defp keep_client_attributes do
    JS.ignore_attributes([
      "hidden",
      "aria-expanded",
      "aria-checked",
      "style",
      "data-open",
      "data-side"
    ])
  end
end
