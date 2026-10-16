defmodule DevactionUISite.EmailTemplateTest do
  use ExUnit.Case, async: true

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias DevactionUISite.{Catalog, Changelog, Repo, ScreenHTML, Templates}

  @endpoint DevactionUISite.Endpoint

  @slugs ~w(magic_link confirm_account update_email reset_password password_changed new_device
            review_ready contract_expiring amendment_signature weekly_digest workspace_invite)

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Changelog.sync!()
  end

  test "the e-mail components are in the Email category, new in 0.4" do
    assert {"Email", entries} = List.keyfind(Catalog.groups(), "Email", 0)
    assert Enum.map(entries, & &1.slug) == ~w(email email_callout email_table email_tag)

    for entry <- entries do
      assert Catalog.since(entry) == "0.4"
      assert Catalog.release(entry) == "v0.4.0"
    end
  end

  test "the next version lists the components and the template group as new" do
    next = Enum.find(Changelog.versions(), &(&1.version == "v0.4.0"))
    new = for %{kind: "new", group: "Email", name: name} <- next.entries, do: name

    assert Enum.sort(new) == ~w(email email_callout email_table email_tag)
    assert Enum.any?(next.entries, &(&1.group == "Templates" and &1.name == "email"))
  end

  test "the Email group has the eleven e-mails, each with its source" do
    {:ok, group} = Templates.fetch("email")

    assert Enum.map(group.screens, & &1.slug) == @slugs
    assert Templates.width(group) == 720
    assert Templates.width(%{}) == 1440

    for slug <- @slugs, do: assert(ScreenHTML.source("email", slug) =~ "Email.layout")
  end

  test "the page shows every e-mail in a frame that points at the real page" do
    {:ok, view, _html} = live(build_conn(), "/templates/email")

    assert has_element?(view, "#templates-email")

    for slug <- @slugs do
      assert has_element?(view, "#frame-email-#{slug} iframe[src='/screens/email/#{slug}']")
      assert has_element?(view, "#template-email-#{slug}")
    end
  end

  test "every e-mail is tables and inline styles, with the dark rules scoped to the theme" do
    for slug <- @slugs do
      {:ok, _view, html} = live(build_conn(), "/screens/email/#{slug}")

      assert html =~ ~s(class="em-card em-pad")
      assert html =~ "[data-theme=dark] .em-body{background: #101016 !important}"
      refute html =~ ~r/display:\s*(flex|grid)/
      refute html =~ "var(--"
    end
  end
end
