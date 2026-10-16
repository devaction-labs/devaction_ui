defmodule DevactionUI.AccordionTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.Accordion

  defp card(extra \\ %{}) do
    assigns = extra

    rendered_to_string(~H"""
    <Accordion.accordion id="c" variant={:card} exclusive={false}>
      <:actions :let={item}><button id={"act-#{item.index}"}>ACT</button></:actions>
      <:item title="M1" count="3" count_tone={:risk}>Body</:item>
    </Accordion.accordion>
    """)
  end

  test "the actions of a card sit beside the summary, never inside it" do
    html = card()
    [summary] = Regex.run(~r/<summary.*?<\/summary>/s, html)

    refute summary =~ "ACT"
    assert html =~ "ACT"
    assert html =~ "absolute top-0 right-3"
    assert summary =~ "pr-[58px]"
  end

  test "a card without actions keeps a short right padding" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Accordion.accordion id="c" variant={:card}>
        <:item title="M1">Body</:item>
      </Accordion.accordion>
      """)

    assert html =~ "pr-3"
    refute html =~ "pr-[58px]"
  end

  test "the card has its chevron at the start, turning a quarter" do
    html = card()
    [summary] = Regex.run(~r/<summary.*?<\/summary>/s, html)

    assert summary =~ ~r/<summary[^>]*>\s*<svg[^>]*group-open:rotate-90/
    refute html =~ "accordion-chevron"
  end

  test "the count is a pill, tinted by its tone" do
    html = card()

    assert html =~ "rounded-full"
    assert html =~ "border-tag-risk-line"
    assert html =~ "text-tag-risk-text"

    assigns = %{}

    plain =
      rendered_to_string(~H"""
      <Accordion.accordion id="p" variant={:plain}>
        <:item title="A" count="2">a</:item>
      </Accordion.accordion>
      """)

    assert plain =~ "bg-wrap text-ink-2"
  end

  test "the group is 50px tall with a 14px chevron and the panel indented under the title" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Accordion.accordion id="g">
        <:item title="A">a</:item>
      </Accordion.accordion>
      """)

    assert html =~ "min-h-[50px]"
    assert html =~ "rounded-[14px]"
    assert html =~ "size-3.5"
    assert html =~ "pl-[38px]"
  end

  test "the flush one is 44px with a plus that never becomes a minus" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Accordion.accordion id="f" variant={:flush}>
        <:item title="A">a</:item>
      </Accordion.accordion>
      """)

    assert html =~ "min-h-11"
    assert html =~ "text-sm"
    refute html =~ "text-[15px]"
    assert html =~ ">+<"
    refute html =~ "−"
    refute html =~ "group-open:hidden"
  end

  test "exclusive false leaves the sections without a shared name" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Accordion.accordion id="x" exclusive={false} variant={:plain}>
        <:item title="A" open>a</:item>
        <:item title="B" open>b</:item>
      </Accordion.accordion>
      """)

    refute html =~ "name="
    assert length(Regex.scan(~r/<details[^>]*\sopen[\s>]/, html)) == 2
  end

  test "a disabled section is a row that cannot be focused or opened" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Accordion.accordion id="d" variant={:plain}>
        <:item title="A">a</:item>
        <:item title="B" disabled>b</:item>
      </Accordion.accordion>
      """)

    assert length(Regex.scan(~r/<details/, html)) == 1
    assert length(Regex.scan(~r/<summary/, html)) == 1
    assert html =~ ~r/<div[^>]*aria-disabled="true"/
    refute html =~ "tabindex"
    refute html =~ ">b<"
  end

  test "a heading level wraps the title" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Accordion.accordion id="h" heading_level={3}>
        <:item title="Q">a</:item>
      </Accordion.accordion>
      """)

    assert html =~ ~r/<h3[^>]*>\s*Q\s*<\/h3>/

    plain = rendered_to_string(~H|<Accordion.accordion id="h">
  <:item title="Q">a</:item>
</Accordion.accordion>|)
    refute plain =~ "<h"
  end

  test "global attributes reach the container" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Accordion.accordion id="a" data-x="1">
        <:item title="Q">a</:item>
      </Accordion.accordion>
      """)

    assert html =~ ~s(data-x="1")
  end

  test "the tag of a card is the 10px one" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Accordion.accordion id="t" variant={:card}>
        <:item title="M1" tag="Late" tone={:risk}>Body</:item>
      </Accordion.accordion>
      """)

    assert html =~ "text-[10px]"
    assert html =~ "px-[7px] py-[3px]"
    refute html =~ "text-[11px]"
  end

  test "a plain accordion keeps its chevron at the end unless asked to start with it" do
    assigns = %{}

    default =
      rendered_to_string(~H"""
      <Accordion.accordion id="p" variant={:plain}>
        <:item title="A">a</:item>
      </Accordion.accordion>
      """)

    start =
      rendered_to_string(~H"""
      <Accordion.accordion id="p" variant={:plain} chevron={:start}>
        <:item title="A">a</:item>
      </Accordion.accordion>
      """)

    assert default =~ "accordion-chevron"
    refute start =~ "accordion-chevron"
    assert start =~ ~r/<summary[^>]*>\s*<svg[^>]*group-open:rotate-90/
  end

  test "the panel of a card has the canvas padding" do
    css = File.read!(Path.expand("../../assets/css/devaction_ui.css", __DIR__))

    assert css =~ ~r/\.accordion-card > \.accordion-panel \{[^}]*pb-3\.5 pl-14/
  end
end
