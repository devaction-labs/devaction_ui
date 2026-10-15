defmodule DevactionUISite.Reference do
  @moduledoc """
  Reads the API of a component module off the module itself: the `attr` and `slot` declarations that
  `Phoenix.Component` keeps in `__components__/0`, and the docs the compiler stored. The reference pages are
  built from this, so a table can never say something the code does not.
  """

  @doc "The module's `@moduledoc`, or `nil`."
  def moduledoc(module) do
    case Code.fetch_docs(module) do
      {:docs_v1, _anno, _lang, _format, %{"en" => doc}, _meta, _entries} -> doc
      _none -> nil
    end
  end

  @doc "The first sentence of the module's documentation, with its markup taken out."
  def summary(module) do
    module
    |> moduledoc()
    |> first_sentence()
  end

  defp first_sentence(nil), do: ""

  defp first_sentence(doc) do
    doc
    |> String.split(~r/\n\s*\n/, parts: 2)
    |> hd()
    |> String.replace("\n", " ")
    |> String.replace(["`", "**"], "")
    |> then(&Regex.run(~r/\A.*?[.!?](?=\s|\z)/su, &1))
    |> sentence_or_whole(doc)
  end

  defp sentence_or_whole([sentence], _doc), do: sentence |> String.trim() |> shorten()

  defp sentence_or_whole(nil, doc),
    do: doc |> String.split("\n", parts: 2) |> hd() |> String.trim() |> shorten()

  @summary_length 150

  defp shorten(text) when byte_size(text) <= @summary_length, do: text

  defp shorten(text) do
    cut = text |> String.slice(0, @summary_length) |> String.replace(~r/[\s,;:(]+\S*\z/u, "")
    cut <> "…"
  end

  @doc "The function components of a module in source order, each with its attrs, slots and doc."
  def components(module) do
    docs = function_docs(module)

    module.__components__()
    |> Enum.map(fn {name, component} ->
      %{
        name: name,
        line: component.line,
        doc: Map.get(docs, name),
        attrs:
          component.attrs
          |> Enum.reject(&(&1.type == :global))
          |> Enum.sort_by(& &1.line)
          |> Enum.map(&normalize_attr/1),
        globals: component.attrs |> Enum.filter(&(&1.type == :global)) |> Enum.map(&global/1),
        slots: Enum.map(component.slots, &normalize_slot/1)
      }
    end)
    |> Enum.sort_by(& &1.line)
  end

  @doc "A short module name as it is written in a template: `DevactionUI.Tag` is `Tag`."
  def short(module), do: module |> Module.split() |> List.last()

  @doc "A minimal, valid usage of a component: only what it requires."
  def usage(module, %{name: name, attrs: attrs, slots: slots}) do
    tag = "#{short(module)}.#{name}"
    required = Enum.filter(attrs, & &1.required)
    inner = Enum.find(slots, &(&1.name == :inner_block and &1.required))
    named = Enum.filter(slots, &(&1.required and &1.name != :inner_block))
    open = Enum.map_join(required, "", &" #{&1.name}=#{placeholder(&1)}")
    body(tag, open, inner, named)
  end

  @doc "How a type reads in a table."
  def type_label({:fun, arity}), do: "function/#{arity}"
  def type_label({:list, type}), do: "list of #{type_label(type)}"
  def type_label(type) when is_atom(type), do: type |> inspect() |> String.trim_leading(":")
  def type_label(type), do: inspect(type)

  @doc "The default of an attr as source, or `nil` when it has none."
  def default(%{default: {:ok, value}}), do: inspect(value)
  def default(_attr), do: nil

  defp body(tag, open, nil, []), do: "<#{tag}#{open} />"

  defp body(tag, open, inner, named) do
    inner_lines = inner_lines(inner)
    named_lines = Enum.map(named, &"  <:#{&1.name}>...</:#{&1.name}>")
    Enum.join(["<#{tag}#{open}>" | inner_lines ++ named_lines] ++ ["</#{tag}>"], "\n")
  end

  defp inner_lines(nil), do: []
  defp inner_lines(_inner), do: ["  ..."]

  defp normalize_attr(attr) do
    opts = attr.opts

    %{
      name: attr.name,
      type: attr.type,
      required: attr.required,
      default: Keyword.fetch(opts, :default),
      values: Keyword.get(opts, :values),
      examples: Keyword.get(opts, :examples),
      doc: Map.get(attr, :doc) || Keyword.get(opts, :doc)
    }
  end

  defp global(attr), do: %{name: attr.name, include: Keyword.get(attr.opts, :include, [])}

  defp normalize_slot(slot) do
    %{
      name: slot.name,
      required: slot.required,
      doc: slot.doc,
      attrs: slot.attrs |> Enum.sort_by(& &1.line) |> Enum.map(&normalize_attr/1)
    }
  end

  defp function_docs(module) do
    case Code.fetch_docs(module) do
      {:docs_v1, _anno, _lang, _format, _moduledoc, _meta, entries} ->
        for {{:function, name, 1}, _anno, _sig, %{"en" => doc}, _meta} <- entries,
            written = written_part(doc),
            into: %{},
            do: {name, written}

      _none ->
        %{}
    end
  end

  defp written_part(doc) do
    doc
    |> String.split(~r/\n*## (?:Attributes|Slots)/, parts: 2)
    |> hd()
    |> String.trim()
    |> nil_if_blank()
  end

  defp nil_if_blank(""), do: nil
  defp nil_if_blank(text), do: text

  defp placeholder(%{type: :string}), do: ~s("...")
  defp placeholder(%{type: :atom, values: [first | _]}), do: "{#{inspect(first)}}"
  defp placeholder(%{type: :atom}), do: "{:atom}"
  defp placeholder(%{type: :integer}), do: "{0}"
  defp placeholder(%{type: :float}), do: "{0.0}"
  defp placeholder(%{type: :boolean}), do: "{true}"
  defp placeholder(%{type: :list}), do: "{[]}"
  defp placeholder(%{type: :map}), do: "{%{}}"
  defp placeholder(%{type: {:fun, _arity}}), do: "{&handler/1}"
  defp placeholder(%{type: Phoenix.LiveView.JS}), do: ~s|{JS.push("event")}|
  defp placeholder(%{name: name}), do: "{@#{name}}"
end
