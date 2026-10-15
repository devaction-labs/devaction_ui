defmodule DevactionUISite.Doc do
  @moduledoc """
  Renders the small subset of Markdown the `@moduledoc`s and `doc:` options use: paragraphs, bullet lists,
  indented or fenced code, and inline `code` and **bold**. Everything is escaped first, so a doc can never
  inject markup.
  """
  use Phoenix.Component

  alias DevactionUI.CodeBlock

  attr :text, :string, default: nil

  def markdown(%{text: nil} = assigns), do: ~H""

  def markdown(assigns) do
    assigns = assign(assigns, :blocks, assigns.text |> String.trim() |> blocks())

    ~H"""
    <div class="flex flex-col gap-3 text-[15px] leading-relaxed text-ink-2">
      <.block :for={block <- @blocks} block={block} />
    </div>
    """
  end

  attr :text, :string, required: true

  def inline(assigns) do
    ~H"{inline_html(@text)}"
  end

  defp block(%{block: {:code, code}} = assigns) do
    assigns = assign(assigns, :code, code)
    ~H"<CodeBlock.code_block tone={:dark} code={@code} />"
  end

  defp block(%{block: {:list, items}} = assigns) do
    assigns = assign(assigns, :items, items)

    ~H"""
    <ul class="m-0 flex list-disc flex-col gap-1.5 pl-5">
      <li :for={item <- @items}>{inline_html(item)}</li>
    </ul>
    """
  end

  defp block(%{block: {:heading, text}} = assigns) do
    assigns = assign(assigns, :text, text)
    ~H|<h4 class="m-0 mt-2 text-base font-semibold text-ink">{inline_html(@text)}</h4>|
  end

  defp block(%{block: {:paragraph, text}} = assigns) do
    assigns = assign(assigns, :text, text)
    ~H|<p class="m-0">{inline_html(@text)}</p>|
  end

  defp blocks(text) do
    text
    |> String.split(~r/\n{2,}/)
    |> Enum.map(&classify/1)
  end

  defp classify("```" <> _ = fenced) do
    code = fenced |> String.split("\n") |> Enum.drop(1) |> Enum.reject(&(&1 == "```"))
    {:code, Enum.join(code, "\n")}
  end

  defp classify("#" <> _ = heading), do: {:heading, String.trim_leading(heading, "# ")}

  defp classify(chunk) do
    lines = String.split(chunk, "\n")

    cond do
      Enum.all?(lines, &String.starts_with?(&1, "    ")) -> {:code, dedent(lines)}
      Enum.all?(lines, &bullet?/1) -> {:list, Enum.map(lines, &strip_bullet/1)}
      true -> {:paragraph, chunk |> String.replace("\n", " ")}
    end
  end

  defp dedent(lines),
    do: lines |> Enum.map(&String.replace_prefix(&1, "    ", "")) |> Enum.join("\n")

  defp bullet?(line), do: String.starts_with?(line, "- ") or String.starts_with?(line, "* ")
  defp strip_bullet(line), do: String.slice(line, 2..-1//1)

  defp inline_html(text) do
    text
    |> Phoenix.HTML.html_escape()
    |> Phoenix.HTML.safe_to_string()
    |> then(
      &Regex.replace(
        ~r/`([^`]+)`/,
        &1,
        ~s(<code class="rounded bg-wrap px-1 font-mono text-[0.9em] text-ink">\\1</code>)
      )
    )
    |> then(
      &Regex.replace(
        ~r/\*\*([^*]+)\*\*/,
        &1,
        ~s(<strong class="font-semibold text-ink">\\1</strong>)
      )
    )
    |> Phoenix.HTML.raw()
  end
end
