defmodule DevactionUI.AuthTest do
  @moduledoc "The pieces of a sign-in screen: the layout, the card, the divider and the password meter."
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.{AuthCard, AuthLayout, Divider, PasswordStrength}

  describe "AuthLayout" do
    defp layout do
      assigns = %{}

      rendered_to_string(~H"""
      <AuthLayout.auth_layout
        about_label="About the product"
        nav_label="Legal"
        headline="Contracts, code and learning in one place."
        copyright="© 2026 DevAction Labs"
      >
        <:brand><span id="brand">DevAction</span></:brand>
        <:feature title="PR review" text="The AI reads the diff.">I1</:feature>
        <:feature title="Contracts" text="Scope and invoices.">I2</:feature>
        <:link href="/terms">Terms</:link>
        <:link href="/privacy">Privacy</:link>
        <div id="the-card">card</div>
      </AuthLayout.auth_layout>
      """)
    end

    test "the product column is a named section with the brand, the headline and the reasons" do
      html = layout()

      assert html =~ ~s(aria-label="About the product")
      assert html =~ ~s(id="brand")
      assert html =~ "Contracts, code and learning in one place."
      assert html =~ "PR review"
      assert html =~ "The AI reads the diff."
      assert html =~ "I2"
    end

    test "the card goes in the right column and the footer has the copyright and the links" do
      html = layout()

      assert html =~ ~s(id="the-card")
      assert html =~ "© 2026 DevAction Labs"
      assert html =~ ~s(href="/terms")
      assert html =~ ~s(href="/privacy")
    end

    test "the columns are the main landmark and the footer links a named nav" do
      html = layout()

      assert html =~ ~r/<main id="main"[^>]*>.*the-card.*<\/main>/s
      assert html =~ ~r/<footer.*<nav aria-label="Legal".*href="\/terms".*<\/footer>/s
    end

    test "the id of main is the host's, for its skip link" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <AuthLayout.auth_layout
          about_label="A"
          nav_label="N"
          main_id="content"
          headline="H"
          copyright="C"
        >
          <:brand>B</:brand>
          x
        </AuthLayout.auth_layout>
        """)

      assert html =~ ~s(<main id="content")
    end

    test "the icons of the reasons are hidden from assistive technology" do
      assert layout() =~ ~r/aria-hidden="true"[^>]*>\s*I1/s
    end

    test "the footer and the reasons take their colours from tokens, never a hex" do
      html = layout()

      assert html =~ "text-(--auth-foot)"
      assert html =~ "bg-(--auth-feature)"
      refute html =~ "#8A8A9C"
      refute html =~ "#17171F"
    end
  end

  describe "auth_brand/1" do
    test "is the tile on the brand tokens, with the symbol hidden, and the name" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <AuthLayout.auth_brand name="DevAction IA" id="brand" data-x="1">
          <:mark><svg id="mark" /></:mark>
        </AuthLayout.auth_brand>
        """)

      assert html =~
               ~r/<span[^>]*bg-\(--brand-tile\)[^>]*aria-hidden="true"[^>]*>\s*<svg id="mark"/s

      assert html =~ "size-[34px]"
      assert html =~ "border-(--brand-tile-line)"
      assert html =~ "DevAction IA"
      assert html =~ "text-lg font-semibold"
      assert html =~ ~s(data-x="1")
    end
  end

  describe "AuthCard" do
    test "a title, a text, an icon, the form and a footer strip" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <AuthCard.auth_card title="Welcome back" text="Sign in to continue.">
          <:icon>ICON</:icon>
          <form id="f">form</form>
          <:footer>No account? Create one</:footer>
        </AuthCard.auth_card>
        """)

      assert html =~ "<h1"
      assert html =~ "Welcome back"
      assert html =~ "Sign in to continue."
      assert html =~ "ICON"
      assert html =~ ~s(id="f")
      assert html =~ "No account? Create one"
      assert html =~ "auth-grid"
      assert html =~ "auth-glow"
    end

    test "the subtitle slot takes rich text instead of the text" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <AuthCard.auth_card title="Check your e-mail">
          <:subtitle>Sent to <strong>alex@devaction.com.br</strong></:subtitle>
          body
        </AuthCard.auth_card>
        """)

      assert html =~ "<strong>alex@devaction.com.br</strong>"
    end

    test "the heading is an h2 when the card is not the page" do
      assigns = %{}

      html =
        rendered_to_string(~H|<AuthCard.auth_card title="T" heading={:h2}>x</AuthCard.auth_card>|)

      assert html =~ ~r/<h2 class="[^"]*">T<\/h2>/
      refute html =~ "<h1"
    end

    test "the brand tone puts the icon on the product's tile, through tokens" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <AuthCard.auth_card title="T" icon_tone={:brand}>
          <:icon>I</:icon>
          x
        </AuthCard.auth_card>
        """)

      assert html =~ "bg-(--brand-tile)"
      assert html =~ "border-(--brand-tile-line)"
      refute html =~ "#060C1F"
    end

    test "the footer strip is px-7 py-[18px] on a line" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <AuthCard.auth_card title="T">
          x
          <:footer>F</:footer>
        </AuthCard.auth_card>
        """)

      assert html =~
               "border-t border-(--auth-strip-line) bg-(--auth-strip) px-7 py-[18px]"

      refute html =~ "#16161D"
    end

    test "without an icon or a footer neither is drawn" do
      assigns = %{}

      html = rendered_to_string(~H|<AuthCard.auth_card title="T">x</AuthCard.auth_card>|)

      refute html =~ "auth-icon"
      refute html =~ "border-t"
    end

    test "the icon's tile takes the caller's classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <AuthCard.auth_card title="T" icon_class="bg-tag-warn-bg">
          <:icon>I</:icon>
          x
        </AuthCard.auth_card>
        """)

      assert html =~ "auth-icon bg-tag-warn-bg"
    end
  end

  describe "AuthLayout links" do
    test "a link goes through the router's link, so a script URL is refused" do
      assigns = %{}

      assert_raise ArgumentError, fn ->
        rendered_to_string(~H"""
        <AuthLayout.auth_layout about_label="A" nav_label="N" headline="H" copyright="C">
          <:brand>B</:brand>
          <:link href="javascript:alert(1)">Bad</:link>
          x
        </AuthLayout.auth_layout>
        """)
      end
    end
  end

  describe "Divider" do
    test "with a word it is a separator reading it" do
      assigns = %{}
      html = rendered_to_string(~H|<Divider.divider label="or" />|)

      assert html =~ ~s(role="separator")
      assert html =~ "or"
    end

    test "without a word it is a plain rule" do
      assigns = %{}
      html = rendered_to_string(~H|<Divider.divider />|)

      assert html =~ "<hr"
      refute html =~ ~s(role="separator")
    end
  end

  describe "PasswordStrength.evaluate/2" do
    test "an empty password meets nothing and scores 0" do
      assert PasswordStrength.evaluate("") ==
               %{
                 score: 0,
                 rules: [length: false, mixed_case: false, digit_or_symbol: false]
               }
    end

    test "each rule is told apart" do
      assert %{rules: [length: false, mixed_case: false, digit_or_symbol: true]} =
               PasswordStrength.evaluate("1234")

      assert %{rules: [length: false, mixed_case: true, digit_or_symbol: false]} =
               PasswordStrength.evaluate("Abcd")

      assert %{rules: [length: true, mixed_case: false, digit_or_symbol: false]} =
               PasswordStrength.evaluate("abcdefghijkl")
    end

    test "accented capitals and small letters count as letters" do
      assert PasswordStrength.evaluate("Ação").rules[:mixed_case]
    end

    test "the score is the rules met, plus one for 16 characters, and 0 when no rule is met" do
      assert PasswordStrength.evaluate("a").score == 0
      assert PasswordStrength.evaluate("Ab1").score == 2
      assert PasswordStrength.evaluate("Abcdefghijk1").score == 3
      assert PasswordStrength.evaluate("Abcdefghijklmnop1").score == 4
    end

    test "two rules and 16 characters make 3, and no rule stays 0 however long" do
      assert PasswordStrength.evaluate("abcdefghijklmnop", 20).score == 0
      assert PasswordStrength.evaluate("abcdefghijklmnop").score == 2
      assert PasswordStrength.evaluate("abcdefghijklmno1").score == 3
      assert PasswordStrength.evaluate("Abcdefghij1", 12).score == 2
    end

    test "the 16 characters of the bonus do not follow the minimum length" do
      assert PasswordStrength.evaluate("abcdefghijklmno", 8).score == 1
      assert PasswordStrength.evaluate("abcdefghijklmnop", 8).score == 2
      assert PasswordStrength.evaluate("Abcdefgh1", 8).score == 3
      assert PasswordStrength.evaluate("Abcdefghijklmno1", 8).score == 4
    end

    test "the minimum length is the caller's" do
      assert PasswordStrength.evaluate("abcdefgh", 8).rules[:length]
      refute PasswordStrength.evaluate("abcdefgh", 9).rules[:length]
    end
  end

  describe "PasswordStrength.password_strength/1" do
    defp meter(score, rules) do
      assigns = %{score: score, rules: rules}

      rendered_to_string(~H"""
      <PasswordStrength.password_strength
        score={@score}
        label="Weak"
        meter_label="Password strength"
        rules={@rules}
      >
        <:met_icon>OK</:met_icon>
        <:unmet_icon>--</:unmet_icon>
      </PasswordStrength.password_strength>
      """)
    end

    test "it is a meter with its value and name, and a line under the bars" do
      html = meter(2, [%{label: "12 characters", met: false}])

      assert html =~ ~s(role="meter")
      assert html =~ ~s(aria-valuenow="2")
      assert html =~ ~s(aria-label="Password strength")
      assert html =~ ~s(aria-valuetext="Weak")
      assert html =~ "12 characters"
    end

    test "the line is announced politely and takes the colour of the score" do
      assert meter(2, []) =~ ~r/<p aria-live="polite" class="[^"]*text-tag-warn-text/
      assert meter(0, []) =~ ~r/<p aria-live="polite" class="[^"]*text-muted/
    end

    test "a rule that is met colours the whole line, not only the mark" do
      assert meter(1, [%{label: "A", met: true}]) =~ "data-[met=true]:text-ok-fg"
    end

    test "without icons the rules are still listed" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <PasswordStrength.password_strength
          score={1}
          label="Weak"
          meter_label="Strength"
          rules={[%{label: "A", met: true}]}
        />
        """)

      assert html =~ "A"
      assert html =~ ~s(aria-hidden="true")
    end

    test "the bars up to the score are filled and the rest are empty" do
      html = meter(3, [])

      assert length(Regex.scan(~r/h-\[5px\] rounded-full bg-learn/, html)) <= 3
      assert length(Regex.scan(~r/h-\[5px\] rounded-full bg-line/, html)) == 1
    end

    test "a rule that is met gets its mark and a rule that is not gets the other" do
      html = meter(1, [%{label: "A", met: true}, %{label: "B", met: false}])

      assert html =~ ~r/data-met="true".*OK.*A/s
      assert html =~ ~r/data-met="false".*--.*B/s
    end

    test "the colour follows the score" do
      assert meter(1, []) =~ DevactionUI.Tone.fill(:risk)
      assert meter(2, []) =~ DevactionUI.Tone.fill(:warn)
      assert meter(4, []) =~ DevactionUI.Tone.fill(:ok)
    end
  end
end
