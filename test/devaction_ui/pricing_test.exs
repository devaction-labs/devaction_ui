defmodule DevactionUI.PricingTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.Pricing

  defp render_table do
    assigns = %{
      billing: [
        %{value: "monthly", label: "Monthly"},
        %{value: "yearly", label: "Yearly", tag: "2 months free"}
      ]
    }

    rendered_to_string(~H"""
    <Pricing.table
      id="p"
      billing_label="Billing"
      billing={@billing}
      period="yearly"
      billing_event="billing"
      event="choose"
    >
      <:title>Plans</:title>
      <:plan
        id="a"
        name="Solo"
        tagline="One person."
        price="[PRICE]"
        period="/mo"
        note="billed yearly"
        features={["One", "Two"]}
        cta="Start"
      />
      <:plan
        id="b"
        name="Team"
        price="[PRICE]"
        highlighted
        ribbon="Most used"
        cta="Create"
        features={["Everything"]}
      />
      <:plan id="c" name="Custom" custom="Talk to us" cta="Contact" />
      <:footnote>Values are placeholders.</:footnote>
    </Pricing.table>
    """)
  end

  test "the billing toggle is a segmented control with the tag and the chosen period" do
    html = render_table()

    assert html =~ ~s(aria-label="Billing")
    assert html =~ ~s(aria-pressed="true")
    assert html =~ "segment-tag"
    assert html =~ "2 months free"
    assert html =~ ~s(phx-click="billing")
  end

  test "the price, period and note come from the attrs and nothing is invented" do
    html = render_table()

    assert html =~ "[PRICE]"
    assert html =~ "/mo"
    assert html =~ "billed yearly"
    assert html =~ "Talk to us"
  end

  test "a highlighted plan has the ribbon and the highlighted action; the others do not" do
    html = render_table()

    assert length(String.split(html, ~s(class="pricing-ribbon"))) == 2
    assert html =~ ~s(data-highlighted="true")
    assert html =~ ~s(phx-value-plan="b")
  end

  test "the features carry the typographic check when no mark is given" do
    html = render_table()

    assert html =~ "✓"
    assert html =~ "Values are placeholders."
  end

  test "each plan is an article named by its heading" do
    assert render_table() =~ ~s(aria-labelledby="p-plan-a-name")
  end
end
