defmodule DevactionUI.PageHeader do
  @moduledoc """
  The head of a screen as the canvas lays it out: the breadcrumb above, then the title with its status tag and
  the actions at the end, an optional line of text, and the tabs under it. It only places the pieces; each one is
  the caller's (a `DevactionUI.Breadcrumb`, a `DevactionUI.Tag`, buttons, tabs). The `toolbar` slot is a row
  under the tabs, for the search and the filters of a list, with `toolbar_end` at its end for the count of results.
  """
  use Phoenix.Component

  attr :id, :string, required: true
  attr :class, :any, default: nil
  slot :breadcrumb
  slot :status, doc: "a tag beside the title: `AT RISK`, `DRAFT`"
  slot :title, required: true
  slot :subtitle
  slot :actions, doc: "the buttons at the end"
  slot :tabs, doc: "the tabs under the head"
  slot :toolbar, doc: "a row under the tabs: the search and the filters"
  slot :toolbar_end, doc: "the end of the toolbar: the count of results"

  attr :rest, :global

  def page_header(assigns) do
    ~H"""
    <header id={@id} class={["flex flex-col gap-3.5", @class]} {@rest}>
      <div :if={@breadcrumb != []}>{render_slot(@breadcrumb)}</div>
      <div class="page-header">
        <div class="flex min-w-0 flex-col gap-2">
          <div class="flex flex-wrap items-center gap-3">
            <h1 class="page-title m-0 text-ink">{render_slot(@title)}</h1>
            {render_slot(@status)}
          </div>
          <p :if={@subtitle != []} class="m-0 max-w-[640px] text-[15px] text-ink-2">
            {render_slot(@subtitle)}
          </p>
        </div>
        <div :if={@actions != []} class="flex flex-wrap items-center gap-2.5">
          {render_slot(@actions)}
        </div>
      </div>
      <div :if={@tabs != []}>{render_slot(@tabs)}</div>
      <div :if={@toolbar != [] or @toolbar_end != []} class="flex flex-wrap items-center gap-2.5">
        {render_slot(@toolbar)}
        <div :if={@toolbar_end != []} class="ms-auto text-[13px] text-muted">
          {render_slot(@toolbar_end)}
        </div>
      </div>
    </header>
    """
  end
end
