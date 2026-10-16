defmodule DevactionUI.Highlight do
  @moduledoc """
  Splits HEEx source into tokens a code block can colour: `{kind, text}` pairs whose texts, joined, are the
  source again. It reads the shapes of a template (tags, components, slots, attributes, strings in single or
  double quotes, `{}` and `<% %>` expressions, `<!-- -->` and `<%!-- --%>` comments), not the Elixir inside
  them, so it is cheap and never fails: what it does not know, or what is cut short, is plain `:text`.
  It only knows HEEx: it is what `CodeBlock` runs for `lang: :heex`.

  Kinds: `:punct`, `:html`, `:component`, `:slot`, `:attr`, `:string`, `:expr`, `:comment`, `:text`.
  """

  @type kind :: :punct | :html | :component | :slot | :attr | :string | :expr | :comment | :text

  @tag_name ~r/\A\/?[.:A-Za-z][\w.:\-]*/
  @attr_name ~r/\A[\w:@.\-\[\]]+/
  @string ~r/\A(?:"[^"]*"|'[^']*')/

  @doc "The tokens of a HEEx source."
  @spec heex(String.t()) :: [{kind(), String.t()}]
  def heex(source), do: source |> scan([]) |> Enum.reverse() |> merge([])

  defp scan("", acc), do: acc
  defp scan("<!--" <> _ = rest, acc), do: until(rest, "-->", :comment, acc)
  defp scan("<%!--" <> _ = rest, acc), do: until(rest, "--%>", :comment, acc)
  defp scan("<%" <> _ = rest, acc), do: until(rest, "%>", :expr, acc)
  defp scan("{" <> _ = rest, acc), do: braces(rest, :expr, acc)

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
  defp attributes("{" <> _ = rest, acc), do: braces(rest, :expr, acc, &attributes/2)

  defp attributes(<<space, rest::binary>>, acc) when space in [?\s, ?\n, ?\t, ?\r],
    do: attributes(rest, [{:text, <<space>>} | acc])

  defp attributes("", acc), do: acc

  defp attributes(rest, acc) do
    case {Regex.run(@string, rest), Regex.run(@attr_name, rest)} do
      {[string], _} -> attributes(drop(rest, string), [{:string, string} | acc])
      {nil, [name]} -> attributes(drop(rest, name), [{:attr, name} | acc])
      {nil, nil} -> scan(rest, acc)
    end
  end

  defp until(rest, closing, kind, acc) do
    case :binary.match(rest, closing) do
      {at, size} ->
        length = at + size

        scan(drop(rest, binary_part(rest, 0, length)), [
          {kind, binary_part(rest, 0, length)} | acc
        ])

      :nomatch ->
        scan("", [{kind, rest} | acc])
    end
  end

  defp braces(rest, kind, acc, next \\ &scan/2) do
    {expression, remaining} = balanced(rest, 0, [])
    next.(remaining, [{kind, expression} | acc])
  end

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
