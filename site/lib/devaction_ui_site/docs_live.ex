defmodule DevactionUISite.DocsLive do
  @moduledoc """
  The documentation of `DevactionUI`: the introduction, the installation, the colour tokens, one page per
  component and the templates, in one LiveView so moving between pages is a patch. It holds only what navigation
  needs (the page, the search of the sidebar); every example on a page is a LiveView of its own
  (`DevactionUISite.ExampleLive`), so a demo's state never leaks into the next.
  """
  use Phoenix.LiveView

  alias DevactionUISite.{Catalog, DocsHTML, Templates}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "DevactionUI",
       topic: nil,
       template_group: nil,
       previews: [],
       nav_query: "",
       nav_groups: Catalog.groups()
     )}
  end

  @impl true
  def render(assigns), do: DocsHTML.page(assigns)

  @impl true
  def handle_params(%{"slugs" => slugs}, _uri, socket) do
    previews =
      for slug <- String.split(slugs, ","), {:ok, topic} <- [Catalog.fetch(slug)], do: topic

    {:noreply,
     assign(socket, topic: nil, previews: previews, page_title: "Preview · DevactionUI")}
  end

  def handle_params(%{"group" => group}, _uri, socket) do
    case Templates.fetch(group) do
      {:ok, found} ->
        {:noreply,
         assign(socket,
           topic: nil,
           template_group: found,
           page_title: "#{found.title} templates · DevactionUI"
         )}

      :error ->
        {:noreply, push_patch(socket, to: "/")}
    end
  end

  def handle_params(%{"slug" => slug}, _uri, socket) do
    case Catalog.fetch(slug) do
      {:ok, topic} ->
        {:noreply, assign(socket, topic: topic, page_title: "#{topic.title} · DevactionUI")}

      :error ->
        {:noreply, push_patch(socket, to: "/")}
    end
  end

  def handle_params(_params, _uri, %{assigns: %{live_action: :tokens}} = socket),
    do: {:noreply, assign(socket, topic: nil, page_title: "Colors · DevactionUI")}

  def handle_params(_params, _uri, %{assigns: %{live_action: :installation}} = socket),
    do: {:noreply, assign(socket, topic: nil, page_title: "Installation · DevactionUI")}

  def handle_params(_params, _uri, socket),
    do: {:noreply, assign(socket, topic: nil, page_title: "DevactionUI")}

  @impl true
  def handle_event("nav_search", %{"q" => query}, socket),
    do: {:noreply, assign(socket, nav_query: query, nav_groups: Catalog.search(query))}

  def handle_event(
        "nav_go",
        _params,
        %{assigns: %{nav_groups: [{_group, [topic | _]} | _]}} = socket
      ),
      do: {:noreply, push_patch(socket, to: "/c/#{topic.slug}")}

  def handle_event("nav_go", _params, socket), do: {:noreply, socket}

  def handle_event(_event, _params, socket), do: {:noreply, socket}
end
