defmodule DevactionUI.StatTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  import DevactionUI.Stat

  test "the label and the value are a dt and dd pair" do
    assigns = %{}
    html = rendered_to_string(~H|<.stat label="Ready">78</.stat>|)

    assert html =~ ~r/<dl[^>]*>\s*<dt[^>]*>\s*Ready\s*<\/dt>\s*<dd[^>]*>\s*78/
  end

  test "the value is 44px with the canvas tracking, in a bordered card by default" do
    assigns = %{}
    html = rendered_to_string(~H|<.stat label="Ready">78</.stat>|)

    assert html =~ "text-[44px]"
    assert html =~ "leading-none"
    assert html =~ "tracking-[-0.04em]"
    assert html =~ "gap-2"
    assert html =~ "border border-line"
  end

  test "bordered can be turned off" do
    assigns = %{}
    html = rendered_to_string(~H|<.stat label="Ready" bordered={false}>78</.stat>|)

    refute html =~ "border-line"
  end

  test "the unit sits in the value, muted at 24px" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.stat label="Ready">
        78,4<:unit>%</:unit>
      </.stat>
      """)

    assert html =~ ~r/78,4<span class="text-2xl text-muted">%<\/span>/
  end

  test "the trend and the hint share a line below the value" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.stat label="Ready">
        78
        <:trend><b>+6</b></:trend>
        <:hint>since Monday</:hint>
      </.stat>
      """)

    assert html =~ ~r/<\/dd>\s*<dd[^>]*text-\[13px\][^>]*>\s*<b>\+6<\/b>/
    assert html =~ "since Monday"
  end

  test "no support line without a trend or a hint" do
    assigns = %{}
    html = rendered_to_string(~H|<.stat label="Ready">78</.stat>|)

    assert length(String.split(html, "<dd")) == 2
  end

  test "the tone colours the value through the tone tokens" do
    assigns = %{}

    for {tone, class} <- [
          risk: "text-tag-risk-text",
          warn: "text-tag-warn-text",
          ok: "text-tag-ok-text"
        ] do
      assigns = Map.put(assigns, :tone, tone)
      assert rendered_to_string(~H|<.stat label="L" tone={@tone}>1</.stat>|) =~ class
    end
  end

  test "highlight is ink without a border, and its hint is dimmed" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.stat label="Ready" highlight>
        78<:hint>x</:hint>
      </.stat>
      """)

    assert html =~ "bg-ink"
    refute html =~ "border-line"
    assert html =~ "opacity-70"
  end

  test "global attributes arrive" do
    assigns = %{}
    assert rendered_to_string(~H|<.stat label="L" id="s">1</.stat>|) =~ ~s(id="s")
  end
end
