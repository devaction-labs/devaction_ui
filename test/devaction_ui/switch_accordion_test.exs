defmodule DevactionUI.SwitchAccordionTest do
  @moduledoc "The switch for what takes effect at once, and the accordion in its four ways."
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.{Accordion, Switch}

  describe "Switch" do
    test "is a switch button that says its state" do
      assigns = %{}

      off = rendered_to_string(~H|<Switch.switch id="s" label="Auto" phx-click="go" />|)
      assert off =~ ~s(role="switch")
      assert off =~ ~s(aria-checked="false")
      assert off =~ ~s(aria-label="Auto")
      assert off =~ ~s(type="button")
      assert off =~ ~s(phx-click="go")
      refute off =~ "aria-busy"

      on = rendered_to_string(~H|<Switch.switch id="s" checked />|)
      assert on =~ ~s(aria-checked="true")
    end

    test "takes the size and the tone from the canvas classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Switch.switch id="a" size={:sm} />
        <Switch.switch id="b" size={:lg} tone={:ai} />
        <Switch.switch id="c" tone={:ok} />
        """)

      assert html =~ "switch-sm"
      assert html =~ "switch-lg"
      assert html =~ "switch-ai"
      assert html =~ "switch-ok"
    end

    test "saving and disabled ignore presses and say so" do
      assigns = %{}

      saving = rendered_to_string(~H|<Switch.switch id="s" saving phx-click="go" />|)
      assert saving =~ ~s(aria-busy="true")
      assert saving =~ ~s(aria-disabled="true")
      refute saving =~ "phx-click"
      assert saving =~ "animate-spin"

      disabled = rendered_to_string(~H|<Switch.switch id="s" disabled phx-click="go" />|)
      assert disabled =~ ~s(aria-disabled="true")
      refute disabled =~ "phx-click"
      refute disabled =~ "animate-spin"
    end

    test "a tone with disabled keeps its class and still ignores presses" do
      assigns = %{}

      html = rendered_to_string(~H|<Switch.switch id="s" tone={:ok} disabled phx-click="go" />|)

      assert html =~ "switch-ok"
      assert html =~ ~s(aria-disabled="true")
      refute html =~ "phx-click"
    end

    test "the icon goes in the thumb with the state, and gives way to the spinner" do
      assigns = %{}

      on =
        rendered_to_string(~H"""
        <Switch.switch id="s" checked>
          <:icon :let={state}>{to_string(state.checked)}-MARK</:icon>
        </Switch.switch>
        """)

      assert on =~ ~r/switch-thumb[^>]*>[^<]*true-MARK/

      saving =
        rendered_to_string(~H"""
        <Switch.switch id="s" saving>
          <:icon :let={_state}>MARK</:icon>
        </Switch.switch>
        """)

      refute saving =~ "MARK"
    end

    test "a row and a card are named by their label and keep the description" do
      assigns = %{}

      row =
        rendered_to_string(
          ~H|<Switch.switch_row id="r" label="Weekly" description="On Monday" phx-click="go" />|
        )

      assert row =~ "switch-row"
      assert row =~ ~s(id="r-label")
      assert row =~ ~s(aria-labelledby="r-label")
      assert row =~ "On Monday"
      assert row =~ ~s(<label for="r")
      assert row =~ ~s(aria-describedby="r-description")
      assert row =~ "leading-[1.45]"
      refute row =~ "data-disabled"

      dimmed = rendered_to_string(~H|<Switch.switch_row id="r" label="Weekly" disabled />|)
      assert dimmed =~ ~s(data-disabled="true")

      card =
        rendered_to_string(~H"""
        <Switch.switch_card id="c" label="Lessons" checked>
          <:icon>ICON</:icon>
          <:thumb_icon :let={state}>{to_string(state.checked)}-THUMB</:thumb_icon>
        </Switch.switch_card>
        """)

      assert card =~ "switch-card"
      assert card =~ ~r/switch-card-mark[^>]*>\s*ICON/
      assert card =~ "true-THUMB"
      assert card =~ ~s(aria-checked="true")
      refute card =~ "text-[13px] text-muted"
    end

    test "the confirmation is a status band with its icon" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Switch.saved_note id="n">
          <:icon>TICK</:icon>
          Saved now
        </Switch.saved_note>
        """)

      assert html =~ ~s(role="status")
      assert html =~ "Saved now"
      assert html =~ "TICK"
      assert html =~ "bg-ok-bg"
    end

    test "the live region is there even when the confirmation is not" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<Switch.saved_note id="n" show={false}>Saved now</Switch.saved_note>|
        )

      assert html =~ ~s(id="n")
      assert html =~ ~s(role="status")
      refute html =~ "Saved now"
    end
  end

  describe "Accordion" do
    test "the plain one has dividers, a chevron and a panel, and opens one at a time" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Accordion.accordion id="a" variant={:plain}>
          <:item title="One" open>First</:item>
          <:item title="Two" disabled>Second</:item>
        </Accordion.accordion>
        """)

      assert html =~ ~s(class="accordion")
      assert html =~ "accordion-trigger"
      assert html =~ "accordion-chevron"
      assert html =~ "accordion-panel"
      assert html =~ ~s(name="a")
      assert html =~ "pointer-events-none"
    end

    test "a card has the lead, the sub line, the tag and the actions in its header" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Accordion.accordion id="c" variant={:card} exclusive={false}>
          <:lead :let={item}>LEAD{item.index}</:lead>
          <:actions :let={item}>ACT{item.title}</:actions>
          <:item title="M1" subtitle="Delivered" tag="PAID" tone={:ok}>Body</:item>
        </Accordion.accordion>
        """)

      assert html =~ "accordion-card"
      assert html =~ "LEAD0"
      assert html =~ "ACTM1"
      assert html =~ "Delivered"
      assert html =~ "PAID"
      refute html =~ ~s(name="c")
    end

    test "the group and the flush ones keep their plus and minus" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Accordion.accordion id="g">
          <:item title="A" count="2">a</:item>
        </Accordion.accordion>
        <Accordion.accordion id="f" variant={:flush}>
          <:item title="B">b</:item>
        </Accordion.accordion>
        """)

      assert html =~ "+"
      assert html =~ "−"
      assert html =~ "border-line-soft"
      assert html =~ ~r{>\s*2\s*<}
    end
  end
end
