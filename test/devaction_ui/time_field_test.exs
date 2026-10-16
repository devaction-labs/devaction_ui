defmodule DevactionUI.TimeFieldTest do
  @moduledoc "The start and end fields with their suggestions, the duration row and the note."
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.TimeField

  defp render_field(extra \\ %{}) do
    assigns = Map.merge(%{note: nil, step: 15, disabled: false, icon: false}, extra)

    rendered_to_string(~H"""
    <TimeField.input
      id="tf"
      start_name="entry[start]"
      end_name="entry[end]"
      start_value="09:00"
      end_value="11:15"
      start_label="Start"
      end_label="End"
      list_label="Times"
      duration_label="Duration"
      hours_label="%{count} h"
      minutes_label="%{count} min"
      step={@step}
      note={@note}
      disabled={@disabled}
    >
      <:icon :if={@icon}>CLOCK</:icon>
    </TimeField.input>
    """)
  end

  test "two named fields hold the times as text and are tied to the list" do
    html = render_field()

    assert html =~ ~s(phx-hook="DevactionUI.TimeField")
    assert html =~ ~r/<input[^>]*name="entry\[start\]"[^>]*value="09:00"/
    assert html =~ ~r/<input[^>]*name="entry\[end\]"[^>]*value="11:15"/
    assert html =~ ~s(data-time="start")
    assert html =~ ~s(data-time="end")
    assert html =~ ~s(inputmode="numeric")
    assert html =~ ~s(role="combobox")
    assert html =~ ~s(aria-controls="tf-list")
    assert html =~ "font-mono"
  end

  test "the labels are the caller's words" do
    html = render_field()

    assert html =~ ~r/<label[^>]*>\s*Start/
    assert html =~ ~r/<label[^>]*>\s*End/
    assert html =~ ~s(aria-label="Times")
    assert html =~ "Duration"
  end

  test "the list and the length are drawn by the hook and left alone by LiveView" do
    html = render_field()

    assert html =~ ~r/<div[^>]*id="tf-list"[^>]*role="listbox"[^>]*phx-update="ignore"/s
    assert html =~ ~r/<span[^>]*id="tf-length"[^>]*phx-update="ignore"/s
  end

  test "the patterns of hours and minutes and the step go to the hook" do
    html = render_field(%{step: 30})

    assert html =~ ~s(data-hours="%{count} h")
    assert html =~ ~s(data-minutes="%{count} min")
    assert html =~ ~s(data-step="30")
  end

  test "the clock icon is the caller's slot in both fields" do
    html = render_field(%{icon: true})

    assert length(Regex.scan(~r/CLOCK/, html)) == 2
    refute render_field() =~ "CLOCK"
  end

  test "the note is shown when there is one" do
    assert render_field(%{note: "Zone: America/Bahia"}) =~ "Zone: America/Bahia"
    refute render_field() =~ "<p"
  end

  test "a disabled field takes no input" do
    html = render_field(%{disabled: true})

    assert length(Regex.scan(~r/<input[^>]*disabled/, html)) == 2
  end
end
