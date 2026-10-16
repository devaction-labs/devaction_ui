defmodule DevactionUI.Breadcrumb do
  @moduledoc """
  Where the page is: `Today / SGE / PR #142`. The last item is the current page and always carries
  `aria-current="page"`, whether it is a link or plain text.

  The `separator` is text (`"/"` by default) or `:chevron`, a 14px chevron that mirrors itself when the page
  is right-to-left (`dir="rtl"`); the row itself already runs from the right there. A long trail can be
  shortened with `max`: it keeps the first item and the last `max - 1`, and the ones between become a `…` that
  opens a list of them (a native `<details>` that Esc and a press outside close). Name that `…` with `collapsed_label`.

  `home` puts a link to the start of the app before the first item, drawn by the `home_icon` slot and named by
  `home_label`, which it needs (without one it raises).
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  attr :id, :string,
    default: nil,
    doc: "names the hook of the collapsed list; set it when two trails on a page share a `label`"

  attr :label, :string,
    required: true,
    doc: "the name of the navigation, for assistive technology"

  attr :items, :list,
    required: true,
    doc:
      "`%{label: ..., to: path}` each; `to` navigates to another LiveView, `patch` patches this one and `href` is a plain link. An item with none of them is plain text"

  attr :separator, :any,
    default: "/",
    doc: "the text between items, or `:chevron` for a chevron that follows the reading direction"

  attr :max, :integer,
    default: nil,
    doc:
      "how many items are drawn at most (2 or more); the first and the last `max - 1` stay, the middle collapses"

  attr :collapsed_label, :string,
    default: nil,
    doc: "the name of the `…` that holds the collapsed items; give it whenever `max` is set"

  attr :home, :string,
    default: nil,
    doc:
      "a path: the trail starts with a link to it drawn as the `home_icon`, before the first item"

  attr :home_label, :string,
    default: nil,
    doc: "names the home link; required whenever `home` is set"

  attr :underline, :boolean,
    default: true,
    doc:
      "underlines the links of the trail; `false` for the quiet trail in the header of a `Shell`"

  attr :class, :any, default: nil
  attr :rest, :global
  slot :home_icon, doc: "the icon of the home link; a typographic glyph when empty"

  @doc "The trail of pages up to the current one."
  @spec breadcrumb(map()) :: Phoenix.LiveView.Rendered.t()
  def breadcrumb(%{home: home, home_label: nil}) when is_binary(home),
    do: raise(ArgumentError, "breadcrumb: `home` needs a `home_label`")

  def breadcrumb(assigns) do
    assigns =
      assigns
      |> assign(:entries, entries(assigns.items, assigns.max, assigns.home))
      |> assign(:more_id, "#{assigns.id || "breadcrumb-#{:erlang.phash2(assigns.label)}"}-more")

    ~H"""
    <nav id={@id} aria-label={@label} class={["text-sm text-muted", @class]} {@rest}>
      <ol class="m-0 flex list-none flex-wrap items-center gap-2.5 p-0">
        <li :for={{entry, index} <- Enum.with_index(@entries)} class="flex items-center gap-2.5">
          <.separator :if={index > 0} separator={@separator} />
          <.entry
            entry={entry}
            collapsed_label={@collapsed_label}
            more_id={@more_id}
            home_label={@home_label}
            home_icon={@home_icon}
            underline={@underline}
          />
        </li>
      </ol>
    </nav>
    """
  end

  defp entries(items, max, home) do
    last = length(items) - 1
    indexed = for {item, index} <- Enum.with_index(items), do: {:crumb, item, index == last}
    start(collapse(indexed, max), home)
  end

  defp start(entries, nil), do: entries
  defp start(entries, home), do: [{:home, home} | entries]

  defp collapse(entries, max) when is_nil(max), do: entries
  defp collapse(entries, max) when length(entries) <= max, do: entries

  defp collapse([first | rest], max) do
    keep = max(max, 2) - 1
    {hidden, tail} = Enum.split(rest, length(rest) - keep)
    more = for {:crumb, item, _current} <- hidden, do: item
    [first, {:more, more} | tail]
  end

  attr :separator, :any, required: true

  defp separator(%{separator: :chevron} = assigns) do
    ~H"""
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="1.8"
      stroke-linecap="round"
      stroke-linejoin="round"
      aria-hidden="true"
      class="size-3.5 shrink-0 rtl:-scale-x-100"
    >
      <path d="m9 6 6 6-6 6" />
    </svg>
    """
  end

  defp separator(assigns) do
    ~H"""
    <span aria-hidden="true">{@separator}</span>
    """
  end

  attr :entry, :any, required: true
  attr :collapsed_label, :string, required: true
  attr :more_id, :string, required: true
  attr :home_label, :string, required: true
  attr :home_icon, :list, required: true
  attr :underline, :boolean, required: true

  defp entry(%{entry: {:home, path}} = assigns) do
    assigns = assign(assigns, :path, path)

    ~H"""
    <.link
      navigate={@path}
      aria-label={@home_label}
      class="grid size-6 place-items-center rounded-sm outline-none hover:text-ink focus-visible:ring-4 focus-visible:ring-ink/10"
    >
      <span class="size-4" aria-hidden="true">
        {(@home_icon != [] && render_slot(@home_icon)) || "⌂"}
      </span>
    </.link>
    """
  end

  defp entry(%{entry: {:crumb, item, current}} = assigns) do
    assigns = assign(assigns, item: item, current: current)

    ~H"""
    <.crumb item={@item} current={@current} underline={@underline} />
    """
  end

  defp entry(%{entry: {:more, hidden}} = assigns) do
    assigns = assign(assigns, :hidden, hidden)

    ~H"""
    <details
      id={@more_id}
      class="group relative"
      phx-hook="DevactionUI.Breadcrumb"
      phx-mounted={JS.ignore_attributes(["open"])}
    >
      <summary
        aria-label={@collapsed_label}
        class="flex h-6 min-w-6 cursor-pointer list-none items-center justify-center rounded-sm outline-none marker:hidden hover:text-ink focus-visible:ring-4 focus-visible:ring-ink/10 [&::-webkit-details-marker]:hidden"
      >
        <span aria-hidden="true">…</span>
      </summary>
      <ol class="absolute start-0 z-40 mt-1.5 flex min-w-40 list-none flex-col gap-1 rounded-[14px] border border-line bg-card p-2 shadow-pop">
        <li :for={item <- @hidden}>
          <.crumb item={item} current={false} underline={@underline} />
        </li>
      </ol>
    </details>
    """
  end

  attr :item, :map, required: true
  attr :current, :boolean, required: true
  attr :underline, :boolean, required: true

  defp crumb(assigns) do
    assigns = assign(assigns, :link, link_attrs(assigns.item))

    ~H"""
    <.link
      :if={@link}
      {@link}
      aria-current={@current && "page"}
      class={[
        "rounded-sm outline-none hover:text-ink focus-visible:ring-4 focus-visible:ring-ink/10",
        @underline && "underline underline-offset-2",
        (@current && "text-ink") || "text-muted"
      ]}
    >
      {@item.label}
    </.link>
    <span :if={!@link} aria-current={@current && "page"} class={@current && "text-ink"}>
      {@item.label}
    </span>
    """
  end

  defp link_attrs(%{to: to}), do: [navigate: to]
  defp link_attrs(%{patch: to}), do: [patch: to]
  defp link_attrs(%{href: to}), do: [href: to]
  defp link_attrs(_item), do: nil
end
