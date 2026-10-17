defmodule DevactionUI.DateFieldsTest do
  @moduledoc "The date fields: the masked text, the hidden ISO inputs, the popover with the calendar, and the due chip."
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.DatePicker

  defp input(extra \\ %{}) do
    assigns =
      Map.merge(
        %{
          value: "2026-10-16",
          order: :dmy,
          separator: "/",
          error: nil,
          description: nil,
          relative: nil,
          disabled: false,
          min: nil
        },
        extra
      )

    rendered_to_string(~H"""
    <DatePicker.date_input
      id="due"
      name="task[due]"
      label="Due"
      value={@value}
      today="2026-10-14"
      min={@min}
      order={@order}
      separator={@separator}
      placeholder="dd/mm/yyyy"
      error={@error}
      description={@description}
      relative={@relative}
      disabled={@disabled}
      calendar_label="Choose a date"
      previous_label="Previous month"
      next_label="Next month"
    >
      <:icon>CAL</:icon>
      <:shortcut date="2026-10-16">Friday</:shortcut>
    </DatePicker.date_input>
    """)
  end

  defp range(extra \\ %{}) do
    assigns = Map.merge(%{value: {"2026-10-13", "2026-10-20"}, error: nil}, extra)

    rendered_to_string(~H"""
    <DatePicker.date_range
      id="period"
      name="milestone"
      label="Period"
      value={@value}
      today="2026-10-14"
      from_label="Start"
      to_label="End"
      inside_label="in the range"
      error={@error}
      calendar_label="Choose the period"
      previous_label="Previous month"
      next_label="Next month"
    />
    """)
  end

  describe "date_input/1" do
    test "has a label, a text field with the date in the order of the format, and a hidden ISO input" do
      html = input()

      assert html =~ ~s(<label for="due-text")
      assert html =~ "Due"
      assert html =~ ~s(value="16/10/2026")
      assert html =~ ~s(placeholder="dd/mm/yyyy")
      assert html =~ ~s(inputmode="numeric")

      assert html =~
               ~s(<input type="hidden" name="task[due]" value="2026-10-16" data-date-value="from")

      refute html =~ ~r/id="due-text"[^>]*name=/s
      assert html =~ ~s(phx-hook="DevactionUI.DateInput")
      assert html =~ ~s(data-order="dmy")
      assert html =~ ~s(data-separator="/")
    end

    test "other orders and separators, and no value" do
      assert input(%{order: :mdy}) =~ ~s(value="10/16/2026")
      assert input(%{order: :ymd, separator: "-"}) =~ ~s(value="2026-10-16")
      assert input(%{value: nil}) =~ ~s(name="task[due]" data-date-value="from")
      assert input(%{value: ""}) =~ ~s(name="task[due]" data-date-value="from")
      refute input(%{value: ""}) =~ ~s(value="2026)
      assert input(%{value: ~D[2026-10-16]}) =~ ~s(value="16/10/2026")
    end

    test "the calendar is a popover whose picker has no name and is told apart for the hook" do
      html = input()

      assert html =~ ~s(phx-hook="DevactionUI.Popover")
      assert html =~ ~s(aria-label="Choose a date")
      assert html =~ "CAL"
      assert html =~ ~s(phx-hook="DevactionUI.DatePicker")
      assert html =~ ~s(data-date-picker)
      assert html =~ ~s(data-from="2026-10-16")
      assert html =~ ~s(data-shortcut="2026-10-16")
      refute html =~ ~r/data-from-input[^>]*name=|name=[^>]*data-from-input/
      assert html =~ "shadow-pop"
    end

    test "the error marks the field invalid and is tied to it, with the description" do
      html = input(%{error: "Pick a later date", description: "Deadline of the task"})

      assert html =~ ~s(aria-invalid="true")
      assert html =~ ~s(aria-describedby="due-description due-error")
      assert html =~ ~s(<p id="due-error")
      assert html =~ "Pick a later date"
      assert html =~ ~s(<p id="due-description")
    end

    test "without an error or a description there is nothing to point at" do
      html = input()

      refute html =~ "aria-describedby"
      refute html =~ "aria-invalid"
      refute html =~ "due-error"
    end

    test "the relative text sits on the right and a disabled field disables the button" do
      html = input(%{relative: "in 2 days", disabled: true, min: "2026-10-10"})

      assert html =~ "in 2 days"
      assert html =~ ~r/<button[^>]*disabled[^>]*aria-label="Choose a date"/s
      assert html =~ ~s(data-min="2026-10-10")
    end

    test "the date text of a field" do
      assert DatePicker.format_date("2026-01-05", :dmy, "/") == "05/01/2026"
      assert DatePicker.format_date(~D[2026-01-05], :ymd, ".") == "2026.01.05"
      assert DatePicker.format_date(nil, :dmy, "/") == ""
    end
  end

  describe "date_range/1" do
    test "is a group of two linked text fields with an arrow between and two hidden ISO inputs" do
      html = range()

      assert html =~ ~s(role="group")
      assert html =~ ~s(data-mode="range")
      assert html =~ ~s(value="13/10/2026")
      assert html =~ ~s(value="20/10/2026")
      assert html =~ ~s(aria-label="Start")
      assert html =~ ~s(aria-label="End")
      assert html =~ ~s(data-date-text="from")
      assert html =~ ~s(data-date-text="to")
      assert html =~ "→"
      assert html =~ ~s(name="milestone_from" value="2026-10-13")
      assert html =~ ~s(name="milestone_to" value="2026-10-20")
    end

    test "one calendar in range mode serves both fields" do
      html = range()

      assert length(Regex.scan(~r/phx-hook="DevactionUI.DatePicker"/, html)) == 1
      assert html =~ ~s(data-mode="range")
      assert html =~ ~s(data-from="2026-10-13")
      assert html =~ ~s(data-to="2026-10-20")
      assert html =~ ~s(data-inside="in the range")
      refute html =~ ~r/data-from-input[^>]*name=|name=[^>]*data-from-input/
    end

    test "an empty range has empty inputs, and the error marks both fields" do
      html = range(%{value: nil, error: "End before start"})

      assert html =~ ~s(name="milestone_from" data-date-value="from")
      assert length(Regex.scan(~r/aria-invalid="true"/, html)) == 2
      assert html =~ "End before start"
    end
  end

  describe "date_picker/1 with no name" do
    test "its hidden inputs are not sent" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DatePicker.date_picker
          id="d"
          mode={:range}
          today="2026-10-14"
          previous_label="Prev"
          next_label="Next"
        />
        """)

      assert html =~ "data-from-input"
      assert html =~ "data-to-input"
      refute html =~ "name="
    end
  end

  describe "due_chip/1" do
    test "a recurring chip is grey, with an icon of its own or the arrow, and needs no date" do
      assigns = %{}

      html = rendered_to_string(~H|<DatePicker.due_chip recurring text="every Friday" />|)

      assert html =~ ~s(data-state="recurring")
      assert html =~ "bg-wrap text-ink-2"
      assert html =~ "↻"
      assert html =~ "every Friday"

      custom =
        rendered_to_string(~H"""
        <DatePicker.due_chip recurring text="every Friday">
          <:icon>LOOP</:icon>
        </DatePicker.due_chip>
        """)

      assert custom =~ "LOOP"
      refute custom =~ "↻"
    end

    test "a dated chip has no icon" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<DatePicker.due_chip date={~D[2026-10-12]} today={~D[2026-10-14]} text="late" />|
        )

      refute html =~ "↻"
      assert html =~ ~s(data-state="late")
    end
  end
end
