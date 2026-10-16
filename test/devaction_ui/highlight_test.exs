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
    assert {:expr, "{"} in tokens
    assert {:atom, ":ok"} in tokens
    assert {:expr, "}"} in tokens
    assert {:string, ~S|"go"|} in tokens
    assert {:attr, "disabled"} in tokens
  end

  test "braces nest" do
    tokens = kinds("<x y={[a: %{b: 1}]} />")

    assert Enum.count(tokens, &(&1 == {:expr, "}"})) == 1
    assert {:atom, "a:"} in tokens
    assert {:atom, "b:"} in tokens
    assert {:number, "1"} in tokens
  end

  test "comments and eex blocks are whole tokens" do
    tokens = kinds("<%!-- note --%><%= @x %>")

    assert {:comment, "<%!-- note --%>"} in tokens
    assert {:expr, "<%="} in tokens
    assert {:assign, "@x"} in tokens
    assert {:expr, "%>"} in tokens
  end

  test "an expression is Elixir inside its delimiters" do
    tokens = kinds(~S|<p :if={@user && Enum.any?(@items, &(&1 == "a"))}>|)

    assert {:assign, "@user"} in tokens
    assert {:module, "Enum"} in tokens
    assert {:string, ~S|"a"|} in tokens

    eex = kinds("<% for x <- @xs do %>")
    assert {:expr, "<%"} in eex
    assert {:keyword, "for"} in eex
    assert {:keyword, "do"} in eex
    assert {:expr, "%>"} in eex
  end

  test "the special attributes are directives, the plain ones attributes" do
    tokens =
      kinds(
        ~S|<li :for={x <- @xs} :if={x} :let={y} phx-click="go" phx-value-id="1" class="a" id="b">|
      )

    for name <- [":for", ":if", ":let", "phx-click", "phx-value-id"],
        do: assert({:directive, name} in tokens, name)

    assert {:attr, "class"} in tokens
    assert {:attr, "id"} in tokens
    refute Enum.any?(tokens, &match?({:attr, ":" <> _}, &1))
  end

  test "an expression that is cut short keeps its open delimiter and the text" do
    assert {:expr, "{"} in kinds("<a b={ @x")
    assert {:assign, "@x"} in kinds("<a b={ @x")
    refute {:expr, "}"} in kinds("<a b={ @x")
  end

  test "script and style tags are plain html tags and their body stays text" do
    tokens = kinds("<script>var a = 1 < 2</script><style>p {}</style>")

    assert {:html, "script"} in tokens
    assert {:html, "style"} in tokens

    assert Highlight.heex("<script>x</script>") |> Enum.map_join(&elem(&1, 1)) ==
             "<script>x</script>"
  end

  test "an attribute with no value before a self-closing bracket" do
    tokens = kinds("<input disabled />")

    assert {:attr, "disabled"} in tokens
    assert {:punct, "/>"} in tokens
  end

  describe "elixir/1" do
    test "the tokens put back together are the source" do
      sources = [
        "defmodule A.B do\n  @doc \"x\"\n  def f(x), do: {:ok, x} # note\nend\n",
        "~H\"\"\"\n<p>{@x}</p>\n\"\"\"",
        "a = \"open",
        "1_000.5 |> then(&(&1 + 2))",
        "é ü #hash"
      ]

      for source <- sources,
          do: assert(Highlight.elixir(source) |> Enum.map_join(&elem(&1, 1)) == source)
    end

    test "tells apart keywords, modules, atoms, keys, numbers, strings, comments and assigns" do
      tokens =
        for {kind, text} <- Highlight.elixir("if @x, do: Foo.Bar.run(:ok, 12, \"s\") # c"),
            kind != :text,
            do: {kind, text}

      assert {:keyword, "if"} in tokens
      assert {:assign, "@x"} in tokens
      assert {:atom, "do:"} in tokens
      assert {:module, "Foo.Bar"} in tokens
      assert {:atom, ":ok"} in tokens
      assert {:number, "12"} in tokens
      assert {:string, ~S|"s"|} in tokens
      assert {:comment, "# c"} in tokens
    end

    test "a word that only starts like a keyword is not one" do
      assert Highlight.elixir("endpoint doing") == [{:text, "endpoint doing"}]
    end

    test "an escaped quote stays inside the string" do
      assert {:string, ~S|"a \" b"|} in Highlight.elixir(~S|"a \" b" + 1|)
    end
  end

  describe "lines/1" do
    test "cuts the tokens at the breaks and drops the breaks" do
      tokens = Highlight.heex("<p>\n  a\n</p>")

      assert [[{:punct, "<"}, {:html, "p"}, {:punct, ">"}], [{:text, "  a"}], [_, _, _]] =
               Highlight.lines(tokens)
    end

    test "a token that spans lines is split, and empty lines stay" do
      assert Highlight.lines([{:comment, "a\n\nb"}]) == [
               [{:comment, "a"}],
               [],
               [{:comment, "b"}]
             ]
    end

    test "a final break does not make an extra line" do
      assert length(Highlight.lines([{:text, "a\nb\n"}])) == 2
      assert Highlight.lines([]) == [[]]
    end
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

  test "any source round-trips, even with every construct together" do
    source = """
    <!-- c --><.form :let={f} for={@form} phx-submit="save" class='a b'>
      <%!-- n --%><%= if @x do %>{@y}<% end %>
      <script>if (a < b) {}</script><input disabled/>
    </.form>
    """

    assert Highlight.heex(source) |> Enum.map_join(&elem(&1, 1)) == source
    assert Highlight.heex(source) |> Highlight.lines() |> length() == 4
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

    test "a directive has its own colour on the dark block" do
      assigns = %{code: ~S|<li :for={x <- @xs} phx-click="a" class="b">|}

      html = rendered_to_string(~H|<CodeBlock.code_block lang={:heex} code={@code} />|)

      assert html =~ ~s(<span class="text-[#C4A7E7]">:for</span>)
      assert html =~ ~s(<span class="text-[#C4A7E7]">phx-click</span>)
      assert html =~ ~s(<span class="text-[#9CA3AF]">class</span>)
      assert html =~ ~s(<span class="text-[#A3B35A]">@xs</span>)
    end

    test "lang: :elixir colours Elixir" do
      assigns = %{code: "def f(x), do: {:ok, x}"}

      html = rendered_to_string(~H|<CodeBlock.code_block lang={:elixir} code={@code} />|)

      assert html =~ ~s(<span class="text-[#C4A7E7]">def</span>)
      assert html =~ ~s(<span class="text-[#E3A72F]">:ok</span>)
    end

    test "the tinted tones colour from the tone, not the dark palette" do
      assigns = %{code: ~S|<.a :if={@x} b="c">|}

      html =
        rendered_to_string(~H|<CodeBlock.code_block tone={:risk} lang={:heex} code={@code} />|)

      assert html =~ "text-tag-info-text"
      assert html =~ "text-learning"
      refute html =~ "text-[#7AA2F7]"
      refute html =~ "text-[#E4E4E7]\"><"
    end

    test "without a lang the code stays plain" do
      assigns = %{code: "<.tab>"}

      html = rendered_to_string(~H|<CodeBlock.code_block code={@code} />|)

      refute html =~ "<span class=\"text-"
      assert html =~ "&lt;.tab&gt;"
    end
  end
end
