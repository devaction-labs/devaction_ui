defmodule DevactionUI.DateRangeTest do
  @moduledoc "The range picker: the trigger in a popover, the presets, the months, the footer and the hidden ISO inputs."
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.DateRange

  defp render_range(extra \\ %{}) do
    assigns =
      Map.merge(
        %{value: {"2026-10-01", "2026-10-15"}, aside: false, one_label: nil, min: nil},
        extra
      )

    rendered_to_string(~H"""
    <DateRange.picker
      id="period"
      name="report[period]"
      label="Choose the period"
      value={@value}
      today="2026-10-15"
      min={@min}
      placeholder="Pick dates"
      previous_label="Previous month"
      next_label="Next month"
      presets_label="Ready-made ranges"
      count_label="%{count} days selected"
      one_label={@one_label}
      pending_label="Pick the end date"
      cancel_label="Cancel"
      apply_label="Apply"
    >
      <:icon>CAL</:icon>
      <:prev_icon>PREV</:prev_icon>
      <:next_icon>NEXT</:next_icon>
      <:preset from="2026-10-15" to="2026-10-15">Today</:preset>
      <:preset from="2026-10-01" to="2026-10-15">This month</:preset>
      <:preset>Custom</:preset>
      <:aside :if={@aside}>TIMES</:aside>
    </DateRange.picker>
    """)
  end

  test "the trigger is a button in a popover and shows the placeholder until the hook writes the range" do
    html = render_range()

    assert html =~ ~s(phx-hook="DevactionUI.DateRange")
    assert html =~ ~s(phx-hook="DevactionUI.Popover")
    assert html =~ ~r/<button[^>]*aria-expanded:border-ink/
    assert html =~ ~r/<span[^>]*id="period-label"[^>]*phx-update="ignore"[^>]*>Pick dates/
    assert html =~ "CAL"
    assert html =~ ~s(aria-label="Choose the period")
  end

  test "the range goes in two hidden ISO inputs that the hook owns" do
    html = render_range()

    assert html =~
             ~r/<input[^>]*type="hidden"[^>]*name="report\[period\]_from"[^>]*value="2026-10-01"/

    assert html =~
             ~r/<input[^>]*type="hidden"[^>]*name="report\[period\]_to"[^>]*value="2026-10-15"/

    assert html =~ "data-from-input"
    assert html =~ "data-to-input"
    assert html =~ ~s(data-from="2026-10-01")
    assert html =~ ~s(data-to="2026-10-15")
  end

  test "a value may be dates or nothing or only a start" do
    assert render_range(%{value: {~D[2026-10-02], ~D[2026-10-09]}}) =~ ~s(data-to="2026-10-09")
    refute render_range(%{value: nil}) =~ ~r/<div id="period"[^>]*data-from=/
    html = render_range(%{value: "2026-10-05"})
    assert html =~ ~s(data-from="2026-10-05")
    refute html =~ ~r/<div id="period"[^>]*data-to=/
  end

  test "the server gives the hook today, the minimum and the words" do
    html = render_range(%{min: "2026-10-10", one_label: "1 day selected"})

    assert html =~ ~s(data-today="2026-10-15")
    assert html =~ ~s(data-min="2026-10-10")
    assert html =~ ~s(data-count="%{count} days selected")
    assert html =~ ~s(data-one="1 day selected")
    assert html =~ ~s(data-pending="Pick the end date")
    assert html =~ ~s(data-placeholder="Pick dates")
    assert html =~ ~s(data-previous="Previous month")
    assert html =~ ~s(data-locale="en")
    assert html =~ ~s(data-week-start="0")
  end

  test "the presets are a column of buttons with their ISO dates, the custom one with none" do
    html = render_range()

    assert html =~ ~s(aria-label="Ready-made ranges")

    assert html =~
             ~r/<button[^>]*data-preset[^>]*data-from="2026-10-15"[^>]*data-to="2026-10-15"[^>]*>\s*Today/

    assert html =~ ~r/<button[^>]*data-from="2026-10-01"[^>]*>\s*This month/
    assert html =~ ~r/<button[^>]*data-preset[^>]*aria-pressed="false"[^>]*>\s*Custom/
    assert length(Regex.scan(~r/data-preset/, html)) == 3
    assert html =~ "aria-pressed:bg-wrap"
  end

  test "the months are drawn by the hook into a place LiveView leaves alone, with the arrows from the slots" do
    html = render_range()

    assert html =~ ~r/<div[^>]*id="period-months"[^>]*data-range-months[^>]*phx-update="ignore"/s
    assert html =~ ~r/<template data-previous-icon>PREV<\/template>/
    assert html =~ ~r/<template data-next-icon>NEXT<\/template>/
  end

  test "the footer has the count, Cancel and Apply, and Apply is the one the hook enables" do
    html = render_range()

    assert html =~ ~r/<span[^>]*id="period-count"[^>]*data-range-count[^>]*phx-update="ignore"/s
    assert html =~ ~r/<button[^>]*data-range-cancel[^>]*>\s*Cancel/
    assert html =~ ~r/<button[^>]*data-range-apply[^>]*>\s*Apply/
  end

  test "the column on the right is optional" do
    assert render_range(%{aside: true}) =~ "TIMES"
    refute render_range() =~ "TIMES"
  end

  test "no hex colours: the panel is made of tokens" do
    refute render_range() =~ ~r/#[0-9A-Fa-f]{6}/
  end
end
