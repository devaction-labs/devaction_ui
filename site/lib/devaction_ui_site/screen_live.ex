defmodule DevactionUISite.ScreenLive do
  @moduledoc """
  One template of `Templates` as a page of its own, with nothing of the documentation around it: this is what the
  documentation embeds, scaled down, and what a person opens to see the screen at its real size. A LiveView, so
  the components that need the browser (tabs, the password toggle) work as they would in an app.
  """
  use Phoenix.LiveView

  alias DevactionUISite.{ScreenHTML, Templates}

  @impl true
  def mount(%{"group" => group, "slug" => slug}, _session, socket) do
    case Templates.screen(group, slug) do
      {:ok, _group, screen} ->
        {:ok,
         assign(socket, key: "#{group}_#{slug}", page_title: "#{screen.title} · DevactionUI")}

      :error ->
        {:ok, redirect(socket, to: "/")}
    end
  end

  @impl true
  def render(assigns), do: ScreenHTML.render(assigns.key, assigns)

  @impl true
  def handle_event(_event, _params, socket), do: {:noreply, socket}
end
