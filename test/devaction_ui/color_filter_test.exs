defmodule DevactionUI.ColorFilterTest do
  @moduledoc "The colour picker and the filter menu: the markup the hooks drive and the form fields they send."
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.{ColorPicker, FilterMenu}

  @picker_defaults %{
    id: "project-color",
    name: "project[color]",
    value: "#DC2626",
    label: "Project colour",
    toggle_label: "Open the colour picker",
    area_label: "Saturation and brightness",
    hue_label: "Hue",
    presets_label: "Ready colours"
  }

  defp picker(extra \\ %{}) do
    assigns = Map.merge(@picker_defaults, extra)

    rendered_to_string(~H"""
    <ColorPicker.color_picker {assigns} />
    """)
  end

  describe "ColorPicker" do
    test "the field is a text input named for the form and holding the hex" do
      html = picker()

      assert html =~ ~s(phx-hook="DevactionUI.ColorPicker")
      assert html =~ ~s(name="project[color]")
      assert html =~ ~s(value="#DC2626")
      assert html =~ ~s(<label for="project-color")
      assert html =~ ~s(maxlength="9")
    end

    test "the panel starts closed and the swatch says it opens a dialog" do
      html = picker()

      assert html =~ ~r/data-panel[^>]* hidden|hidden[^>]*data-panel/s
      assert html =~ ~s(aria-haspopup="dialog")
      assert html =~ ~s(aria-expanded="false")
      assert html =~ ~s(aria-label="Open the colour picker")
    end

    test "the square is a slider with a name, and the hue strip too" do
      html = picker()

      assert html =~ ~s(role="slider")
      assert html =~ ~s(aria-label="Saturation and brightness")
      assert html =~ ~s(aria-label="Hue")
      assert html =~ ~s(max="360")
    end

    test "there are eight presets by default, each a toggle button named by its colour" do
      html = picker()

      assert length(Regex.scan(~r/data-preset="#/, html)) == 8
      assert html =~ ~s(role="group")
      assert html =~ ~s(aria-label="Ready colours")
      assert html =~ ~s(data-preset="#2563EB")
    end

    test "the presets can be the caller's own" do
      html = picker(%{presets: ["#111111", "#EEEEEE"]})

      assert length(Regex.scan(~r/data-preset="#/, html)) == 2
    end

    test "opacity and the eyedropper appear only when asked for" do
      refute picker() =~ "data-alpha"
      refute picker() =~ "data-eyedropper"

      html =
        picker(%{alpha: true, alpha_label: "Opacity", eyedropper_label: "Pick from the screen"})

      assert html =~ "data-alpha"
      assert html =~ ~s(aria-label="Opacity")
      assert html =~ "data-eyedropper"
      assert html =~ "Pick from the screen"
    end

    test "the panel shows the hex, and the eyedropper takes an icon in place of its text" do
      html = picker()
      assert html =~ ~r/<output[^>]*data-value-text[^>]*>#DC2626</

      assigns = %{}

      with_icon =
        rendered_to_string(~H"""
        <ColorPicker.color_picker
          id="c"
          name="c"
          label="Colour"
          toggle_label="Open"
          area_label="Area"
          hue_label="Hue"
          presets_label="Presets"
          eyedropper_label="Pick from the screen"
        >
          <:eyedropper_icon>DROP</:eyedropper_icon>
        </ColorPicker.color_picker>
        """)

      assert with_icon =~ "DROP"
      assert with_icon =~ ~s(aria-label="Pick from the screen")
      refute with_icon =~ ">Pick from the screen<"
    end

    test "the field takes disabled and required, and the hook sits on id-picker" do
      html = picker(%{disabled: true, required: true})

      assert html =~ ~s(id="project-color-picker")
      assert html =~ ~r/<input[^>]*data-input[^>]* disabled/
      assert html =~ ~r/<input[^>]*data-input[^>]* required/
      assert html =~ ~r/<button[^>]*data-toggle[^>]* disabled/
      refute picker() =~ " required"
    end

    test "an error is written under the field and tied to it" do
      html = picker(%{error: "Pick a valid colour"})

      assert html =~ "Pick a valid colour"
      assert html =~ ~s(aria-invalid="true")
      assert html =~ ~s(aria-describedby="project-color-error")
      assert html =~ ~s(id="project-color-error")
    end

    test "a value that is not a colour never reaches the style or the data attribute" do
      html = picker(%{value: "red;position:fixed;inset:0;background:url(//evil/x)"})

      refute html =~ "position:fixed" and html =~ "--cp-color: red"
      assert html =~ "--cp-color: #2563EB"
      assert html =~ ~s(data-value="#2563EB")
    end

    test "what the person typed is still shown in the field, escaped" do
      html = picker(%{value: ~s(<b>"x")})

      assert html =~ "&lt;b&gt;"
      refute html =~ ~s(<b>"x")
    end

    test "a preset that is not a colour is dropped" do
      html = picker(%{presets: ["#111111", "javascript:alert(1)", "#GGGGGG", "#22222280"]})

      assert length(Regex.scan(~r/data-preset="/, html)) == 2
      refute html =~ "javascript"
    end

    test "the words the browser says aloud are the caller's template" do
      html = picker(%{area_text: "%{color}, %{saturation} per cent"})

      assert html =~ ~s(data-area-text="%{color}, %{saturation} per cent")
    end
  end

  @groups [
    %{
      key: "status",
      label: "Status",
      type: :checkbox,
      options: [
        %{value: "progress", label: "In progress", count: 2, checked: true},
        %{value: "review", label: "In review", count: 4}
      ]
    },
    %{
      key: "order",
      label: "Order",
      type: :radio,
      options: [
        %{value: "deadline", label: "Deadline", checked: true, default: true},
        %{value: "recent", label: "Recent"}
      ]
    },
    %{
      key: "who",
      label: "Person",
      type: :checkbox,
      options: [%{value: "CA", label: "Carlos André", avatar: "CA"}]
    }
  ]

  defp menu do
    assigns = %{groups: @groups}

    rendered_to_string(~H"""
    <FilterMenu.filter_menu
      id="task-filters"
      label="Filter"
      groups={@groups}
      apply_label="Apply"
      reset_label="Clear"
      close_label="Close"
      phx-submit="apply_filters"
    >
      <:trigger_icon>T</:trigger_icon>
      <:group_icon :let={group}>G-{group.key}</:group_icon>
      <:chevron_icon>›</:chevron_icon>
      <:check_icon>✓</:check_icon>
      <:close_icon>x</:close_icon>
    </FilterMenu.filter_menu>
    """)
  end

  describe "FilterMenu" do
    test "the button opens a menu that is a form sending where the caller says" do
      html = menu()

      assert html =~ ~s(phx-hook="DevactionUI.FilterMenu")
      assert html =~ ~s(aria-haspopup="menu")
      assert html =~ ~s(aria-controls="task-filters-menu")
      assert html =~ ~s(phx-submit="apply_filters")
      assert html =~ ~s(type="submit")
    end

    test "every group is a row and has its own submenu, both closed" do
      html = menu()

      for key <- ~w(status order who) do
        assert html =~ ~s(data-submenu-trigger="#{key}")
        assert html =~ ~s(data-submenu="#{key}")
        assert html =~ ~s(data-count-for="#{key}")
      end

      assert length(Regex.scan(~r/data-submenu="/, html)) == 3
    end

    test "a checkbox group has checkboxes and a radio group has radios, all named under filters" do
      html = menu()

      assert html =~ ~s(type="checkbox" name="filters[status][]" value="progress")
      assert html =~ ~s(type="radio" name="filters[order][]" value="deadline")
      assert html =~ ~s(role="menuitemcheckbox")
      assert html =~ ~s(role="menuitemradio")
    end

    test "a ticked option is checked and a default option is marked so it is not counted" do
      html = menu()

      assert html =~ ~r/value="progress" checked/
      assert html =~ ~r/value="deadline" checked[^>]*data-default/
      refute html =~ ~r/value="review" checked/
    end

    test "the option carries its count and its avatar when it has them" do
      html = menu()

      assert html =~ ~s(<span class="menu-check-meta">4</span>)
      assert html =~ ~s(<span class="avatar avatar-xs">CA</span>)
    end

    test "the icons are the caller's slots and the group's icon gets the group" do
      html = menu()

      assert html =~ "G-status"
      assert html =~ "G-who"
      assert html =~ "›"
      assert html =~ "✓"
    end

    test "the total on the button and the footer actions are there" do
      html = menu()

      assert html =~ "data-count-total"
      assert html =~ "data-menu-reset"
      assert html =~ "Clear"
      assert html =~ "Apply"
    end

    defp render_menu(groups, extra \\ %{}) do
      assigns = %{groups: groups, extra: extra}

      rendered_to_string(~H"""
      <FilterMenu.filter_menu
        id="m"
        label="Filter"
        groups={@groups}
        apply_label="Apply"
        reset_label="Clear"
        close_label="Close"
        {@extra}
      >
        <:option_icon :let={slot}>O-{slot.group}-{slot.option.value}</:option_icon>
      </FilterMenu.filter_menu>
      """)
    end

    test "Clear only unticks by default and submits the form with reset_submits" do
      assert menu() =~ ~s(data-reset="change")
      assert render_menu(@groups) =~ ~s(data-reset="change")
      assert render_menu(@groups, %{reset_submits: true}) =~ ~s(data-reset="submit")
    end

    test "the Apply button has a count of pending changes, hidden until there are some" do
      html = menu()

      assert html =~ ~r/data-count-pending[^>]*hidden/
    end

    test "an option can have an icon, given its group and the option" do
      html = render_menu(@groups)

      assert html =~ "O-status-progress"
      assert html =~ "O-order-deadline"
    end

    test "the panel and the submenus take their side, and the shadow is the menu's" do
      start = render_menu(@groups)
      assert start =~ ~s(data-align="start")
      assert start =~ ~s(data-align="right")
      assert start =~ ~s(data-side="right")

      far = render_menu(@groups, %{align: :end})
      assert far =~ ~s(data-align="end")
      assert far =~ ~s(data-align="left")
      assert far =~ ~s(data-side="left")

      css = File.read!("assets/css/devaction_ui.css")
      assert css =~ ~r/\.menu-panel\s+\{[^}]*shadow-menu/
      assert css =~ ~r/\.menu-sub\s+\{[^}]*shadow-menu[^}]*data-\[side=left\]/
    end

    test "the class goes to the root and the form keeps the global attributes" do
      html = render_menu(@groups, %{class: "extra-root", "phx-change": "filter", "data-x": "1"})

      assert html =~ ~r/<div id="m" class="filter-menu extra-root"/
      assert html =~ ~r/<form[^>]*phx-change="filter"/
      assert html =~ ~r/<form[^>]*data-x="1"/
    end

    test "a group with a type that is not checkbox or radio raises" do
      groups = [%{key: "x", label: "X", type: :tree, options: [%{value: "a", label: "A"}]}]

      assert_raise FunctionClauseError, fn -> render_menu(groups) end
    end
  end
end
