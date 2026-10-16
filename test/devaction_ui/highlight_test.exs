defmodule DevactionUI.HighlightTest do
  use ExUnit.Case, async: true

  alias DevactionUI.Highlight

  defp kinds(source),
    do: for({kind, text} <- Highlight.heex(source), kind != :text, do: {kind, text})

  test "the tokens put back together are the source, whatever it holds" do
    sources = [
      ~S|<.accordion id="a"><:header>Hi</:header></.accordion>|,
      ~S|<Tag.tag variant={:ok} class={["a", %{b: 1}]}>x</Tag.tag>|,
      "<%!-- a comment --%>\n<%= @x %> and <% y %> and { stray",
      "a < b and c > d",
      "<div\n  class=\"x\"\n  disabled\n/>"
    ]

    for source <- sources do
      assert Highlight.heex(source) |> Enum.map_join(&elem(&1, 1)) == source
    end
  end

  test "a component, a slot and an html tag are told apart" do
    assert {:component, ".accordion"} in kinds("<.accordion>")
    assert {:component, "Tag.tag"} in kinds("<Tag.tag>")
    assert {:slot, ":header"} in kinds("<:header>")
    assert {:html, "div"} in kinds("<div>")
  end

  test "a closing tag keeps its slash with the bracket" do
    assert {:punct, "</"} in kinds("</.accordion>")
  end

  test "attributes, strings and expressions have their own kinds" do
    tokens = kinds(~S|<Button.button variant={:ok} id="go" disabled>|)

    assert {:attr, "variant"} in tokens
    assert {:expr, "{:ok}"} in tokens
    assert {:string, ~S|"go"|} in tokens
    assert {:attr, "disabled"} in tokens
  end

  test "braces nest" do
    assert {:expr, "{[a: %{b: 1}]}"} in kinds("<x y={[a: %{b: 1}]} />")
  end

  test "comments and eex blocks are whole tokens" do
    tokens = kinds("<%!-- note --%><%= @x %>")

    assert {:comment, "<%!-- note --%>"} in tokens
    assert {:expr, "<%= @x %>"} in tokens
  end

  test "single-quoted attribute values are strings" do
    tokens = kinds(~S|<a href='x "y"' id="z">|)

    assert {:string, ~S|'x "y"'|} in tokens
    assert {:string, ~S|"z"|} in tokens
  end

  test "html comments are whole tokens" do
    assert {:comment, "<!-- a <b> -->"} in kinds("<!-- a <b> --><p>")
    assert {:html, "p"} in kinds("<!-- a --><p>")
  end

  test "truncated input still round-trips" do
    for source <- ["<!-- open", "<%!-- open", "<div class=\"x", "<div class='x", "<a b={ {", "<"] do
      assert Highlight.heex(source) |> Enum.map_join(&elem(&1, 1)) == source
    end
  end

  test "a lone less-than sign is text" do
    assert kinds("1 < 2") == []
  end

  describe "in a code block" do
    import Phoenix.Component
    import Phoenix.LiveViewTest

    alias DevactionUI.CodeBlock

    test "lang: :heex wraps the parts of a template in coloured spans and keeps the text" do
      assigns = %{code: ~S|<.tab id="a">Hi</.tab>|}

      html = rendered_to_string(~H|<CodeBlock.code_block lang={:heex} code={@code} />|)

      assert html =~ "text-[#7AA2F7]"
      assert html =~ "text-[#E4E4E7]"
      assert html =~ "Hi"
    end

    test "without a lang the code stays plain" do
      assigns = %{code: "<.tab>"}

      html = rendered_to_string(~H|<CodeBlock.code_block code={@code} />|)

      refute html =~ "<span class=\"text-"
      assert html =~ "&lt;.tab&gt;"
    end
  end
end
