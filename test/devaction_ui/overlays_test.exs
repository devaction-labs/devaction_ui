defmodule DevactionUI.OverlaysTest do
  @moduledoc "The drawer, the modal, the dialog before something that cannot be undone and the tooltip."
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.{DangerDialog, Drawer, Modal, Tooltip}
  alias Phoenix.LiveView.JS

  describe "Drawer" do
    defp drawer(extra \\ %{}) do
      assigns = Map.merge(%{variant: :floating, side: :right, size: :md}, extra)

      rendered_to_string(~H"""
      <Drawer.drawer
        id="d"
        variant={@variant}
        side={@side}
        size={@size}
        on_close="close"
        close_label="Close"
      >
        <:close_icon>X</:close_icon>
        <:title>Edit profile</:title>
        <:subtitle>Your data</:subtitle>
        BODY
        <:footer>FOOT</:footer>
      </Drawer.drawer>
      """)
    end

    test "is a labelled modal dialog with a title, a subtitle, a body and a footer" do
      html = drawer()

      assert html =~ ~s(role="dialog")
      assert html =~ ~s(aria-modal="true")
      assert html =~ ~s(aria-labelledby="d-title")
      assert html =~ "Edit profile"
      assert html =~ "Your data"
      assert html =~ "BODY"
      assert html =~ "drawer-footer"
      assert html =~ ~s(aria-label="Close")
      assert html =~ "drawer-backdrop"
    end

    test "closes on Esc, the backdrop and the close button, and gives the focus back" do
      html = drawer()

      assert html =~ ~s(phx-hook="DevactionUI.Overlay")
      assert html =~ ~r/data-close="[^"]*pop_focus/
      assert length(Regex.scan(~r/pop_focus/, html)) >= 3
    end

    test "docks, comes from the left and takes the width" do
      assert drawer(%{variant: :docked}) =~ "drawer-docked"
      assert drawer(%{side: :left}) =~ "drawer-left"
      assert drawer(%{size: :sm}) =~ "drawer-sm"
      assert drawer(%{size: :lg}) =~ "drawer-lg"
      assert drawer(%{variant: :sheet}) =~ "drawer-sheet"
      refute drawer() =~ "drawer-docked"
      refute drawer() =~ "drawer-sheet"
    end

    test "the subtitle describes the dialog, and the handle shows at any width only on a sheet" do
      html = drawer()

      assert html =~ ~s(aria-describedby="d-subtitle")
      assert html =~ ~s(id="d-subtitle")
      assert html =~ "max-sm:flex"
      refute drawer(%{variant: :sheet}) =~ "max-sm:flex"
    end

    test "the drawer is above the page and under a modal, and the handle is a draggable area" do
      html = drawer()

      assert html =~ ~s(class="drawer-root")
      assert html =~ ~r/data-handle[^>]*touch-none/s
      assert html =~ ~r/data-handle[^>]*hidden max-sm:flex/s
      assert drawer(%{variant: :sheet}) =~ ~r/data-handle[^>]*flex flex-none/s
      refute drawer(%{variant: :sheet}) =~ "hidden max-sm:flex"

      assert html =~
               ~r/id="d"[^>]*phx-hook="DevactionUI.Overlay"|phx-hook="DevactionUI.Overlay"[^>]*id="d"/s
    end

    test "has no footer when it has no actions" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Drawer.drawer id="d" on_close={JS.push("c")} close_label="Close">
          <:close_icon>X</:close_icon>
          <:title>T</:title>
          B
        </Drawer.drawer>
        """)

      refute html =~ "drawer-footer"
      refute html =~ "aria-describedby"
    end

    test "open/1 remembers the focus before the event" do
      assert %JS{ops: [["push_focus", _], ["push", %{event: "go"}]]} = Drawer.open("go")

      assert %JS{ops: [["push_focus", _], ["push", %{event: "x"}]]} =
               Drawer.open(JS.push("x"))
    end
  end

  describe "lazy overlays (opened in the browser)" do
    defp lazy_drawer do
      assigns = %{}

      rendered_to_string(~H"""
      <Drawer.drawer id="d" lazy on_close="clear" close_label="Close">
        <:close_icon>X</:close_icon>
        <:title>Edit</:title>
        BODY
      </Drawer.drawer>
      """)
    end

    test "a drawer without lazy is not hidden and is unchanged" do
      refute drawer() =~ ~r/<div[^>]*id="d"[^>]*\shidden/
    end

    test "a lazy drawer is rendered hidden, and the server may not show it again" do
      html = lazy_drawer()

      assert html =~ ~r/<div[^>]*id="d"[^>]*\shidden/
      assert html =~ "ignore_attrs"
      refute html =~ "focus_first"
    end

    test "a lazy drawer hides itself in the browser and still runs on_close" do
      html = lazy_drawer()

      assert html =~ ~r/data-close="[^"]*pop_focus[^"]*clear[^"]*overlay-close[^"]*hidden/
    end

    test "show/1 remembers the focus, unhides, opens the overlay and focuses the panel in that order" do
      assert %JS{
               ops: [
                 ["push_focus", _],
                 ["remove_attr", %{attr: "hidden", to: "#d"}],
                 ["dispatch", %{event: "devaction:overlay-open", to: "#d"}],
                 ["focus_first", %{to: "#d-panel"}]
               ]
             } = Drawer.show("d")
    end

    test "hide/1 gives the focus back, closes the overlay and hides it" do
      assert %JS{
               ops: [
                 ["pop_focus", _],
                 ["dispatch", %{event: "devaction:overlay-close", to: "#d"}],
                 ["set_attr", %{to: "#d", attr: ["hidden", "hidden"]}]
               ]
             } = Drawer.hide("d")
    end

    test "the modal has the same lazy mode and the same commands" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Modal.modal id="m" lazy on_close="clear">
          <:title>T</:title>
        </Modal.modal>
        """)

      assert html =~ ~r/<div[^>]*id="m"[^>]*\shidden/
      assert html =~ ~r/data-close="[^"]*clear[^"]*overlay-close/
      assert Modal.show("m") == Drawer.show("m")
      assert Modal.hide("m") == Drawer.hide("m")
    end

    test "a modal that is not dismissible still ignores a click outside when lazy" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Modal.modal id="m" lazy dismissible={false} on_close="clear">
          <:title>T</:title>
        </Modal.modal>
        """)

      refute html =~ ~r/class="modal-backdrop"[^>]*phx-click/
    end
  end

  describe "Modal" do
    test "is a labelled dialog of the size asked, with the icon tile and the footer" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Modal.modal id="m" size={:sm} tone={:ok} on_close="close">
          <:icon>I</:icon>
          <:title>Done</:title>
          <:subtitle>All saved</:subtitle>
          <:footer>OK</:footer>
        </Modal.modal>
        """)

      assert html =~ ~s(role="dialog")
      assert html =~ "modal-sm"
      assert html =~ "modal-icon"
      assert html =~ "border-tag-ok-line"
      assert html =~ "modal-footer"
      assert html =~ "All saved"
      assert html =~ ~s(aria-describedby="m-subtitle")
      assert html =~ ~r/<div[^>]*id="m-subtitle"/
      refute html =~ ~s(aria-label=")
    end

    test "has no description when it has no subtitle, and the body scrolls inside the panel" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Modal.modal id="m" on_close="c">
          <:title>T</:title>
          BODY
        </Modal.modal>
        """)

      refute html =~ "aria-describedby"
      assert html =~ ~s(class="modal-body")
    end

    test "locks the page and answers Esc through the overlay hook, above a drawer" do
      assigns = %{}

      html =
        rendered_to_string(~H|<Modal.modal id="m" on_close="c">
  <:title>T</:title>
</Modal.modal>|)

      assert html =~ ~s(phx-hook="DevactionUI.Overlay")
      assert html =~ ~r/data-close="[^"]*pop_focus[^"]*"/
      assert html =~ "z-[70]"
      refute html =~ "phx-window-keydown"
      refute html =~ "data-handle"
    end

    test "open/1 remembers the focus before the event and close/1 gives it back" do
      assert %JS{ops: [["push_focus", _], ["push", %{event: "go"}]]} = Modal.open("go")
      assert %JS{ops: [["pop_focus", _], ["push", %{event: "x"}]]} = Modal.close("x")
      assert %JS{ops: [["push", %{event: "y"}], ["pop_focus", _]]} = Modal.close(JS.push("y"))
    end

    test "has a close button only when it has a label, and a centered success" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Modal.modal id="m" size={:lg} centered on_close="close" close_label="Close">
          <:close_icon>X</:close_icon>
          <:title>T</:title>
          BODY
          <:footer>F</:footer>
        </Modal.modal>
        """)

      assert html =~ ~s(aria-label="Close")
      assert html =~ "modal-lg"
      assert html =~ "text-center"
      assert html =~ "justify-center"
      assert html =~ "BODY"
    end

    test "a modal that is not dismissible ignores a click outside" do
      assigns = %{}

      locked =
        rendered_to_string(~H|<Modal.modal id="m" dismissible={false} on_close="c">
  <:title>T</:title>
</Modal.modal>|)

      open = rendered_to_string(~H|<Modal.modal id="m" on_close="c">
  <:title>T</:title>
</Modal.modal>|)

      refute locked =~ ~r/modal-backdrop[^>]*phx-click|phx-click[^>]*modal-backdrop/
      assert open =~ ~r/phx-click[^>]*|modal-backdrop/
      assert open =~ "pop_focus"
    end

    test "takes the focus on the control it is told, or on the first one" do
      assigns = %{}

      first = rendered_to_string(~H|<Modal.modal id="m" on_close="c">
  <:title>T</:title>
</Modal.modal>|)
      assert first =~ "focus_first"

      told =
        rendered_to_string(~H|<Modal.modal id="m" focus="#name" on_close="c">
  <:title>T</:title>
</Modal.modal>|)

      assert told =~ "#name"
      refute told =~ "focus_first"
    end

    test "every tone has its tile" do
      assigns = %{}

      for {tone, expected} <- [
            neutral: "bg-wrap",
            info: "tag-info",
            ok: "tag-ok",
            warn: "tag-warn",
            risk: "tag-risk"
          ] do
        html =
          rendered_to_string(~H"""
          <Modal.modal id="m" tone={tone} on_close="c">
            <:icon>I</:icon><:title>T</:title>
          </Modal.modal>
          """)

        assert html =~ expected
      end
    end
  end

  describe "DangerDialog" do
    defp danger(typed) do
      assigns = %{typed: typed}

      rendered_to_string(~H"""
      <DangerDialog.danger_dialog
        id="x"
        name="sge-api"
        typed={@typed}
        on_type="type"
        on_confirm="confirm"
        on_close="close"
        confirm_label="Stop"
        cancel_label="Cancel"
        close_label="Close"
      >
        <:icon>I</:icon>
        <:close_icon>X</:close_icon>
        <:title>Stop?</:title>
        <:type_label>Type <code>sge-api</code> to confirm</:type_label>
        What is lost.
      </DangerDialog.danger_dialog>
      """)
    end

    test "the red button stays locked until the name is typed" do
      assert DangerDialog.confirmed?("sge-api", "sge-api")
      assert DangerDialog.confirmed?("  sge-api ", "sge-api")
      refute DangerDialog.confirmed?("sge", "sge-api")
      refute DangerDialog.confirmed?(nil, "sge-api")

      locked = danger("sge")

      assert locked =~ ~r/id="x-confirm"[^>]*aria-disabled="true"/s or
               locked =~ ~s(aria-disabled="true")

      refute locked =~ ~s(phx-click="confirm")

      open = danger("sge-api")
      assert open =~ ~s(aria-disabled="false")
      assert open =~ ~s(phx-click="confirm")
      assert locked =~ ~s(data-unlocked="false")
      assert open =~ ~s(data-unlocked="true")
      assert locked =~ ~s(data-valid="false")
      assert open =~ ~s(data-valid="true")
    end

    test "Enter in the field submits the confirm event, and Cancel gives the focus back" do
      html = danger("")

      assert html =~ ~r/<form[^>]*phx-submit="confirm"/
      assert html =~ ~r/id="x-cancel"[^>]*phx-click="[^"]*pop_focus/s
    end

    test "the name chip draws the name as code, and the locked button says why through the sentence" do
      assigns = %{}

      chip =
        rendered_to_string(~H|<DangerDialog.name_chip class="x">sge-api</DangerDialog.name_chip>|)

      assert chip =~ ~r/<code[^>]*class="[^"]*font-mono[^"]*"[^>]*>sge-api<\/code>/
      html = danger("sge")
      assert html =~ ~s(id="x-type-label")
      assert html =~ ~r/id="x-confirm"[^>]*aria-describedby="x-type-label"/s
    end

    test "the aria-disabled of the red button follows what was typed" do
      assert danger("") =~ ~r/id="x-confirm"[^>]*aria-disabled="true"/s
      assert danger("sge-api") =~ ~r/id="x-confirm"[^>]*aria-disabled="false"/s
    end

    test "the sentence over the field is a slot and the field is described by the explanation" do
      html = danger("")

      assert html =~ "<code>sge-api</code>"
      assert html =~ ~r/id="x-typed"[^>]*aria-describedby="x-subtitle"/s
      assert html =~ ~s(id="x-subtitle")
    end

    test "asks for the name in a field that reports each key and does not close on a click outside" do
      html = danger("")

      assert html =~ ~s(phx-keyup="type")
      assert html =~ "#x-typed"
      assert html =~ "focus"
      assert html =~ ~s(autocomplete="off")
      assert html =~ "What is lost."
      refute html =~ ~r/modal-backdrop[^>]*phx-click/
    end
  end

  describe "Tooltip" do
    test "is described by its text and starts on each of the four sides" do
      for side <- [:top, :bottom, :left, :right] do
        assigns = %{side: side}

        html =
          rendered_to_string(~H"""
          <Tooltip.tooltip id="t" text="Search" placement={@side}><button>S</button></Tooltip.tooltip>
          """)

        assert html =~ ~s(role="tooltip")
        assert html =~ ~s(data-tip="t-tip")
        assert html =~ ~s(id="t-tip")
        assert html =~ ~s(data-side="#{side}")
        assert html =~ ~s(data-placement="#{side}")
      end
    end

    test "can be hovered and dismissed: it takes the pointer only while shown" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tooltip.tooltip id="t" text="Search"><button>S</button></Tooltip.tooltip>
        """)

      assert html =~ "group-hover/tip:pointer-events-auto"
      assert html =~ "group-focus-within/tip:pointer-events-auto"
      assert html =~ "group-data-[dismissed]/tip:!pointer-events-none"
      assert html =~ "pointer-events-none"
    end

    test "waits before showing, shows the shortcut and the rich variant has a heading" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tooltip.tooltip id="t" text="Search" shortcut="⌘K"><button>S</button></Tooltip.tooltip>
        """)

      assert html =~ "delay-[400ms]"
      assert html =~ "⌘K"
      assert html =~ "<kbd"
      assert html =~ "bg-kbd-inverse"
      assert html =~ "shadow-tip"
      assert html =~ "px-[9px]"
      assert html =~ "group-data-[dismissed]/tip"

      rich =
        rendered_to_string(~H"""
        <Tooltip.tooltip id="t" title="RingScore 69" text="18 of 26"><button>S</button></Tooltip.tooltip>
        """)

      assert rich =~ "RingScore 69"
      assert rich =~ "max-w-[280px]"
      assert rich =~ "rounded-xl"
      assert rich =~ "shadow-tip-rich"
      refute rich =~ "<kbd"
    end

    test "draws an arrow that the hook and the CSS turn to the side of the trigger" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tooltip.tooltip id="t" text="Search"><button>S</button></Tooltip.tooltip>
        """)

      assert html =~ ~s(class="tip-arrow")
      assert html =~ ~s(aria-hidden="true")
      assert html =~ "tip "
    end
  end
end
