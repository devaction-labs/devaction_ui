defmodule DevactionUI.Components2Test do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  import DevactionUI.{Alert, Badge, Breadcrumb, Pagination, Stat, Steps, Timeline}

  alias DevactionUI.Button

  describe "Button" do
    test "is a real button with type button, and a link when given a destination" do
      assigns = %{}
      html = rendered_to_string(~H|<Button.button id="b">Go</Button.button>|)
      assert html =~ "<button"
      assert html =~ ~s(type="button")

      html = rendered_to_string(~H|<Button.button navigate="/x">Go</Button.button>|)
      assert html =~ ~s(href="/x")
      refute html =~ "<button"
    end

    test "a submit button keeps its type" do
      assigns = %{}

      assert rendered_to_string(~H|<Button.button type="submit">Save</Button.button>|) =~
               ~s(type="submit")
    end

    test "each variant takes its colors from the tone tokens" do
      assigns = %{}

      for {variant, token} <- [
            ai: "tag-warn",
            danger: "tag-risk",
            info: "tag-info",
            primary: "bg-ink"
          ] do
        html = rendered_to_string(~H|<Button.button variant={variant}>x</Button.button>|)
        assert html =~ token
      end
    end

    test "sizes are 38, 46 and 54px, and an icon button is square" do
      assigns = %{}
      assert rendered_to_string(~H|<Button.button size={:sm}>x</Button.button>|) =~ "h-[38px]"
      assert rendered_to_string(~H|<Button.button size={:md}>x</Button.button>|) =~ "h-[46px]"
      assert rendered_to_string(~H|<Button.button size={:lg}>x</Button.button>|) =~ "h-[54px]"

      assert rendered_to_string(~H|<Button.button icon_only aria-label="x">+</Button.button>|) =~
               "size-11"
    end

    test "round makes it a pill, or a circle for an icon" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<Button.button shape={:round} icon_only aria-label="x">+</Button.button>|
        )

      assert html =~ "rounded-full"
      assert html =~ "size-11"
    end

    test "the padding and the weight follow the variant" do
      assigns = %{}
      primary = rendered_to_string(~H|<Button.button variant={:primary}>x</Button.button>|)
      secondary = rendered_to_string(~H|<Button.button>x</Button.button>|)
      assert primary =~ "px-[18px]"
      assert primary =~ "font-medium"
      assert secondary =~ "px-4"
      assert secondary =~ "font-normal"
    end

    test "the link variant is 46px tall, without underline, and keeps no height of its own" do
      assigns = %{}
      html = rendered_to_string(~H|<Button.button variant={:link}>More</Button.button>|)
      assert html =~ "h-[46px]"
      assert html =~ "px-1.5"
      refute html =~ "h-auto"
      refute html =~ "underline-offset"
      assert html =~ "no-underline"
    end

    test "loading disables it, marks it busy and shows a spinner that stops for reduced motion" do
      assigns = %{}
      html = rendered_to_string(~H|<Button.button loading>Saving</Button.button>|)
      assert html =~ ~s(aria-busy="true")
      assert html =~ "disabled"
      assert html =~ "motion-reduce:animate-none"
      assert html =~ "border-t-current"
      assert html =~ "gap-2.5"
    end

    test "a loading link says it is busy" do
      assigns = %{}
      html = rendered_to_string(~H|<Button.button navigate="/x" loading>Go</Button.button>|)
      assert html =~ ~s(aria-busy="true")
    end

    test "a disabled link is marked, not clickable" do
      assigns = %{}
      html = rendered_to_string(~H|<Button.button navigate="/x" disabled>Go</Button.button>|)
      assert html =~ ~s(aria-disabled="true")
      assert html =~ ~s(tabindex="-1")
    end

    test "an enabled link stays in the tab order" do
      assigns = %{}
      html = rendered_to_string(~H|<Button.button navigate="/x">Go</Button.button>|)
      refute html =~ "tabindex"
      refute html =~ "aria-disabled"
    end
  end

  describe "alert/1" do
    test "a risk alert is announced as an alert and the rest as a status" do
      assigns = %{}
      assert rendered_to_string(~H|<.alert kind={:risk} title="Failed" />|) =~ ~s(role="alert")
      assert rendered_to_string(~H|<.alert kind={:ok} title="Done" />|) =~ ~s(role="status")
    end

    test "has the title, the body and the tone" do
      assigns = %{}

      html =
        rendered_to_string(~H|<.alert kind={:ai} title="The AI did it">
  <:icon><i class="spark" /></:icon>Details
</.alert>|)

      assert html =~ "The AI did it"
      assert html =~ "Details"
      assert html =~ "spark"
      assert html =~ "border-tag-warn-line"
    end
  end

  describe "breadcrumb/1" do
    test "links the way and marks the current page" do
      assigns = %{
        items: [
          %{label: "Today", to: "/today"},
          %{label: "SGE", to: "/projects/1"},
          %{label: "PR #142"}
        ]
      }

      html = rendered_to_string(~H|<.breadcrumb label="You are here" items={@items} />|)
      assert html =~ ~s(aria-label="You are here")
      assert html =~ ~s(href="/today")
      assert html =~ ~s(aria-current="page")
      assert html =~ "PR #142"
      assert length(Regex.scan(~r/<a /, html)) == 2
    end
  end

  describe "pagination/1" do
    test "entries skip with a gap and always keep the first, the last and the neighbors" do
      assert DevactionUI.Pagination.entries(1, 3) == [1, 2, 3]
      assert DevactionUI.Pagination.entries(5, 10) == [1, :gap, 4, 5, 6, :gap, 10]
      assert DevactionUI.Pagination.entries(2, 10) == [1, 2, 3, :gap, 10]
      assert DevactionUI.Pagination.entries(10, 10) == [1, :gap, 9, 10]
    end

    test "marks the current page and offers previous and next only where they exist" do
      assigns = %{path: &"/p?page=#{&1}"}

      html =
        rendered_to_string(
          ~H|<.pagination page={1} pages={4} path={@path} label="Pages" previous="Previous" next="Next" />|
        )

      assert html =~ ~s(aria-current="page")
      assert html =~ ~s(aria-label="Next")
      refute html =~ ~s(aria-label="Previous")
      assert html =~ "/p?page=2"
    end

    test "draws nothing for a single page" do
      assigns = %{path: & &1}

      html =
        rendered_to_string(
          ~H|<.pagination page={1} pages={1} path={@path} label="P" previous="a" next="b" />|
        )

      refute html =~ "<nav"
    end
  end

  describe "stat/1" do
    test "shows the caption, the value and the trend" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.stat label="Approved" tone={:risk} id="s">
          7
          <:trend><span>+6</span></:trend>
        </.stat>
        """)

      assert html =~ "Approved"
      assert html =~ "text-missing"
      assert html =~ "+6"
      assert html =~ ~s(id="s")
    end

    test "the highlighted one is inverted" do
      assigns = %{}
      html = rendered_to_string(~H|<.stat label="Ready" highlight>78</.stat>|)
      assert html =~ "bg-ink"
      refute html =~ "text-ink"
    end
  end

  describe "badge" do
    test "count caps at the maximum" do
      assigns = %{}
      assert rendered_to_string(~H|<.count value={4} />|) =~ ~r/>\s*4\s*</
      assert rendered_to_string(~H|<.count value={120} />|) =~ "99+"
    end

    test "a dot without a label is decoration and with one is an image" do
      assigns = %{}
      assert rendered_to_string(~H|<.dot />|) =~ ~s(aria-hidden="true")
      html = rendered_to_string(~H|<.dot tone={:warn} pulse label="Running" />|)
      assert html =~ ~s(role="img")
      assert html =~ ~s(aria-label="Running")
      assert html =~ "motion-reduce:animate-none"
    end
  end

  test "steps/1 marks done, current and pending" do
    assigns = %{}
    html = rendered_to_string(~H|<.steps labels={["Install", "Pick", "Tie"]} current={2} />|)
    assert html =~ ~s(aria-current="step")
    assert html =~ "✓"
    assert html =~ "Install" and html =~ "Tie"
  end

  test "timeline/1 lists its items with their time and text" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.timeline>
        <:item tone={:ok} title="Merged" time="4 min ago">The PR went in.</:item>
        <:item title="Opened" />
      </.timeline>
      """)

    assert html =~ "Merged"
    assert html =~ "4 min ago"
    assert html =~ "The PR went in."
    assert html =~ "Opened"
  end

  describe "Button states" do
    test "loading keeps the fill of its variant and shows the spinner" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<DevactionUI.Button.button variant={:primary} loading>Publishing</DevactionUI.Button.button>|
        )

      assert html =~ "bg-ink"
      assert html =~ "cursor-progress"
      assert html =~ "animate-spin"
      assert html =~ ~s(aria-busy="true")
      refute html =~ "opacity-50"
    end

    test "disabled is a flat grey block, not the variant faded" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<DevactionUI.Button.button variant={:primary} disabled>Publish</DevactionUI.Button.button>|
        )

      assert html =~ "bg-line"
      assert html =~ "text-muted"
      assert html =~ "cursor-not-allowed"
      refute html =~ "bg-ink"
    end
  end
end
