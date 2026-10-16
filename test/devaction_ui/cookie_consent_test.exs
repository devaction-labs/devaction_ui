defmodule DevactionUI.CookieConsentTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.CookieConsent

  defp render_banner(open, fixed \\ true) do
    assigns = %{open: open, fixed: fixed}

    rendered_to_string(~H"""
    <CookieConsent.banner
      id="c"
      title="We use cookies."
      open={@open}
      fixed={@fixed}
      privacy_label="Privacy policy"
      privacy_href="/privacy"
      preferences_label="Preferences"
      preferences_event="prefs"
      necessary_label="Only necessary"
      necessary_event="necessary"
      accept_label="Accept all"
      accept_event="accept"
      category_event="toggle"
    >
      Necessary ones keep you signed in.
      <:category id="need" title="Necessary" description="Always on." locked />
      <:category id="stats" title="Analytics" description="Pages seen." checked={false} />
    </CookieConsent.banner>
    """)
  end

  test "it is a non-modal dialog named by its lead and wired to its hook" do
    html = render_banner(false)

    assert html =~ ~s(role="dialog")
    assert html =~ ~s(aria-modal="false")
    assert html =~ ~s(aria-labelledby="c-title")
    assert html =~ ~s(phx-hook="DevactionUI.CookieConsent")
    assert html =~ ~s(data-fixed="true")
  end

  test "the three actions send their events and the link goes to the policy" do
    html = render_banner(false)

    assert html =~ ~s(phx-click="prefs")
    assert html =~ ~s(phx-click="necessary")
    assert html =~ ~s(phx-click="accept")
    assert html =~ ~s(href="/privacy")
  end

  test "the categories show only when open, and the preferences button says so" do
    closed = render_banner(false)
    open = render_banner(true)

    refute closed =~ "Analytics"
    assert closed =~ ~s(aria-expanded="false")
    assert open =~ "Analytics"
    assert open =~ ~s(aria-expanded="true")
  end

  test "the locked category is on and cannot be pressed; the other sends its id" do
    html = render_banner(true)

    assert length(String.split(html, ~s(aria-checked="true"))) == 2
    assert html =~ ~s(aria-disabled="true")
    assert html =~ ~s(phx-value-id="stats")
    assert length(String.split(html, ~s(phx-click="toggle"))) == 2
  end

  test "it can flow in the page instead of anchoring to the viewport" do
    assert render_banner(false, false) =~ ~s(data-fixed="false")
  end
end
