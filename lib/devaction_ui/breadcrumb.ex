defmodule DevactionUI.Breadcrumb do
  @moduledoc """
  Where the page is: `Today / SGE / PR #142`. The items are `%{label: ..., to: path}`; the last one has no
  `to` and is the current page (`aria-current="page"`).
  """
  use Phoenix.Component

  attr :label, :string,
    required: true,
    doc: "the name of the navigation, for assistive technology"

  attr :items, :list, required: true
  attr :class, :any, default: nil
  attr :rest, :global

  def breadcrumb(assigns) do
    ~H"""
    <nav aria-label={@label} class={["text-sm text-muted", @class]} {@rest}>
      <ol class="m-0 flex list-none flex-wrap items-center gap-2.5 p-0">
        <li :for={{item, index} <- Enum.with_index(@items)} class="flex items-center gap-2.5">
          <span :if={index > 0} aria-hidden="true">/</span>
          <.link :if={item[:to]} navigate={item.to} class="text-muted underline underline-offset-2">
            {item.label}
          </.link>
          <span :if={is_nil(item[:to])} aria-current="page" class="text-ink">{item.label}</span>
        </li>
      </ol>
    </nav>
    """
  end
end
