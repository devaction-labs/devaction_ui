defmodule DevactionUI.TabsTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.Tabs

  defp render_tabs(variant, tone \\ nil) do
    assigns = %{variant: variant, tone: tone}

    rendered_to_string(~H"""
    <Tabs.tabs id="t" label="PRs" variant={@variant}>
      <:tab id="a" label="A" count="4" count_tone={@tone}>first</:tab>
      <:tab id="b" label="B" selected>second</:tab>
    </Tabs.tabs>
    """)
  end

  test "the count takes its colour from the tone, muted when it has none" do
    assert render_tabs(:boxed, :risk) =~ ~r/font-mono text-xs text-tag-risk-text">\s*4/
    assert render_tabs(:boxed) =~ ~r/font-mono text-xs text-muted">\s*4/
  end

  test "the line variant is muted until selected and the boxed one is ink-2" do
    line = render_tabs(:line)
    boxed = render_tabs(:boxed)

    assert line =~ "text-muted aria-selected:border-ink"
    refute line =~ "text-ink-2"
    assert boxed =~ "text-ink-2"
  end

  test "the server's selection is rendered for the hook to compare" do
    assert render_tabs(:boxed) =~ ~s(data-server-selected="b")
  end

  test "only what the person picked is left alone by LiveView patches" do
    html = render_tabs(:boxed)

    assert html =~ "data-selected"
    refute html =~ "aria-selected&quot;"
    refute html =~ ~r/phx-mounted="[^"]*aria-selected/
    refute html =~ ~r/phx-mounted="[^"]*tabindex/
    refute html =~ ~r/phx-mounted="[^"]*hidden/
  end

  defp render_vertical(variant) do
    assigns = %{variant: variant}

    rendered_to_string(~H"""
    <Tabs.tabs id="t" label="Settings" variant={@variant} orientation={:vertical}>
      <:tab id="a" label="A">first</:tab>
      <:tab id="b" label="B">second</:tab>
    </Tabs.tabs>
    """)
  end

  test "horizontal is the default and says so to assistive technology" do
    html = render_tabs(:boxed)

    assert html =~ ~s(aria-orientation="horizontal")
    refute html =~ "flex-col"
  end

  test "a vertical boxed list is a column beside the panels" do
    html = render_vertical(:boxed)

    assert html =~ ~s(aria-orientation="vertical")
    assert html =~ "flex items-start gap-6"
    assert html =~ "flex-col"
    assert html =~ "min-w-0 flex-1"
    assert html =~ "justify-start"
    refute html =~ "pt-4"
  end

  test "a vertical line list underlines with a rule at the start of the row" do
    html = render_vertical(:line)

    assert html =~ "border-s border-line"
    assert html =~ "border-s-2 border-transparent"
    refute html =~ "border-b-2"
  end

  test "a vertical list keeps the roles and the roving tabindex" do
    html = render_vertical(:boxed)

    assert html =~ ~s(role="tablist")
    assert length(Regex.scan(~r/role="tab"/, html)) == 2
    assert html =~ ~s(tabindex="-1")
    assert html =~ ~s(aria-selected="true")
  end
end
