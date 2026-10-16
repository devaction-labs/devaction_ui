defmodule DevactionUI.TimelineTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  import DevactionUI.Timeline

  test "the time is on its own line, smaller than the title" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.timeline><:item title="Merged" time="4 min ago" /></.timeline>
      """)

    assert html =~
             ~r/text-sm font-medium text-ink[^>]*>\s*Merged\s*<\/span>\s*<span class="text-xs text-muted">4 min ago/
  end

  test "a datetime makes the time a time element" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.timeline><:item title="Merged" time="4 min ago" datetime="2026-10-15T10:00:00Z" /></.timeline>
      """)

    assert html =~ ~s(<time datetime="2026-10-15T10:00:00Z")
  end

  test "without a datetime the time stays a plain span" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.timeline><:item title="Merged" time="4 min ago" /></.timeline>
      """)

    refute html =~ "<time"
  end

  test "the neutral dot is the muted one and the others come from the tone" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.timeline>
        <:item title="Opened" />
        <:item title="Failed" tone={:risk} />
      </.timeline>
      """)

    assert html =~ "bg-muted-2"
    assert html =~ "bg-missing"
  end

  test "the marker column is 20px, the dot 5px down and the items 16px apart" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.timeline><:item title="A" /></.timeline>
      """)

    assert html =~ "w-5"
    assert html =~ "mt-[5px]"
    assert html =~ "pb-4"
  end

  test "a tone_label is read out before the title" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.timeline><:item title="Deploy" tone={:risk} tone_label="Failed:" /></.timeline>
      """)

    assert html =~ ~r/sr-only">Failed: <\/span>Deploy/
  end

  test "the item text and global attributes render" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.timeline id="t">
        <:item title="Merged">The PR went in.</:item>
      </.timeline>
      """)

    assert html =~ "The PR went in."
    assert html =~ ~s(id="t")
  end
end
