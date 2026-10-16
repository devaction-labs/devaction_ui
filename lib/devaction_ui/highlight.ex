defmodule DevactionUI.Highlight do
  @moduledoc """
  Splits HEEx or Elixir source into tokens a code block can colour: `{kind, text}` pairs whose texts, joined,
  are the source again. It is cheap and never fails: what it does not know, or what is cut short, is plain
  `:text`.

  `heex/1` reads the shapes of a template (tags, components, slots, attributes, strings in single or double
  quotes, `{}` and `<% %>` expressions, `<!-- -->` and `<%!-- --%>` comments). An expression is not one piece:
  its delimiters (`{`, `}`, `<%=`, `%>`) are `:expr` and what is inside goes through `elixir/1`. The special
  attributes of HEEx (`:if`, `:for`, `:let`, `:key` and every `phx-*`) are `:directive`, apart from the plain
  `:attr`. It is what `CodeBlock` runs for `lang: :heex`.

  `elixir/1` is a small lexer, not a parser: comments, strings, atoms and keyword keys, numbers, `@assigns`,
  module names and reserved words; the rest is `:text`. Sigils, heredocs and charlists are not told apart: their
  quotes are strings and the rest of a sigil is `:text`. It is what `CodeBlock` runs for `lang: :elixir`.

  `lines/1` cuts a token list at its line breaks, for the blocks that number or mark lines.

  Kinds: `:punct`, `:html`, `:component`, `:slot`, `:attr`, `:directive`, `:string`, `:expr`, `:comment`,
  `:keyword`, `:atom`, `:number`, `:module`, `:assign` and `:text`.
  """

  @type kind ::
          :punct
          | :html
          | :component
          | :slot
          | :attr
          | :directive
          | :string
          | :expr
          | :comment
          | :keyword
          | :atom
          | :number
          | :module
          | :assign
          | :text
  @type token :: {kind(), String.t()}

  @tag_name ~r/\A\/?[.:A-Za-z][\w.:\-]*/
  @attr_name ~r/\A[\w:@.\-\[\]]+/
  @string ~r/\A(?:"[^"]*"|'[^']*')/
  @eex_open ~r/\A<%[=\/|]?/

  @keywords ~w(do end fn if else unless case cond when with for in and or not nil true false
               def defp defmodule defmacro import alias use require raise try rescue catch after receive)

  @elixir_rules [
    {~r/\A#[^\n]*/, :comment},
    {~r/\A"(?:[^"\\]|\\.)*"?/s, :string},
    {~r/\A:"(?:[^"\\]|\\.)*"?/s, :atom},
    {~r/\A:[A-Za-z_][\w@]*[?!]?/, :atom},
    {~r/\A[A-Za-z_]\w*[?!]?:(?!:)/, :atom},
    {~r/\A@[a-z_]\w*/, :assign},
    {~r/\A\d[\d_]*(?:\.\d+)?/, :number},
    {~r/\A[A-Z]\w*(?:\.[A-Z]\w*)*/, :module},
    {~r/\A[A-Za-z_]\w*[?!]?/, :word}
  ]

  @doc "The tokens of a HEEx source."
  @spec heex(String.t()) :: [token()]
  def heex(source), do: source |> scan([]) |> Enum.reverse() |> merge([])

  @doc "The tokens of an Elixir source."
  @spec elixir(String.t()) :: [token()]
  def elixir(source), do: source |> lex([]) |> Enum.reverse() |> merge([])

  @doc "The tokens cut at their line breaks: a list of lines, each a list of tokens, without the breaks."
  @spec lines([token()]) :: [[token()]]
  def lines(tokens) do
    tokens
    |> Enum.reduce([[]], &split_token/2)
    |> without_final_break()
    |> Enum.reverse()
    |> Enum.map(&Enum.reverse/1)
  end

  defp split_token({kind, text}, acc) do
    [first | more] = String.split(text, "\n")
    Enum.reduce(more, push(acc, kind, first), &push([[] | &2], kind, &1))
  end

  defp push(acc, _kind, ""), do: acc
  defp push([line | rest], kind, text), do: [[{kind, text} | line] | rest]

  defp without_final_break([[], _line | _] = reversed), do: tl(reversed)
  defp without_final_break(reversed), do: reversed

  defp lex("", acc), do: acc

  defp lex(<<char::utf8, rest::binary>> = source, acc) do
    case Enum.find_value(@elixir_rules, &lexeme(&1, source)) do
      {kind, token} -> lex(drop(source, token), [{word(kind, token), token} | acc])
      nil -> lex(rest, [{:text, <<char::utf8>>} | acc])
    end
  end

  defp lexeme({regex, kind}, source) do
    case Regex.run(regex, source) do
      [token] -> {kind, token}
      nil -> nil
    end
  end

  defp word(:word, token) when token in @keywords, do: :keyword
  defp word(:word, _token), do: :text
  defp word(kind, _token), do: kind

  defp scan("", acc), do: acc
  defp scan("<!--" <> _ = rest, acc), do: until(rest, "-->", :comment, acc)
  defp scan("<%!--" <> _ = rest, acc), do: until(rest, "--%>", :comment, acc)
  defp scan("<%" <> _ = rest, acc), do: until(rest, "%>", :eex, acc)
  defp scan("{" <> _ = rest, acc), do: braces(rest, acc)

  defp scan("<" <> rest = source, acc) do
    case Regex.run(@tag_name, rest) do
      [name] ->
        name |> tag_name(rest, acc) |> then(fn {remaining, acc} -> attributes(remaining, acc) end)

      nil ->
        plain(source, acc)
    end
  end

  defp scan(source, acc), do: plain(source, acc)

  defp plain(<<char::utf8, rest::binary>>, acc), do: scan(rest, [{:text, <<char::utf8>>} | acc])

  defp tag_name(name, rest, acc) do
    {slash, bare} = split_slash(name)
    remaining = binary_part(rest, byte_size(name), byte_size(rest) - byte_size(name))
    acc = [{name_kind(bare), bare}, {:punct, "<" <> slash} | acc]
    {remaining, acc}
  end

  defp split_slash("/" <> bare), do: {"/", bare}
  defp split_slash(bare), do: {"", bare}

  defp name_kind("." <> _), do: :component
  defp name_kind(":" <> _), do: :slot

  defp name_kind(<<first, _::binary>> = name) when first in ?A..?Z,
    do: qualified(String.contains?(name, "."))

  defp name_kind(_name), do: :html

  defp qualified(true), do: :component
  defp qualified(false), do: :html

  defp attributes("/>" <> rest, acc), do: scan(rest, [{:punct, "/>"} | acc])
  defp attributes(">" <> rest, acc), do: scan(rest, [{:punct, ">"} | acc])
  defp attributes("=" <> rest, acc), do: attributes(rest, [{:punct, "="} | acc])
  defp attributes("{" <> _ = rest, acc), do: braces(rest, acc, &attributes/2)

  defp attributes(<<space, rest::binary>>, acc) when space in [?\s, ?\n, ?\t, ?\r],
    do: attributes(rest, [{:text, <<space>>} | acc])

  defp attributes("", acc), do: acc

  defp attributes(rest, acc) do
    case {Regex.run(@string, rest), Regex.run(@attr_name, rest)} do
      {[string], _} -> attributes(drop(rest, string), [{:string, string} | acc])
      {nil, [name]} -> attributes(drop(rest, name), [{attr_kind(name), name} | acc])
      {nil, nil} -> scan(rest, acc)
    end
  end

  defp attr_kind(":" <> _), do: :directive
  defp attr_kind("phx-" <> _), do: :directive
  defp attr_kind(_name), do: :attr

  defp until(rest, closing, kind, acc) do
    case :binary.match(rest, closing) do
      {at, size} ->
        taken = binary_part(rest, 0, at + size)
        scan(drop(rest, taken), put(kind, taken, acc))

      :nomatch ->
        scan("", put(kind, rest, acc))
    end
  end

  defp braces(rest, acc, next \\ &scan/2) do
    {expression, remaining} = balanced(rest, 0, [])
    next.(remaining, expression("{", "}", expression, acc))
  end

  defp put(:eex, text, acc) do
    [open] = Regex.run(@eex_open, text)
    expression(open, "%>", text, acc)
  end

  defp put(kind, text, acc), do: [{kind, text} | acc]

  defp expression(open, close, text, acc) do
    body = binary_part(text, byte_size(open), byte_size(text) - byte_size(open))
    {inner, closing} = split_closing(body, close)
    Enum.reverse([{:expr, open} | elixir(inner)] ++ closing, acc)
  end

  defp split_closing(body, close), do: split_closing(body, close, String.ends_with?(body, close))

  defp split_closing(body, close, true),
    do: {binary_part(body, 0, byte_size(body) - byte_size(close)), [{:expr, close}]}

  defp split_closing(body, _close, false), do: {body, []}

  defp balanced("", _depth, taken), do: {taken |> Enum.reverse() |> IO.iodata_to_binary(), ""}

  defp balanced(<<char::utf8, rest::binary>>, depth, taken) do
    case {char, depth} do
      {?{, _} -> balanced(rest, depth + 1, [<<char::utf8>> | taken])
      {?}, 1} -> {[<<char::utf8>> | taken] |> Enum.reverse() |> IO.iodata_to_binary(), rest}
      {?}, _} -> balanced(rest, depth - 1, [<<char::utf8>> | taken])
      _other -> balanced(rest, depth, [<<char::utf8>> | taken])
    end
  end

  defp drop(source, taken),
    do: binary_part(source, byte_size(taken), byte_size(source) - byte_size(taken))

  defp merge([], acc), do: Enum.reverse(acc)

  defp merge([{kind, text}, {kind, more} | rest], acc) when kind in [:text],
    do: merge([{kind, text <> more} | rest], acc)

  defp merge([token | rest], acc), do: merge(rest, [token | acc])
end
