defmodule DevactionUI.BannerTest do
  @moduledoc "The banner: four tones, the role by tone, the action and the dismiss button."
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.Banner

  test "each tone has its surface and the critical one is an alert" do
    for {tone, role, klass} <- [
          {:info, "status", "bg-tag-info-bg"},
          {:warning, "status", "bg-tag-warn-bg"},
          {:critical, "alert", "bg-tag-risk-bg"},
          {:offline, "status", "bg-ink"}
        ] do
      assigns = %{tone: tone}
      html = rendered_to_string(~H|<Banner.banner tone={@tone}>text</Banner.banner>|)

      assert html =~ ~s(role="#{role}")
      assert html =~ klass
      assert html =~ ~s(data-tone="#{tone}")
    end
  end

  test "a lead, a text, an icon and an action" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Banner.banner title="Heads up." tone={:warning}>
        Reviews may be late.
        <:icon><svg data-icon /></:icon>
        <:action><a href="/status">Status</a></:action>
      </Banner.banner>
      """)

    assert html =~ ~r/<b class="font-semibold">Heads up.<\/b>/
    assert html =~ "Reviews may be late."
    assert html =~ "data-icon"
    assert html =~ ~s(<a href="/status">Status</a>)
    assert html =~ "underline"
    refute html =~ "<button"
  end

  test "a dismiss event makes a named button that sends it" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Banner.banner on_dismiss="dismiss" dismiss_label="Dismiss" target="#page">
        text
        <:dismiss_icon><svg data-icon="x" /></:dismiss_icon>
      </Banner.banner>
      """)

    assert html =~ ~s(aria-label="Dismiss")
    assert html =~ ~s(phx-click="dismiss")
    assert html =~ ~s(phx-target="#page")
    assert html =~ ~s(data-icon="x")
  end

  test "a dismiss event without a name is a mistake" do
    assigns = %{}

    assert_raise ArgumentError, ~r/dismiss_label/, fn ->
      rendered_to_string(~H|<Banner.banner on_dismiss="dismiss">text</Banner.banner>|)
    end
  end
end
