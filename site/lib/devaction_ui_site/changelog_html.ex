defmodule DevactionUISite.ChangelogHTML do
  @moduledoc "Stub of the changelog page; the real one replaces this file."
  use Phoenix.Component

  alias DevactionUISite.Shell

  def page(assigns) do
    ~H"""
    <Shell.shell page={assigns} sidebar={false}>
      <div id="changelog" class="px-10 py-16">
        <h1 class="m-0 text-[40px] font-semibold text-ink">Changelog</h1>
      </div>
    </Shell.shell>
    """
  end
end
