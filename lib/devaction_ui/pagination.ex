defmodule DevactionUI.Pagination do
  @moduledoc """
  Page links: previous, a window of numbers around the current one with the first and last page and an
  ellipsis where it skips, and next.

  `path` is a function from a page number to the URL of that page. `kind` says how the link goes there:
  `:patch` (the default, inside the same LiveView), `:navigate` (to another LiveView) or `:href` (a plain
  link, for a controller page). A `page` outside `1..pages` is clamped into it, so the current page never
  disappears. The previous and next links carry a 14px chevron (inline SVG, mirrored on a right-to-left page)
  that the `previous_icon` and `next_icon` slots replace. On the first page the previous control stays, dimmed
  and `aria-disabled` and not a link (and the same for next on the last), so the row does not change width as
  the person pages. `size: :sm` draws 30px cells for the footer of a table.

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
    doc: "the cells are 38px, or 30px (`:sm`) for the footer of a table"

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
      <.step
        target={target(@page, @pages, :previous)}
        kind={@kind}
        path={@path}
        label={@previous}
        size={@size}
        icon={render_slot(@previous_icon) || chevron(:previous)}
      />
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
            (entry == @page && "bg-ink text-on-primary") || "text-ink-2 hover:bg-wrap"
          ]}
        >
          {entry}
        </.link>
      <% end %>
      <.step
        target={target(@page, @pages, :next)}
        kind={@kind}
        path={@path}
        label={@next}
        size={@size}
        icon={render_slot(@next_icon) || chevron(:next)}
      />
    </nav>
    """
  end

  defp links(assigns), do: ~H""

  attr :target, :any, required: true
  attr :kind, :atom, required: true
  attr :path, :any, required: true
  attr :label, :string, required: true
  attr :size, :atom, required: true
  attr :icon, :any, required: true

  defp step(%{target: nil} = assigns) do
    ~H"""
    <span
      role="link"
      aria-disabled="true"
      aria-label={@label}
      class={[cell(@size), "border border-line-strong bg-card text-ink opacity-40"]}
    >
      <span aria-hidden="true">{@icon}</span>
    </span>
    """
  end

  defp step(assigns) do
    ~H"""
    <.link
      {link_attrs(@kind, @path.(@target))}
      aria-label={@label}
      class={[cell(@size), "border border-line-strong bg-card text-ink"]}
    >
      <span aria-hidden="true">{@icon}</span>
    </.link>
    """
  end

  defp target(page, _pages, :previous) when page > 1, do: page - 1
  defp target(page, pages, :next) when page < pages, do: page + 1
  defp target(_page, _pages, _direction), do: nil

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

  defp cell(:md),
    do: "flex size-[38px] items-center justify-center rounded-[10px] text-sm no-underline"

  defp cell(:sm),
    do: "flex size-[30px] items-center justify-center rounded-lg text-[13px] no-underline"

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
