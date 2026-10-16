defmodule DevactionUI.EmailTest do
  @moduledoc "The e-mail set: the document and its head, the layout, the text parts, the tags, callouts and tables."
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.{Email, EmailCallout, EmailTable, EmailTag}

  describe "document/1" do
    setup do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Email.document lang="en" title="Your link">
          <p>inside</p>
        </Email.document>
        """)

      %{html: html}
    end

    test "is a whole page with the color-scheme metas", %{html: html} do
      assert html =~ "<!doctype html>"
      assert html =~ ~s(<html lang="en")
      assert html =~ ~s(<meta name="color-scheme" content="light dark")
      assert html =~ ~s(<meta name="supported-color-schemes" content="light dark")
      assert html =~ ~s(<meta name="viewport" content="width=device-width, initial-scale=1")
      assert html =~ "<title>Your link</title>"
      assert html =~ ~s(<body class="em-body")
      assert html =~ "<p>inside</p>"
    end

    test "carries the one stylesheet: mobile padding and the dark rules", %{html: html} do
      assert html =~ "@media (max-width:620px){.em-pad{padding:28px 22px !important}"

      assert html =~
               "@media (prefers-color-scheme: dark){.em-body{background: #101016 !important}"

      for klass <-
            ~w(em-card em-ink em-muted em-soft em-line em-line-b em-panel em-btn-primary em-btn-secondary em-step-on) do
        assert html =~ ".#{klass}{"
      end
    end

    test "a dark scope puts the dark rules under a selector instead of the media query" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Email.document lang="en" title="t" dark_scope="[data-theme=dark]">x</Email.document>
        """)

      assert html =~ "[data-theme=dark] .em-body{background: #101016 !important}"
      refute html =~ "prefers-color-scheme: dark"
    end

    test "to_html/1 gives the string" do
      assigns = %{}

      assert Email.to_html(~H"<Email.heading>Hi</Email.heading>") =~ "<h1"
    end
  end

  describe "layout/1" do
    setup do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Email.layout
          preheader="Click to enter."
          brand_name="Acme"
          brand_href="https://acme.test"
          logo_src="https://acme.test/logo.png"
          signature="Acme Inc."
        >
          body text
          <:footer>Why you got this.</:footer>
          <:footer>Second line.</:footer>
        </Email.layout>
        """)

      %{html: html}
    end

    test "hides the preheader and draws the brand", %{html: html} do
      assert html =~ "mso-hide: all"
      assert html =~ "Click to enter."
      assert html =~ ~s(href="https://acme.test")
      assert html =~ ~s(src="https://acme.test/logo.png")
      assert html =~ ~s(alt="Acme")
      assert html =~ ~s(width="36")
    end

    test "is a 600px column with the card, the dark hooks and the footer", %{html: html} do
      assert html =~ ~s(width="600")
      assert html =~ "max-width: 600px"
      assert html =~ ~s(class="em-body")
      assert html =~ ~s(class="em-outer")
      assert html =~ ~s(class="em-card em-pad")
      assert html =~ "body text"
      assert html =~ "Why you got this."
      assert html =~ "Second line."
      assert html =~ "Acme Inc."
      assert html =~ "#F4F4F5"
    end
  end

  test "footer_link/1 is an underlined link" do
    assigns = %{}

    html = rendered_to_string(~H|<Email.footer_link href="/prefs">Prefs</Email.footer_link>|)

    assert html =~ ~s(href="/prefs")
    assert html =~ "text-decoration: underline"
    assert html =~ ">Prefs</a>"
  end

  test "heading/1 is the 26px ink title with the dark hook" do
    assigns = %{}
    html = rendered_to_string(~H|<Email.heading id="h">Title</Email.heading>|)

    assert html =~ ~s(<h1 class="em-ink")
    assert html =~ "font-size: 26px"
    assert html =~ "color: #18181B"
    assert html =~ ~s(id="h")
  end

  describe "paragraph/1" do
    test "body is muted 16px with a margin" do
      assigns = %{}
      html = rendered_to_string(~H|<Email.paragraph>Text</Email.paragraph>|)

      assert html =~ ~s(class="em-muted")
      assert html =~ "font-size: 16px"
      assert html =~ "color: #52525B"
      assert html =~ "margin: 0 0 16px"
    end

    test "compact is 15px" do
      assigns = %{}
      html = rendered_to_string(~H|<Email.paragraph size={:compact}>Text</Email.paragraph>|)

      assert html =~ "font-size: 15px"
    end

    test "small is the soft fine print and can be flush" do
      assigns = %{}
      html = rendered_to_string(~H|<Email.paragraph size={:small} flush>Text</Email.paragraph>|)

      assert html =~ ~s(class="em-soft")
      assert html =~ "font-size: 13px"
      assert html =~ "color: #71717A"
      assert html =~ "margin: 0;"
    end

    test "lead takes the ink color" do
      assigns = %{}
      html = rendered_to_string(~H|<Email.paragraph lead>Hello</Email.paragraph>|)

      assert html =~ ~s(class="em-ink")
      assert html =~ "color: #18181B"
    end
  end

  test "emphasis/1 turns light in dark mode on the card and stays dark on a tint" do
    assigns = %{}

    card = rendered_to_string(~H|<Email.emphasis>A</Email.emphasis>|)
    tint = rendered_to_string(~H|<Email.emphasis surface={:tint}>A</Email.emphasis>|)

    assert card =~ ~s(class="em-ink")
    refute tint =~ "em-ink"
    assert tint =~ "color: #18181B"
  end

  test "emphasis/1 and caption/1" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Email.emphasis>15 minutes</Email.emphasis><Email.caption>WHAT TO LOOK AT</Email.caption>
      """)

    assert html =~ ~r/<strong class="em-ink"[^>]*font-weight: 600[^>]*>15 minutes<\/strong>/
    assert html =~ "letter-spacing: 0.08em"
    assert html =~ "WHAT TO LOOK AT"
  end

  describe "button/1" do
    test "primary is the ink cell with the dark hook and a blank target" do
      assigns = %{}
      html = rendered_to_string(~H|<Email.button href="https://x.test/a">Go</Email.button>|)

      assert html =~ ~s(class="em-btn-primary")
      assert html =~ "background: #18181B"
      assert html =~ "color: #FFFFFF"
      assert html =~ ~s(href="https://x.test/a")
      assert html =~ ~s(target="_blank")
      assert html =~ "padding: 14px 24px"
      assert html =~ "border-radius: 12px"
    end

    test "secondary is outlined" do
      assigns = %{}

      html =
        rendered_to_string(~H|<Email.button href="/a" variant={:secondary}>Go</Email.button>|)

      assert html =~ ~s(class="em-btn-secondary")
      assert html =~ "border: 1px solid #D4D4D8"
      assert html =~ "background: #FFFFFF"
    end

    test "button_row/1 puts buttons side by side with the narrower padding" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Email.button_row>
          <:button href="/a">One</:button>
          <:button href="/b" variant={:secondary}>Two</:button>
        </Email.button_row>
        """)

      assert html =~ "padding: 14px 20px"
      assert html =~ ~s(class="em-btn-primary")
      assert html =~ ~s(class="em-btn-secondary")
      assert html =~ "padding-right: 10px"
    end
  end

  test "link_fallback/1 shows the address in mono and links it" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Email.link_fallback href="https://x.test/t/1">Paste this:</Email.link_fallback>
      """)

    assert html =~ "Paste this:"
    assert html =~ ~s(<a href="https://x.test/t/1")
    assert html =~ ">https://x.test/t/1</a>"
    assert html =~ "word-break: break-all"
    assert html =~ "Geist Mono"
  end

  test "divider/1 is the hairline with the dark hook" do
    assigns = %{}
    html = rendered_to_string(~H|<Email.divider />|)

    assert html =~ ~s(class="em-line")
    assert html =~ "height: 1px"
    assert html =~ "background: #E4E4E7"
  end

  test "byline/1 is the avatar and the sentence" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Email.byline initials="CA">Carlos invited you.</Email.byline>
      """)

    assert html =~ ">CA</span>"
    assert html =~ "background: #EEF2FF"
    assert html =~ "Carlos invited you."
  end

  describe "EmailTag" do
    test "each tone has its own hex values" do
      for {tone, line, bg, ink} <- [
            {:risk, "#FBCFCF", "#FEF2F2", "#B91C1C"},
            {:warn, "#F5DFA8", "#FEF9EC", "#854D0E"},
            {:ok, "#BBF7D0", "#F0FDF4", "#15803D"},
            {:info, "#C7D7FE", "#EFF4FF", "#1E40AF"},
            {:neutral, "#E4E4E7", "#F4F4F5", "#3F3F46"}
          ] do
        assigns = %{tone: tone}
        html = rendered_to_string(~H|<EmailTag.tag tone={@tone}>LABEL</EmailTag.tag>|)

        assert html =~ "border: 1px solid #{line}"
        assert html =~ "background: #{bg}"
        assert html =~ "color: #{ink}"
        assert html =~ ">LABEL</span>"
      end
    end

    test "sizes" do
      assigns = %{}
      small = rendered_to_string(~H|<EmailTag.tag>A</EmailTag.tag>|)
      medium = rendered_to_string(~H|<EmailTag.tag size={:md}>A</EmailTag.tag>|)

      assert small =~ "padding: 3px 7px"
      assert small =~ "font-size: 10px"
      assert medium =~ "padding: 4px 8px"
      assert medium =~ "font-size: 11px"
    end

    test "tag_row/1 lines tags up" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <EmailTag.tag_row>
          <:tag tone={:risk}>2 RISKS</:tag>
          <:tag tone={:ok}>TESTS OK</:tag>
        </EmailTag.tag_row>
        """)

      assert html =~ "2 RISKS"
      assert html =~ "color: #B91C1C"
      assert html =~ "color: #15803D"
      assert html =~ "padding: 0 6px 0 0"
    end

    test "chip/1 names the subject in mono" do
      assigns = %{}
      html = rendered_to_string(~H|<EmailTag.chip tone={:info}>sge-api · #142</EmailTag.chip>|)

      assert html =~ "sge-api · #142"
      assert html =~ "border-radius: 8px"
      assert html =~ "color: #1E40AF"
      assert html =~ "font-size: 12px"
    end
  end

  describe "EmailCallout" do
    test "callout/1 takes the tone of its notice" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <EmailCallout.callout tone={:risk} lead="Not you?">Reset it now.</EmailCallout.callout>
        """)

      assert html =~ "Reset it now."
      assert html =~ ~r/<strong style="color: #18181B; font-weight: 600">Not you\?<\/strong>/
      assert html =~ "border: 1px solid #FBCFCF"
      assert html =~ "background: #FEF2F2"
      assert html =~ "color: #B91C1C"
      assert html =~ "border-radius: 12px"
    end

    test "highlight/1 is the warm card with a linked title" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <EmailCallout.highlight label="LESSON" title="Oban" href="/l/1" meta="12 min" />
        """)

      assert html =~ "background: #FFFDF6"
      assert html =~ "LESSON"
      assert html =~ ~s(<a href="/l/1")
      assert html =~ ">Oban</a>"
      assert html =~ "12 min"
    end
  end

  describe "EmailTable" do
    test "details/1 draws label and value rows with the dark hooks" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <EmailTable.details>
          <:row label="Device">Firefox</:row>
          <:row label="When">Today</:row>
        </EmailTable.details>
        """)

      assert html =~ "Device"
      assert html =~ ~r/>\s*Firefox/
      assert html =~ ~s(class="em-line-b em-soft")
      assert html =~ ~s(class="em-line-b em-ink")
      assert html =~ "width: 42%"
      assert html =~ "text-align: right"
    end

    test "finding_list/1 has a tag, a title and a mono location" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <EmailTable.finding_list>
          <:item tone={:risk} tag="RISK" title="Unscoped query" location="lib/a.ex:1" />
        </EmailTable.finding_list>
        """)

      assert html =~ ">RISK</span>"
      assert html =~ "Unscoped query"
      assert html =~ "lib/a.ex:1"
      assert html =~ "width: 84px"
      assert html =~ "border-radius: 12px"
    end

    test "code_list/1 has a mono code and the text" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <EmailTable.code_list>
          <:item code="1.1">Export CSV</:item>
        </EmailTable.code_list>
        """)

      assert html =~ "1.1"
      assert html =~ "Export CSV"
      assert html =~ "width: 44px"
    end

    test "event_list/1 has the title and detail, then the tag and the date" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <EmailTable.event_list>
          <:item title="Renewal" detail="Hub API" tone={:warn} tag="30 DAYS" date="Nov 15" />
        </EmailTable.event_list>
        """)

      assert html =~ "Renewal"
      assert html =~ "Hub API"
      assert html =~ ">30 DAYS</span>"
      assert html =~ "Nov 15"
      assert html =~ "color: #854D0E"
    end

    test "steps/1 numbers the steps and solidifies the current one" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <EmailTable.steps>
          <:step title="Confirm" current>Here.</:step>
          <:step title="Connect">Next.</:step>
        </EmailTable.steps>
        """)

      assert html =~ ~r/background: #18181B; color: #FFFFFF[^>]*>1<\/span>/
      assert html =~ ~r/background: #F4F4F5; color: #52525B[^>]*>2<\/span>/
      assert html =~ "Confirm"
      assert html =~ "Next."
    end

    test "stats/1 splits the width and spaces the tiles" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <EmailTable.stats>
          <:stat value="12" label="Reviewed" />
          <:stat value="3" label="Risks" />
          <:stat value="5" label="Lessons" />
        </EmailTable.stats>
        """)

      assert html =~ ~s(width="33%")
      assert html =~ ~s(class="em-panel")
      assert html =~ ~r/>\s*12\s*</
      assert html =~ "Lessons"
      assert length(Regex.scan(~r/width="8"/, html)) == 2
    end
  end

  test "a whole e-mail is tables and inline styles only" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Email.document lang="en" title="All">
        <Email.layout
          preheader="p"
          brand_name="Acme"
          brand_href="https://acme.test"
          logo_src="https://acme.test/l.png"
          signature="Acme"
        >
          <Email.byline initials="A">Someone</Email.byline>
          <EmailTag.chip>chip</EmailTag.chip>
          <Email.heading>Title</Email.heading>
          <Email.paragraph>Text</Email.paragraph>
          <EmailTag.tag_row>
            <:tag tone={:ok}>OK</:tag>
          </EmailTag.tag_row>
          <EmailTable.stats><:stat value="1" label="One" /></EmailTable.stats>
          <EmailTable.details>
            <:row label="A">B</:row>
          </EmailTable.details>
          <EmailTable.finding_list>
            <:item tone={:risk} tag="R" title="T" location="L" />
          </EmailTable.finding_list>
          <EmailTable.steps>
            <:step title="S">d</:step>
          </EmailTable.steps>
          <EmailCallout.callout>Note</EmailCallout.callout>
          <EmailCallout.highlight label="L" title="T" href="/x" meta="m" />
          <Email.button href="/b">Go</Email.button>
          <Email.link_fallback href="/b">Paste</Email.link_fallback>
          <Email.divider />
        </Email.layout>
      </Email.document>
      """)

    refute html =~ ~r/display:\s*(flex|grid|inline-flex|inline-grid)/
    refute html =~ "var(--"
    refute html =~ ~r/<link[\s>]/
    refute html =~ "@import"
    refute html =~ "<script"
    refute html =~ ~r/\sclass="[^"]*\b(flex|grid|px-\d|text-\w+-\d)/
  end
end
