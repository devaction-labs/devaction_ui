defmodule DevactionUI.Breadcrumb do
  @moduledoc """
  Where the page is: `Today / SGE / PR #142`. The last item is the current page and always carries
  `aria-current="page"`, whether it is a link or plain text.
  """
  use Phoenix.Component

  attr :label, :string,
    required: true,
    doc: "the name of the navigation, for assistive technology"

  attr :items, :list,
    required: true,
    doc:
      "`%{label: ..., to: path}` each; `to` navigates to another LiveView, `patch` patches this one and `href` is a plain link. An item with none of them is plain text"

  attr :class, :any, default: nil
  attr :rest, :global

  @doc "The trail of pages up to the current one."
  @spec breadcrumb(map()) :: Phoenix.LiveView.Rendered.t()
  def breadcrumb(assigns) do
    assigns = assign(assigns, :last, length(assigns.items) - 1)

    ~H"""
    <nav aria-label={@label} class={["text-sm text-muted", @class]} {@rest}>
      <ol class="m-0 flex list-none flex-wrap items-center gap-2.5 p-0">
        <li :for={{item, index} <- Enum.with_index(@items)} class="flex items-center gap-2.5">
          <span :if={index > 0} aria-hidden="true">/</span>
          <.crumb item={item} current={index == @last} />
        </li>
      </ol>
    </nav>
    """
  end

  attr :item, :map, required: true
  attr :current, :boolean, required: true

  defp crumb(assigns) do
    assigns = assign(assigns, :link, link_attrs(assigns.item))

    ~H"""
    <.link
      :if={@link}
      {@link}
      aria-current={@current && "page"}
      class={[
        "rounded-sm underline underline-offset-2 outline-none hover:text-ink focus-visible:ring-4 focus-visible:ring-ink/10",
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
