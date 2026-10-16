defmodule DevactionUI.ToastGroupTest do
  @moduledoc "The toast group: the region, its attributes, the templates of the icons, the flash and the helpers that push toasts."
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.ToastGroup
  alias Phoenix.LiveView.Socket

  defp render_group(extra) do
    assigns = %{extra: extra}

    rendered_to_string(~H"""
    <ToastGroup.toast_group label="Notifications (Alt+T)" dismiss_label="Close" {@extra} />
    """)
  end

  defp events(socket), do: socket.private.live_temp.push_events |> Enum.reverse()

  describe "the region" do
    test "is a polite live region with its name, the hook and a list the browser owns" do
      html = render_group(%{})

      assert html =~ ~s(id="toasts")
      assert html =~ ~s(role="region")
      assert html =~ ~s[aria-label="Notifications (Alt+T)"]
      assert html =~ ~s(aria-live="polite")
      assert html =~ ~s(phx-hook="DevactionUI.ToastGroup")
      assert html =~ ~s(data-dismiss-label="Close")
      assert html =~ ~r/<ol[^>]*id="toasts-list"[^>]*data-toasts[^>]*phx-update="ignore"/s
    end

    test "has the position, the count that shows, the duration and the target" do
      html =
        render_group(%{
          position: "top-left",
          visible: 2,
          duration: 1500,
          target: "#panel",
          id: "tg"
        })

      assert html =~ ~s(data-position="top-left")
      assert html =~ ~s(data-visible="2")
      assert html =~ ~s(data-duration="1500")
      assert html =~ ~s(phx-target="#panel")
      assert html =~ ~s(id="tg-list")
    end

    test "Alt+T goes to it unless the hotkey is off" do
      assert render_group(%{}) =~ ~s(data-hotkey="true")
      assert render_group(%{hotkey: false}) =~ ~s(data-hotkey="false")
    end

    test "is fixed unless it is inline" do
      refute render_group(%{}) =~ "data-inline"
      assert render_group(%{inline: true}) =~ "data-inline"
    end

    test "the label and the dismiss label are required" do
      assert ToastGroup.__components__().toast_group.attrs
             |> Enum.filter(& &1.required)
             |> Enum.map(& &1.name)
             |> Enum.sort() == [:dismiss_label, :label]
    end
  end

  describe "icons" do
    test "each variant and the close button have a template with the default glyph" do
      html = render_group(%{})

      for name <- ~w(ok warn risk info ai loading close) do
        assert html =~ ~s(<template data-icon="#{name}">)
      end

      assert html =~ "M5 13l4 4L19 7"
      assert html =~ "M6 6l12 12M18 6L6 18"
      refute html =~ ~s(data-icon="default")
    end

    test "the slots replace the glyphs" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <ToastGroup.toast_group label="N" dismiss_label="Close">
          <:icon :let={variant}><i class={"mine-#{variant}"}></i></:icon>
          <:close_icon><b class="mine-close">x</b></:close_icon>
        </ToastGroup.toast_group>
        """)

      assert html =~ ~s(class="mine-ok")
      assert html =~ ~s(class="mine-loading")
      assert html =~ ~s(class="mine-close")
      refute html =~ "M5 13l4 4L19 7"
    end
  end

  describe "flash" do
    test "info becomes an ok toast and error a risk one, for the hook to show" do
      html = render_group(%{flash: %{"info" => "Saved", "error" => "Failed"}})

      assert html =~ "Saved"
      assert html =~ "flash-info"
      assert html =~ "Failed"
      assert html =~ "flash-error"
      assert html =~ "&quot;variant&quot;:&quot;ok&quot;"
      assert html =~ "&quot;variant&quot;:&quot;risk&quot;"
    end

    test "no flash, no initial toasts" do
      assert render_group(%{}) =~ ~s(data-initial="[]")
    end
  end

  describe "server helpers" do
    test "put_toast pushes the toast with its variant, title and options" do
      socket =
        %Socket{}
        |> ToastGroup.put_toast(:ok, "Saved", id: "a", description: "PR #214", duration: nil)
        |> ToastGroup.put_toast(:default, "Deleted",
          action: %{label: "Undo", event: "undo", value: %{id: 9}}
        )

      assert [["toast", first], ["toast", second]] = events(socket)
      assert first == %{variant: :ok, title: "Saved", id: "a", description: "PR #214"}
      assert second.action == %{label: "Undo", event: "undo", value: %{id: 9}}
      refute Map.has_key?(second, :id)
    end

    test "a variant outside the set is refused" do
      assert_raise FunctionClauseError, fn ->
        apply(ToastGroup, :put_toast, [%Socket{}, :nope, "x"])
      end
    end

    test "update_toast turns a loading toast into another by the same id" do
      socket = ToastGroup.update_toast(%Socket{}, "report", variant: :ok, title: "Ready")
      assert [["toast:update", %{id: "report", variant: :ok, title: "Ready"}]] = events(socket)
    end

    test "dismiss_toast and clear_toasts" do
      socket = %Socket{} |> ToastGroup.dismiss_toast("a") |> ToastGroup.clear_toasts()
      assert [["toast:dismiss", %{id: "a"}], ["toast:clear", %{}]] = events(socket)
    end

    test "a group names the one of several that gets the event" do
      socket =
        %Socket{}
        |> ToastGroup.put_toast(:ok, "Saved", group: "side")
        |> ToastGroup.update_toast("a", group: "side", title: "Done")
        |> ToastGroup.dismiss_toast("a", group: "side")
        |> ToastGroup.clear_toasts(group: "side")

      assert [
               ["toast", %{group: "side"}],
               ["toast:update", %{group: "side", id: "a"}],
               ["toast:dismiss", %{group: "side", id: "a"}],
               ["toast:clear", %{group: "side"}]
             ] = events(socket)
    end
  end
end
