defmodule DevactionUI.HoverCardTest do
  @moduledoc "The hover card: its trigger, its card, the delays it hands the hook and what the hook may touch."
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.HoverCard

  defp card(extra \\ %{}) do
    assigns = Map.merge(%{placement: :bottom, open_delay: 400, close_delay: 150}, extra)

    rendered_to_string(~H"""
    <HoverCard.card
      id="hc"
      label="Alex"
      placement={@placement}
      open_delay={@open_delay}
      close_delay={@close_delay}
    >
      <:trigger>Alex</:trigger>
      CARD-BODY
    </HoverCard.card>
    """)
  end

  test "is a hooked wrapper with the trigger and a card that starts closed" do
    html = card()

    assert html =~ ~s(phx-hook="DevactionUI.HoverCard")
    assert html =~ "data-trigger"
    assert html =~ "Alex"
    assert html =~ "CARD-BODY"
    assert html =~ ~s(id="hc-card")
    assert html =~ ~s(data-state="closed")
    assert html =~ "invisible"
  end

  test "the card is a named group, so a screen reader knows what the description is" do
    html = card()

    assert html =~ ~s(role="group")
    assert html =~ ~s(aria-label="Alex")
  end

  test "hands the hook the delays: 400 ms to open and a close delay for the pointer to cross the gap" do
    html = card()

    assert html =~ ~s(data-open-delay="400")
    assert html =~ ~s(data-close-delay="150")
    assert card(%{open_delay: 0, close_delay: 300}) =~ ~s(data-open-delay="0")
    assert card(%{open_delay: 0, close_delay: 300}) =~ ~s(data-close-delay="300")
  end

  test "the card prefers the side it is given, and the hook may change it and the shift" do
    assert card(%{placement: :top}) =~ ~s(data-placement="top")
    assert card() =~ ~s(data-placement="bottom")
    assert card() =~ "data-[side=top]:pb-2"
    assert card() =~ "data-[side=bottom]:pt-2"
  end

  test "the trigger has the dotted underline unless it is turned off" do
    assert card() =~ "decoration-dotted"

    assigns = %{}

    plain =
      rendered_to_string(~H"""
      <HoverCard.card id="hc2" label="x" underline={false}>
        <:trigger>Plain</:trigger>
        body
      </HoverCard.card>
      """)

    refute plain =~ "decoration-dotted"
  end

  test "can sit inside a paragraph: it draws no block element" do
    html = card()

    refute html =~ "<div"
    refute html =~ "<p"
  end

  test "fades without motion when the person asked for less" do
    assert card() =~ "motion-reduce:transition-none"
  end

  test "passes the caller's own attributes to the wrapper" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <HoverCard.card id="hc3" label="x" data-person="alex">
        <:trigger>Alex</:trigger>
        body
      </HoverCard.card>
      """)

    assert html =~ ~s(data-person="alex")
  end
end
