defmodule DevactionUI.Pagination do
  @moduledoc """
  Page links: previous, a window of numbers around the current one with the first and last page and an
  ellipsis where it skips, and next. `path` is a function from a page number to the URL (or `patch` target).
  """
  use Phoenix.Component

  attr :page, :integer, required: true
  attr :pages, :integer, required: true
  attr :path, :any, required: true, doc: "a function: page number -> path"

  attr :label, :string,
    required: true,
    doc: "the name of the navigation, for assistive technology"

  attr :previous, :string,
    required: true,
    doc: "text for the previous link, for assistive technology"

  attr :next, :string, required: true, doc: "text for the next link, for assistive technology"
  attr :class, :any, default: nil

  attr :rest, :global
  slot :previous_icon, doc: "replaces the typographic ‹"
  slot :next_icon, doc: "replaces the typographic ›"

  def pagination(%{pages: pages} = assigns) when pages > 1 do
    assigns = assign(assigns, :entries, entries(assigns.page, assigns.pages))

    ~H"""
    <nav aria-label={@label} class={["flex items-center gap-1.5", @class]} {@rest}>
      <.link
        :if={@page > 1}
        patch={@path.(@page - 1)}
        aria-label={@previous}
        class={[cell(), "border border-line-strong bg-card text-ink"]}
      >
        <span aria-hidden="true">{render_slot(@previous_icon) || "‹"}</span>
      </.link>
      <%= for entry <- @entries do %>
        <span :if={entry == :gap} class="px-1 text-muted" aria-hidden="true">…</span>
        <.link
          :if={entry != :gap}
          patch={@path.(entry)}
          aria-current={entry == @page && "page"}
          class={[
            cell(),
            (entry == @page && "bg-ink text-on-primary") || "text-ink-2 hover:bg-wrap"
          ]}
        >
          {entry}
        </.link>
      <% end %>
      <.link
        :if={@page < @pages}
        patch={@path.(@page + 1)}
        aria-label={@next}
        class={[cell(), "border border-line-strong bg-card text-ink"]}
      >
        <span aria-hidden="true">{render_slot(@next_icon) || "›"}</span>
      </.link>
    </nav>
    """
  end

  def pagination(assigns), do: ~H""

  defp cell,
    do: "flex size-10 items-center justify-center rounded-[10px] text-sm no-underline"

  @doc "The page numbers to draw, with `:gap` where pages are skipped: always the first, the last and one on each side of the current."
  @spec entries(pos_integer(), pos_integer()) :: [pos_integer() | :gap]
  def entries(page, pages) do
    wanted =
      Enum.uniq([1, page - 1, page, page + 1, pages])
      |> Enum.filter(&(&1 in 1..pages//1))
      |> Enum.sort()

    wanted
    |> Enum.chunk_every(2, 1)
    |> Enum.flat_map(fn
      [a, b] when b - a > 1 -> [a, :gap]
      [a, _b] -> [a]
      [a] -> [a]
    end)
  end
end
