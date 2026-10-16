defmodule DevactionUI.Pagination do
  @moduledoc """
  Page links: previous, a window of numbers around the current one with the first and last page and an
  ellipsis where it skips, and next.

  `path` is a function from a page number to the URL of that page. `kind` says how the link goes there:
  `:patch` (the default, inside the same LiveView), `:navigate` (to another LiveView) or `:href` (a plain
  link, for a controller page). A `page` outside `1..pages` is clamped into it, so the current page never
  disappears. The previous and next links carry a 14px chevron (inline SVG, mirrored on a right-to-left page)
  that the `previous_icon` and `next_icon` slots replace.

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

  attr :size, :atom,
    values: [:md, :sm],
    default: :md,
    doc: "`:md` cells are 38px, `:sm` cells 30px (the page footer of a data table)"

  attr :class, :any, default: nil

  attr :total, :integer,
    default: nil,
    doc: "how many items there are; with `per_page` and `summary_label` the range is drawn"

  attr :per_page, :integer, default: nil
  attr :noun, :string, default: nil, doc: "what the items are, for `__NOUN__` in `summary_label`"

  attr :summary_label, :string,
    default: nil,
    doc: "the range, e.g. `__FROM__–__TO__ of __TOTAL__ __NOUN__`"

  attr :rest, :global
  slot :previous_icon, doc: "replaces the 14px chevron of the previous link"
  slot :next_icon, doc: "replaces the 14px chevron of the next link"

  @doc "The range of the page (with `total`, `per_page` and `summary_label`) and the page links."
  @spec pagination(map()) :: Phoenix.LiveView.Rendered.t()
  def pagination(assigns) do
    assigns = assign(assigns, :range, range(assigns))

    ~H"""
    <span :if={@range} data-pagination-summary>{@range}</span>
    <.links
      page={@page}
      pages={@pages}
      path={@path}
      kind={@kind}
      label={@label}
      previous={@previous}
      next={@next}
      size={@size}
      class={@class}
      rest={@rest}
      previous_icon={@previous_icon}
      next_icon={@next_icon}
    />
    """
  end

  @doc "The text of the range, or nil without the data to draw one."
  @spec range(map()) :: String.t() | nil
  def range(%{total: total, per_page: per_page, summary_label: label} = assigns)
      when is_integer(total) and is_integer(per_page) and is_binary(label) do
    page = clamp(assigns.page, max(ceil(total / per_page), 1))

    label
    |> String.replace("__FROM__", to_string(min((page - 1) * per_page + 1, total)))
    |> String.replace("__TO__", to_string(min(page * per_page, total)))
    |> String.replace("__TOTAL__", to_string(total))
    |> String.replace("__NOUN__", to_string(assigns.noun))
  end

  def range(_assigns), do: nil

  defp links(%{pages: pages} = assigns) when pages > 1 do
    page = clamp(assigns.page, pages)
    assigns = assign(assigns, page: page, entries: entries(page, pages))

    ~H"""
    <nav aria-label={@label} class={["flex items-center gap-1", @class]} {@rest}>
      <.link
        :if={@page > 1}
        {link_attrs(@kind, @path.(@page - 1))}
        aria-label={@previous}
        class={[cell(@size), "border border-line bg-card text-ink hover:bg-wrap"]}
      >
        <span aria-hidden="true">{render_slot(@previous_icon) || chevron(:previous)}</span>
      </.link>
      <%= for entry <- @entries do %>
        <span
          :if={entry == :gap}
          class={["flex w-6 items-center justify-center text-muted", gap_height(@size)]}
          aria-hidden="true"
        >
          …
        </span>
        <.link
          :if={entry != :gap}
          {link_attrs(@kind, @path.(entry))}
          aria-current={entry == @page && "page"}
          class={[
            cell(@size),
            (entry == @page && "border-ink bg-ink text-on-primary") ||
              "border-line bg-card text-ink hover:bg-wrap"
          ]}
        >
          {entry}
        </.link>
      <% end %>
      <.link
        :if={@page < @pages}
        {link_attrs(@kind, @path.(@page + 1))}
        aria-label={@next}
        class={[cell(@size), "border border-line bg-card text-ink hover:bg-wrap"]}
      >
        <span aria-hidden="true">{render_slot(@next_icon) || chevron(:next)}</span>
      </.link>
    </nav>
    """
  end

  defp links(assigns), do: ~H""

  defp chevron(direction) do
    assigns = %{path: chevron_path(direction)}

    ~H"""
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="2"
      stroke-linecap="round"
      stroke-linejoin="round"
      class="size-3.5 rtl:-scale-x-100"
    >
      <path d={@path} />
    </svg>
    """
  end

  defp chevron_path(:previous), do: "m15 6-6 6 6 6"
  defp chevron_path(:next), do: "m9 6 6 6-6 6"

  defp cell(size),
    do: [
      "flex items-center justify-center border text-sm no-underline",
      cell_size(size)
    ]

  defp cell_size(:md), do: "size-[38px] rounded-[10px]"
  defp cell_size(:sm), do: "size-[30px] rounded-lg text-[13px]"

  defp gap_height(:md), do: "h-[38px]"
  defp gap_height(:sm), do: "h-[30px]"

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
