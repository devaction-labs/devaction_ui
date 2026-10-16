defmodule DevactionUI.ComponentsTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  import DevactionUI.{Callout, CodeBlock, Kbd, Progress, Skeleton, Spinner, Tag}

  alias DevactionUI.Tone

  describe "Tone" do
    test "kinds of the canvas map to the five tones" do
      assert Enum.map([:ai, :warning, :decision, :tip, :note], &Tone.from_kind/1) ==
               [:warn, :risk, :ok, :info, :neutral]

      assert Tone.from_kind(:risk) == :risk
    end

    test "every tone has a surface, a text and a fill" do
      for tone <- [:risk, :warn, :ok, :info, :neutral] do
        assert Tone.surface(tone) =~ "border-tag-#{tone}-line"
        assert Tone.text(tone) =~ "text-tag-#{tone}-text"
        assert is_binary(Tone.fill(tone))
      end
    end
  end

  describe "tag/1" do
    test "the small size is the 11px tag of lists" do
      assigns = %{}
      html = rendered_to_string(~H|<.tag size={:sm} variant={:ok}>OK</.tag>|)
      assert html =~ "text-[11px]"
      assert html =~ "bg-tag-ok-bg"
    end

    test "a plain surface swaps the tinted background for the card's, keeping border and text" do
      assigns = %{}
      html = rendered_to_string(~H|<.tag surface={:plain} variant={:risk}>Problem</.tag>|)
      assert html =~ "bg-card"
      refute html =~ "bg-tag-risk-bg"
      assert html =~ "border-tag-risk-line"
      assert html =~ "text-tag-risk-text"
    end
  end

  describe "callout/1" do
    test "carries its title, icon, role and the tone of its kind" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.callout kind={:warning} role="alert" title="Careful" id="c">
          <:icon><span class="icon-here" /></:icon>
          Someone is missing.
        </.callout>
        """)

      assert html =~ ~s(role="alert")
      assert html =~ "border-tag-risk-line"
      assert html =~ "icon-here"
      assert html =~ "Careful"
      assert html =~ "Someone is missing."
      assert html =~ ~s(id="c")
    end

    test "has no icon, title or actions row unless asked" do
      assigns = %{}
      html = rendered_to_string(~H|<.callout>Plain</.callout>|)
      refute html =~ "hero-"
      refute html =~ "font-semibold"
      refute html =~ "pt-1"
    end

    test "actions go under the body" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.callout kind={:ai}>
          Body
          <:actions><a href="/x">Go</a></:actions>
        </.callout>
        """)

      assert html =~ ~s(href="/x")
      assert html =~ "border-tag-warn-line"
    end
  end

  describe "code_block/1" do
    test "keeps the code exactly, with no space of the template around it" do
      assigns = %{code: "  a\nb"}
      html = rendered_to_string(~H|<.code_block code={@code} id="cb" />|)
      assert html =~ "<code>  a\nb</code>"
      assert html =~ ~s(id="cb")
      assert html =~ "bg-[#18181B]"
    end

    test "the tinted tones carry a colored caption" do
      assigns = %{}
      html = rendered_to_string(~H|<.code_block tone={:risk} label="Your code" code="x" />|)
      assert html =~ "Your code"
      assert html =~ "border-tag-risk-line"
      assert html =~ "text-tag-risk-text"
    end
  end

  describe "code_block/1 regions and copy" do
    test "the neutral and ok tones are tinted like the risk one" do
      assigns = %{}

      for {tone, border} <- [neutral: "border-tag-neutral-line", ok: "border-tag-ok-line"] do
        assigns = Map.put(assigns, :tone, tone)
        html = rendered_to_string(~H|<.code_block tone={@tone} label="L" code="x" />|)

        assert html =~ border
        assert html =~ "text-tag-#{tone}-text"
      end
    end

    test "a label makes the block a named region the keyboard can focus" do
      assigns = %{}
      html = rendered_to_string(~H|<.code_block label="The fix" code="x" />|)

      assert html =~ ~s(role="region")
      assert html =~ ~s(aria-label="The fix")
      assert html =~ ~s(tabindex="0")
    end

    test "without a label there is neither a region nor a tab stop" do
      assigns = %{}
      html = rendered_to_string(~H|<.code_block code="x" />|)

      refute html =~ "role="
      refute html =~ "tabindex"
    end

    test "copy_label adds a hidden button under the hook, and says nothing without it" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<.code_block id="cb" copy_label="Copy" copied_label="Copied" code="x" />|
        )

      assert html =~ ~s(phx-hook="DevactionUI.CodeCopy")
      assert html =~ ~s(data-copied-label="Copied")
      assert html =~ ~r/<button[^>]*hidden[^>]*data-code-copy/
      assert html =~ ">Copy<"
      assert html =~ ~s(role="status")

      plain = rendered_to_string(~H|<.code_block id="cb" code="x" />|)
      refute plain =~ "button"
      refute plain =~ "phx-hook"
    end

    test "the copy icon replaces the visible name, which stays for assistive technology" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.code_block id="cb" copy_label="Copy" code="x">
          <:copy_icon>ICON</:copy_icon>
        </.code_block>
        """)

      assert html =~ "ICON"
      assert html =~ ~r/class="sr-only">Copy</
    end

    test "the hook needs an id, so a copy button without one is a mistake" do
      assigns = %{}

      assert_raise ArgumentError, ~r/id/, fn ->
        rendered_to_string(~H|<.code_block copy_label="Copy" code="x" />|)
      end
    end
  end

  test "kbd/1 draws a key cap" do
    assigns = %{}
    html = rendered_to_string(~H|<.kbd>⌘K</.kbd>|)
    assert html =~ "<kbd"
    assert html =~ "⌘K"
    assert html =~ "border-b-2"
    assert html =~ "border-line"
    refute html =~ "border-line-strong"
  end

  test "kbd/1 has an inverse tone for dark surfaces and a bare one for menus" do
    assigns = %{}

    inverse = rendered_to_string(~H|<.kbd tone={:inverse}>⌘B</.kbd>|)
    assert inverse =~ "bg-kbd-inverse"
    assert inverse =~ "text-[10px]"
    refute inverse =~ "border"

    bare = rendered_to_string(~H|<.kbd tone={:bare}>⌘E</.kbd>|)
    assert bare =~ "text-muted"
    refute bare =~ "border"
    refute bare =~ "bg-"
  end

  test "kbd/1 has a larger cap" do
    assigns = %{}
    html = rendered_to_string(~H|<.kbd size={:md}>Esc</.kbd>|)
    assert html =~ "px-[7px]"
  end

  describe "progress/1" do
    test "is a progress bar with its value and a label" do
      assigns = %{}
      html = rendered_to_string(~H|<.progress value={42} label="Scope" tone={:ok} />|)
      assert html =~ ~s(role="progressbar")
      assert html =~ ~s(aria-valuenow="42")
      assert html =~ ~s(aria-label="Scope")
      assert html =~ "width: 42%"
      assert html =~ Tone.fill(:ok)
    end

    test "never leaves 0 to 100" do
      assigns = %{}

      assert rendered_to_string(~H|<.progress value={140} label="x" />|) =~
               ~s(aria-valuenow="100")

      assert rendered_to_string(~H|<.progress value={-5} label="x" />|) =~ ~s(aria-valuenow="0")
    end
  end

  test "spinner/1 speaks its label to screen readers only" do
    assigns = %{}
    html = rendered_to_string(~H|<.spinner label="Saving" />|)
    assert html =~ ~s(role="status")
    assert html =~ ~s(<span class="sr-only">Saving</span>)
    assert html =~ "motion-reduce:animate-none"
  end

  describe "skeleton/1" do
    test "shimmers, stops for reduced motion and is hidden from assistive technology" do
      assigns = %{}
      html = rendered_to_string(~H|<.skeleton shape={:circle} class="size-12" />|)
      assert html =~ "animate-shimmer"
      assert html =~ "motion-reduce:animate-none"
      assert html =~ ~s(aria-hidden="true")
      assert html =~ "rounded-full"
      assert html =~ "size-12"
    end
  end
end
