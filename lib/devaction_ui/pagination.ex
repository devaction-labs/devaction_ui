defmodule DevactionUI.Pagination do
  @moduledoc """
  Page links: previous, a window of numbers around the current one with the first and last page and an
  ellipsis where it skips, and next.

  `path` is a function from a page number to the URL of that page. `kind` says how the link goes there:
  `:patch` (the default, inside the same LiveView), `:navigate` (to another LiveView) or `:href` (a plain
  link, for a controller page). A `page` outside `1..pages` is clamped into it, so the current page never
  disappears.

      <.pagination
        page={@page}
        pages={@pages}
        path={&~p"/pull-requests?page=\#{&1}"}
        label="Pages"
        previous="Previous page"
        next="Next page"
      >
        <:previous_icon><.icon name="arrow-left" class="size-3.5" /></:previous_icon>
        <:next_icon><.icon name="arrow-right" class="size-3.5" /></:next_icon>
      </.pagination>
  """
  use Phoenix.Component

  attr :page, :integer, required: true, doc: "the current page, clamped into `1..pages`"

  attr :pages, :integer,
    required: true,
    doc: "how many pages there are; with one or none nothing is drawn"

  attr :path, :any, required: true, doc: "a function: page number -> URL of that page"

  attr :kind, :atom,
    values: [:patch, :navigate, :href],
    default: :patch,
    doc: "how the links go to a page"

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

  @doc "The page links, or nothing when there is a single page."
  @spec pagination(map()) :: Phoenix.LiveView.Rendered.t()
  def pagination(%{pages: pages} = assigns) when pages > 1 do
    page = clamp(assigns.page, pages)
    assigns = assign(assigns, page: page, entries: entries(page, pages))

    ~H"""
    <nav aria-label={@label} class={["flex items-center gap-1", @class]} {@rest}>
      <.link
        :if={@page > 1}
        {link_attrs(@kind, @path.(@page - 1))}
        aria-label={@previous}
        class={[cell(), "border border-line-strong bg-card text-ink"]}
      >
        <span aria-hidden="true">{render_slot(@previous_icon) || "‹"}</span>
      </.link>
      <%= for entry <- @entries do %>
        <span
          :if={entry == :gap}
          class="flex h-[38px] w-6 items-center justify-center text-muted"
          aria-hidden="true"
        >
          …
        </span>
        <.link
          :if={entry != :gap}
          {link_attrs(@kind, @path.(entry))}
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
        {link_attrs(@kind, @path.(@page + 1))}
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
    do: "flex size-[38px] items-center justify-center rounded-[10px] text-sm no-underline"

  defp link_attrs(:patch, url), do: [patch: url]
  defp link_attrs(:navigate, url), do: [navigate: url]
  defp link_attrs(:href, url), do: [href: url]

  defp clamp(page, pages), do: page |> max(1) |> min(pages)

  @doc "The page numbers to draw, with `:gap` where pages are skipped: always the first, the last and one on each side of the current. A `page` outside `1..pages` is clamped into it."
  @spec entries(integer(), pos_integer()) :: [pos_integer() | :gap]
  def entries(page, pages) do
    current = clamp(page, pages)

    wanted =
      Enum.uniq([1, current - 1, current, current + 1, pages])
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
