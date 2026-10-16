defmodule DevactionUI.PdfViewerTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.PdfViewer

  @fields [
    %{
      page: 4,
      x: 8,
      y: 80.6,
      w: 38.6,
      h: 10.4,
      signer: "Church",
      state: :signed,
      label: "Signed"
    },
    %{page: 4, x: 53.3, y: 80.6, w: 38.6, h: 10.4, signer: "Alex", state: :mine, label: "Sign"},
    %{page: 2, x: 10, y: 10, w: 20, h: 5, signer: "Bob", state: :pending}
  ]

  @signers [
    %{name: "Church Admin", role: "Client", status: :signed, status_label: "Signed", tone: :red},
    %{
      name: "Alex Nogueira",
      role: "DevAction",
      status: :pending,
      status_label: "Pending",
      mine: true
    }
  ]

  defp render_viewer(extra \\ %{}) do
    assigns =
      Map.merge(
        %{
          page: 4,
          zoom: 100,
          fields: @fields,
          signers: @signers,
          src: nil,
          worker_src: nil,
          field_event: "field",
          target: nil,
          rest: %{}
        },
        extra
      )

    rendered_to_string(~H"""
    <PdfViewer.viewer
      id="pdf"
      name="Contract.pdf"
      page={@page}
      pages={4}
      zoom={@zoom}
      fields={@fields}
      src={@src}
      worker_src={@worker_src}
      page_event="page"
      zoom_event="zoom"
      jump_event="jump"
      field_event={@field_event}
      target={@target}
      pages_label="Pages"
      page_label="Page"
      zoom_label="Zoom"
      zoom_out_label="Zoom out"
      zoom_in_label="Zoom in"
      jump_label="Go to my signature"
      mine_label="You sign here"
      {@rest}
    >
      <:sheet :let={number}>Text of page {number}</:sheet>
      <:jump_icon>J</:jump_icon>
      <:panel>
        <PdfViewer.signatures
          title="Signatures"
          signers={@signers}
          jump_event="jump"
          jump_label="Go to my signature"
        >
          <:note>Your field is on page 4.</:note>
        </PdfViewer.signatures>
      </:panel>
    </PdfViewer.viewer>
    """)
  end

  test "the hook owns the root, which carries the server's page and zoom" do
    html = render_viewer(%{src: "/a.pdf", worker_src: "/w.mjs"})

    assert html =~ ~s(phx-hook="DevactionUI.PdfViewer")
    assert html =~ ~s(data-page="4")
    assert html =~ ~s(data-pages="4")
    assert html =~ ~s(data-zoom="100")
    assert html =~ ~s(data-src="/a.pdf")
    assert html =~ ~s(data-worker-src="/w.mjs")
    assert html =~ ~s(data-page-event="page")
    assert html =~ ~s(data-zoom-event="zoom")
  end

  test "the rail is a listbox of one option per page, the current one selected and in the tab order" do
    html = render_viewer()

    assert html =~ ~s(role="listbox")
    assert html =~ ~s(aria-label="Pages")
    assert length(Regex.scan(~r/role="option"/, html)) == 4
    assert html =~ ~r/aria-selected="true"[^>]*aria-label="Page 4"[^>]*tabindex="0"/
    assert html =~ ~r/aria-selected="false"[^>]*aria-label="Page 1"[^>]*tabindex="-1"/
    assert html =~ ~s(phx-value-page="3")
  end

  test "the server-rendered page is the fallback and the canvas host is left alone by patches" do
    html = render_viewer()

    assert html =~ "data-pdf-fallback"
    assert html =~ "Text of page 4"
    assert html =~ ~r/data-pdf-canvas-host[^>]*phx-update="ignore"/
  end

  test "the toolbar shows the file, the zoom, the page and the jump" do
    html = render_viewer()

    assert html =~ ~s(role="toolbar")
    assert html =~ "Contract.pdf"
    assert html =~ "100%"
    assert html =~ ~r/4 \/ 4/
    assert html =~ ~s(aria-label="Zoom out")
    assert html =~ ~s(phx-value-zoom="75")
    assert html =~ ~s(phx-value-zoom="125")
    assert html =~ ~s(aria-label="Go to my signature")
  end

  test "the zoom buttons stop at the ends of the steps" do
    assert render_viewer(%{zoom: 50}) =~ ~r/aria-label="Zoom out"[^>]*disabled(?!:)/
    assert render_viewer(%{zoom: 300}) =~ ~r/aria-label="Zoom in"[^>]*disabled(?!:)/
    refute render_viewer(%{zoom: 100}) =~ ~r/aria-label="Zoom in"[^>]*disabled(?!:)/
  end

  test "the page is sized by the zoom and carries the zoom for its text" do
    assert render_viewer(%{zoom: 125}) =~ "width: 525px; height: 700px; --pdf-zoom: 1.25"
  end

  test "fields are drawn on their own page, in percent of it, by state" do
    html = render_viewer()

    assert html =~ ~s(data-state="signed")
    assert html =~ ~s(data-state="mine")
    assert html =~ "left: 53.3%; top: 80.6%; width: 38.6%; height: 10.4%"
    assert html =~ "You sign here"
    refute html =~ ~s(data-state="pending")
  end

  test "another page shows its own fields" do
    html = render_viewer(%{page: 2})

    assert html =~ ~s(data-state="pending")
    refute html =~ ~s(data-state="signed")
    refute html =~ "You sign here"
  end

  test "fields are buttons with an event and plain boxes without" do
    assert render_viewer() =~ ~r/<button(?=[^>]*phx-click="field")(?=[^>]*data-state="signed")/
    refute render_viewer(%{field_event: nil}) =~ ~s(phx-click="field")
  end

  test "the thumbnail of a page with my field marks where it is" do
    assert render_viewer() =~ "border-dashed border-ai bg-tag-warn-bg"
  end

  test "the panel lists the signers with a status and the primary jump" do
    html = render_viewer()

    assert html =~ "Signatures"
    assert html =~ "Church Admin"
    assert html =~ ~s(data-status="signed")
    assert html =~ ~s(data-status="pending")
    assert html =~ "CA"
    assert html =~ "Your field is on page 4."
    assert html =~ ~r/<button[^>]*phx-click="jump"[^>]*>\s*Go to my signature/
  end

  test "without a panel the viewer has two columns" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <PdfViewer.viewer
        id="p"
        name="a.pdf"
        pages={2}
        page_event="page"
        zoom_event="zoom"
        pages_label="Pages"
        page_label="Page"
        zoom_label="Zoom"
        zoom_out_label="Out"
        zoom_in_label="In"
      />
      """)

    assert html =~ "grid-cols-[150px_minmax(0,1fr)]"
    refute html =~ "280px"
    refute html =~ "Go to my signature"
  end

  test "the target and extra attributes are passed through" do
    html = render_viewer(%{target: "#box", rest: %{"data-x": "1"}})

    assert html =~ ~s(data-x="1")
    assert html =~ ~s(phx-target="#box")
  end

  test "zoom steps in and out and stops at the ends" do
    assert PdfViewer.zoom_in(100) == 125
    assert PdfViewer.zoom_in(300) == 300
    assert PdfViewer.zoom_out(100) == 75
    assert PdfViewer.zoom_out(50) == 50
    assert PdfViewer.zoom_in(110) == 125
    assert PdfViewer.zoom_out(110) == 100
  end

  test "a page is held to the file and my page is the first field of mine" do
    assert PdfViewer.clamp_page(0, 4) == 1
    assert PdfViewer.clamp_page(9, 4) == 4
    assert PdfViewer.my_page(@fields) == 4
    assert PdfViewer.my_page([]) == nil
  end
end
