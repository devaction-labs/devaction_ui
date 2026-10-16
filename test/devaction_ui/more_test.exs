defmodule DevactionUI.MoreTest do
  @moduledoc "The markup and the pure parts of autocomplete, date picker, popover and toast group. Their keyboard and pointer behavior is checked in a browser through `/dev/ui`."
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.{Autocomplete, DatePicker, Popover, ToastGroup}

  describe "Autocomplete.highlight/2" do
    test "splits around the match, ignoring case and accents" do
      assert Autocomplete.highlight("Ecto.Multi", "ecto") == [match: "Ecto", text: ".Multi"]

      assert Autocomplete.highlight("Dízimos em transação", "dizimo") == [
               match: "Dízimo",
               text: "s em transação"
             ]

      assert Autocomplete.highlight("Pão Quente", "pao") == [match: "Pão", text: " Quente"]

      assert Autocomplete.highlight("Multi no checkout", "CHECK") == [
               text: "Multi no ",
               match: "check",
               text: "out"
             ]
    end

    test "no match or a blank query is the whole label" do
      assert Autocomplete.highlight("Ecto", "zzz") == [text: "Ecto"]
      assert Autocomplete.highlight("Ecto", "  ") == [text: "Ecto"]
      assert Autocomplete.highlight("Ecto", "") == [text: "Ecto"]
    end

    test "a match that is the whole label has no empty pieces" do
      assert Autocomplete.highlight("Ecto", "Ecto") == [match: "Ecto"]
    end
  end

  describe "Autocomplete markup" do
    @groups [
      %{
        label: "Lessons",
        items: [%{id: "1", label: "Ecto.Multi", to: "/learning/1", hint: "30", tone: :warn}]
      }
    ]

    defp ac(assigns) do
      ~H"""
      <Autocomplete.autocomplete
        id="ac"
        label="Search"
        event="search"
        value={@value}
        groups={@groups}
        empty="Nothing"
        ask_label={@ask}
        ask_event="ask"
      />
      """
    end

    test "shows the groups, the links and the bold match once there is a query" do
      assigns = %{value: "ecto", groups: @groups, ask: nil}
      html = rendered_to_string(~H|<.ac value={@value} groups={@groups} ask={@ask} />|)

      assert html =~ "Lessons"
      assert html =~ ~s(href="/learning/1")
      assert html =~ ~s(role="listbox")
      assert html =~ ~r/<strong class="font-semibold">Ecto<\/strong>\.Multi/
      refute html =~ "data-ask"
    end

    test "draws no list for an empty query, and says so for a query with no result" do
      assigns = %{value: "", groups: [], ask: nil}

      refute rendered_to_string(~H|<.ac value={@value} groups={@groups} ask={@ask} />|) =~
               "listbox"

      assigns = %{value: "zzz", groups: [], ask: nil}

      assert rendered_to_string(~H|<.ac value={@value} groups={@groups} ask={@ask} />|) =~
               "Nothing"
    end

    test "the AI row is there only when asked for, and sends the query" do
      assigns = %{value: "ecto", groups: @groups, ask: "Ask the AI"}
      html = rendered_to_string(~H|<.ac value={@value} groups={@groups} ask={@ask} />|)
      assert html =~ "data-ask"
      assert html =~ ~s(phx-click="ask")
      assert html =~ ~s(phx-value-q="ecto")
      assert html =~ "Ask the AI"
    end

    test "escapes what it highlights" do
      assigns = %{
        value: "a",
        groups: [%{label: "G", items: [%{id: "x", label: "<b>a</b>", to: "/x"}]}],
        ask: nil
      }

      html = rendered_to_string(~H|<.ac value={@value} groups={@groups} ask={@ask} />|)
      refute html =~ "<b>a</b>"
      assert html =~ "&lt;b&gt;"
    end
  end

  describe "DatePicker" do
    defp picker(assigns) do
      ~H"""
      <DatePicker.date_picker
        id="d"
        name="due"
        mode={@mode}
        value={@value}
        today="2026-10-14"
        min={@min}
        previous_label="Prev"
        next_label="Next"
      >
        <:shortcut date="2026-10-16">Friday</:shortcut>
      </DatePicker.date_picker>
      """
    end

    test "one day: a single hidden input with the ISO date, and what the hook needs" do
      assigns = %{mode: :single, value: "2026-10-16", min: nil}
      html = rendered_to_string(~H|<.picker mode={@mode} value={@value} min={@min} />|)

      assert html =~ ~s(name="due")
      assert html =~ ~s(value="2026-10-16")
      assert html =~ ~s(data-today="2026-10-14")
      assert html =~ ~s(data-previous="Prev")
      assert html =~ ~s(data-shortcut="2026-10-16")
      assert html =~ "Friday"
      refute html =~ "due_to"
    end

    test "a range has a from and a to input and honours a minimum" do
      assigns = %{mode: :range, value: {"2026-10-15", "2026-10-20"}, min: "2026-10-10"}
      html = rendered_to_string(~H|<.picker mode={@mode} value={@value} min={@min} />|)

      assert html =~ ~s(name="due_from")
      assert html =~ ~s(name="due_to")
      assert html =~ ~s(data-to="2026-10-20")
      assert html =~ ~s(data-min="2026-10-10")
    end

    test "the arrows come from the icon slots, and the title, range hint and shadow are options" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DatePicker.date_picker
          id="d"
          name="due"
          today="2026-10-14"
          previous_label="Prev"
          next_label="Next"
          capitalize={false}
          inside_label="in the range"
          shadow
        >
          <:prev_icon>L</:prev_icon>
          <:next_icon>R</:next_icon>
        </DatePicker.date_picker>
        """)

      assert html =~ ~r/<template data-previous-icon>\s*L\s*<\/template>/
      assert html =~ ~r/<template data-next-icon>\s*R\s*<\/template>/
      assert html =~ ~s(data-capitalize="false")
      assert html =~ ~s(data-inside="in the range")
      assert html =~ "shadow-pop"
    end

    test "by default it capitalises, has no shadow and says nothing about the range" do
      assigns = %{mode: :single, value: nil, min: nil}
      html = rendered_to_string(~H|<.picker mode={@mode} value={@value} min={@min} />|)

      assert html =~ ~s(data-capitalize="true")
      refute html =~ "data-inside"
      refute html =~ "shadow-pop"
    end

    test "no value is empty inputs" do
      assigns = %{mode: :single, value: nil, min: nil}
      html = rendered_to_string(~H|<.picker mode={@mode} value={@value} min={@min} />|)
      assert html =~ ~s(name="due")
      refute html =~ ~s(data-from="20)
    end
  end

  describe "DatePicker.due_chip/1" do
    test "late, today and later are told apart" do
      today = ~D[2026-10-14]
      assert DatePicker.state(~D[2026-10-12], today) == :late
      assert DatePicker.state(today, today) == :today
      assert DatePicker.state(~D[2026-10-20], today) == :later
    end

    test "draws the text in the state's colors" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<DatePicker.due_chip date={~D[2026-10-12]} today={~D[2026-10-14]} text="2 days late" />|
        )

      assert html =~ ~s(data-state="late")
      assert html =~ "bg-tag-risk-bg"
      assert html =~ "2 days late"
      assert html =~ "px-2.5"
    end
  end

  test "Popover is a dialog tied to its trigger, closed at first" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Popover.popover id="p" label="Details" placement={:top} align={:end}>
        <:trigger><a href="#">Open</a></:trigger>
        Body
      </Popover.popover>
      """)

    assert html =~ ~s(role="dialog")
    assert html =~ ~s(aria-label="Details")
    assert html =~ ~s(id="p-panel")
    refute html =~ "aria-expanded"
    assert html =~ ~s(data-placement="top")
    assert html =~ "right-0"
    assert html =~ ~r/data-panel[^>]*hidden/s
    assert html =~ "Body"
  end

  describe "ToastGroup" do
    defp group(assigns) do
      ~H"""
      <ToastGroup.toast_group
        id="tg"
        label="Notices"
        on_dismiss="dismiss"
        on_clear="clear"
        expand_label="Show all"
        collapse_label="Collapse"
        clear_label="Clear"
        dismiss_label="Close"
        count_label="__COUNT__ notices"
      >
        <:toast id="a" kind={:risk} title="Failed" duration={0}>It broke</:toast>
        <:toast id="b" title="Done" action_label="Undo" action_event="undo" />
      </ToastGroup.toast_group>
      """
    end

    test "each toast has its role, its timer and its close button; the group its texts" do
      assigns = %{}
      html = rendered_to_string(~H|<.group />|)

      assert html =~ ~s(role="region")
      assert html =~ ~s(aria-label="Notices")
      assert html =~ ~s(data-on-dismiss="dismiss")
      assert html =~ ~s(data-count-label="__COUNT__ notices")
      assert html =~ ~r/id="a"[^>]*role="alert"|role="alert"[^>]*id="a"/s
      assert html =~ ~r/id="b"[^>]*role="status"|role="status"[^>]*id="b"/s
      assert html =~ ~s(data-duration="0")
      assert html =~ ~s(data-duration="5000")
      assert length(Regex.scan(~r/data-dismiss/, html)) == 2
      assert html =~ ~s(aria-label="Close")
      assert html =~ "Show all" and html =~ "Collapse" and html =~ "Clear"
      assert html =~ "It broke"
    end

    test "a toast with an action shows a button that sends its own id" do
      assigns = %{}
      html = rendered_to_string(~H|<.group />|)
      assert html =~ ~s(phx-click="undo")
      assert html =~ ~s(phx-value-id="b")
      assert html =~ "Undo"
    end

    test "the kinds are the inverted, the light and the risk look" do
      assigns = %{}
      html = rendered_to_string(~H|<.group />|)
      assert html =~ "bg-ink text-on-primary"
      assert html =~ "bg-tag-risk-bg"
    end
  end
end
