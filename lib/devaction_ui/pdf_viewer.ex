defmodule DevactionUI.PdfViewer do
  @moduledoc """
  A PDF viewer with signature fields: a rail of page thumbnails, a toolbar, the page and a panel of signers.

  The server owns `page` and `zoom`. The page is drawn by pdf.js in the browser when a `src` is given (the
  `DevactionUI.PdfViewer` hook loads `pdfjs-dist` with `import()` and takes the worker from `worker_src`), and
  the `:sheet` slot is the server-rendered page that shows until then, and stays when there is no `src`, so the
  viewer works, and is testable, without pdf.js. The toolbar (`toolbar/1`) and the panel (`signatures/1`) are
  plain function components that work without any JavaScript.

  The signature fields come as a list of maps `%{page, x, y, w, h, signer, state}`, the box in percent of the
  page and the `state` one of `:signed` (green), `:mine` ("you sign here": amber, dashed, with a small label)
  and `:pending` (neutral). A field may carry a `label` (the word on it, such as "Signed"); the hook never draws
  fields, they are part of the markup, so they sit over the page at any zoom.

  The hook sends `page` and `zoom` to the server with `pushEventTo`, to the events named by `page_event` and
  `zoom_event`, as `%{"page" => 3}` and `%{"zoom" => 125}`, which are the payloads of the buttons too. Keys:
  `+`, `-` and `0` zoom, PageUp, PageDown, Home and End turn pages, and the thumbnails are a listbox that the
  arrows move through. `zoom_in/1`, `zoom_out/1`, `clamp_page/2` and `my_page/1` are the server's side of that.
  """
  use Phoenix.Component

  @zoom_steps [50, 75, 100, 125, 150, 200, 300]

  @doc "The zoom one step in from `zoom`, which stops at the biggest step."
  @spec zoom_in(integer()) :: integer()
  def zoom_in(zoom), do: Enum.find(@zoom_steps, List.last(@zoom_steps), &(&1 > zoom))

  @doc "The zoom one step out from `zoom`, which stops at the smallest step."
  @spec zoom_out(integer()) :: integer()
  def zoom_out(zoom),
    do: @zoom_steps |> Enum.reverse() |> Enum.find(hd(@zoom_steps), &(&1 < zoom))

  @doc "A page number held to `1..total`."
  @spec clamp_page(integer(), integer()) :: integer()
  def clamp_page(page, total), do: page |> max(1) |> min(max(total, 1))

  @doc "The page of the first field the viewer's person has to sign, or `nil`."
  @spec my_page([map()]) :: integer() | nil
  def my_page(fields) do
    Enum.find_value(fields, fn
      %{state: :mine, page: page} -> page
      _field -> nil
    end)
  end

  attr :id, :string, required: true
  attr :name, :string, required: true, doc: "the file name, shown in the toolbar"
  attr :page, :integer, default: 1, doc: "the current page, owned by the server"
  attr :pages, :integer, required: true, doc: "how many pages the file has"
  attr :zoom, :integer, default: 100, doc: "the zoom in percent, owned by the server"

  attr :fields, :list,
    default: [],
    doc:
      "signature fields, `%{page, x, y, w, h, signer, state}` with the box in percent of the page"

  attr :src, :string,
    default: nil,
    doc: "the URL of the PDF; pdf.js draws it. Without it the `:sheet` slot is the page"

  attr :worker_src, :string,
    default: nil,
    doc: "the URL of the pdf.js worker (`pdf.worker.min.mjs`), set by the host"

  attr :page_width, :integer, default: 420, doc: "the width of a page in px at 100%"
  attr :page_height, :integer, default: 560, doc: "the height of a page in px at 100%"

  attr :page_event, :string,
    required: true,
    doc: "sent with `page` by the thumbnails and the keys"

  attr :zoom_event, :string, required: true, doc: "sent with `zoom` by the buttons and the keys"
  attr :jump_event, :any, default: nil, doc: "the jump to my signature: a string or a `%JS{}`"

  attr :field_event, :any,
    default: nil,
    doc: "sent by a field when pressed, with `page` and `signer`"

  attr :target, :any,
    default: nil,
    doc: "a `phx-target` (a `@myself`) when used inside a LiveComponent"

  attr :pages_label, :string, required: true, doc: "names the rail of thumbnails"
  attr :page_label, :string, required: true, doc: "the word for a page, such as `Page`"
  attr :zoom_label, :string, required: true, doc: "names the zoom value, such as `Zoom`"
  attr :zoom_out_label, :string, required: true
  attr :zoom_in_label, :string, required: true
  attr :jump_label, :string, default: nil, doc: "names the jump button of the toolbar"

  attr :mine_label, :string,
    default: nil,
    doc: "the small label on the field of the viewer's person"

  attr :class, :any, default: "h-[680px]", doc: "the height of the viewer, 680px by default"
  attr :rest, :global

  slot :sheet,
    doc: "the server-rendered page, given the page number; it shows until pdf.js draws the file"

  slot :jump_icon, doc: "the icon of the jump button, such as a signature"
  slot :zoom_out_icon, doc: "replaces the minus sign"
  slot :zoom_in_icon, doc: "replaces the plus sign"
  slot :actions, doc: "more buttons at the end of the toolbar, such as a download"
  slot :panel, doc: "the right panel, usually `signatures/1`"

  @doc "A PDF viewer with a thumbnail rail, a toolbar, the page with its signature fields, and a panel."
  @spec viewer(map()) :: Phoenix.LiveView.Rendered.t()
  def viewer(assigns) do
    assigns = assign(assigns, :size, size(assigns.page_width, assigns.page_height, assigns.zoom))

    ~H"""
    <div
      id={@id}
      phx-hook="DevactionUI.PdfViewer"
      data-page={@page}
      data-pages={@pages}
      data-zoom={@zoom}
      data-src={@src}
      data-worker-src={@worker_src}
      data-page-width={@page_width}
      data-page-height={@page_height}
      data-page-event={@page_event}
      data-zoom-event={@zoom_event}
      class={[
        "grid overflow-hidden rounded-2xl border border-line bg-card text-ink",
        columns(@panel),
        @class
      ]}
      {@rest}
    >
      <aside
        data-pdf-rail
        class="pdf-rail flex flex-col gap-3 overflow-auto border-r border-line p-3"
      >
        <div
          id={"#{@id}-pages"}
          role="listbox"
          aria-label={@pages_label}
          aria-orientation="vertical"
          class="flex flex-col gap-3"
        >
          <.thumb
            :for={number <- 1..@pages//1}
            id={@id}
            number={number}
            current={number == @page}
            label={"#{@page_label} #{number}"}
            fields={mine_on(@fields, number)}
            event={@page_event}
            target={@target}
          />
        </div>
      </aside>
      <div class="pdf-stage flex min-h-0 min-w-0 flex-col">
        <.toolbar
          name={@name}
          page={@page}
          pages={@pages}
          zoom={@zoom}
          zoom_event={@zoom_event}
          jump_event={@jump_event}
          target={@target}
          page_label={@page_label}
          zoom_label={@zoom_label}
          zoom_out_label={@zoom_out_label}
          zoom_in_label={@zoom_in_label}
          jump_label={@jump_label}
        >
          <:jump_icon :if={@jump_icon != []}>{render_slot(@jump_icon)}</:jump_icon>
          <:zoom_out_icon :if={@zoom_out_icon != []}>{render_slot(@zoom_out_icon)}</:zoom_out_icon>
          <:zoom_in_icon :if={@zoom_in_icon != []}>{render_slot(@zoom_in_icon)}</:zoom_in_icon>
          <:actions :if={@actions != []}>{render_slot(@actions)}</:actions>
        </.toolbar>
        <div
          role="region"
          aria-label={@name}
          tabindex="0"
          class="flex min-h-0 flex-1 overflow-auto p-6 outline-none focus-visible:ring-4 focus-visible:ring-ink/10 focus-visible:ring-inset"
        >
          <div
            id={"#{@id}-paper"}
            class="pdf-paper relative m-auto shrink-0 overflow-hidden"
            style={"width: #{@size.width}px; height: #{@size.height}px; --pdf-zoom: #{@zoom / 100}"}
          >
            <div data-pdf-fallback class="pdf-fallback">
              {render_slot(@sheet, @page)}
            </div>
            <div
              id={"#{@id}-canvas"}
              data-pdf-canvas-host
              phx-update="ignore"
              hidden
              class="absolute inset-0"
            >
            </div>
            <.field
              :for={field <- on_page(@fields, @page)}
              field={field}
              event={@field_event}
              target={@target}
              mine_label={@mine_label}
            />
          </div>
        </div>
      </div>
      <aside :if={@panel != []} class="flex min-h-0 flex-col overflow-auto border-l border-line p-4">
        {render_slot(@panel)}
      </aside>
    </div>
    """
  end

  defp size(width, height, zoom),
    do: %{width: round(width * zoom / 100), height: round(height * zoom / 100)}

  defp columns([]), do: "grid-cols-[150px_minmax(0,1fr)]"
  defp columns(_panel), do: "grid-cols-[150px_minmax(0,1fr)_280px]"

  defp on_page(fields, page), do: Enum.filter(fields, &(&1.page == page))
  defp mine_on(fields, page), do: fields |> on_page(page) |> Enum.filter(&(&1.state == :mine))

  attr :id, :string, required: true
  attr :number, :integer, required: true
  attr :current, :boolean, required: true
  attr :label, :string, required: true
  attr :fields, :list, required: true
  attr :event, :string, required: true
  attr :target, :any, default: nil

  defp thumb(assigns) do
    ~H"""
    <button
      type="button"
      role="option"
      aria-selected={to_string(@current)}
      aria-label={@label}
      tabindex={tab_stop(@current)}
      phx-click={@event}
      phx-target={@target}
      phx-value-page={@number}
      class="group flex flex-col items-center gap-1.5 rounded-md outline-none focus-visible:ring-4 focus-visible:ring-ink/10"
    >
      <span
        class={[
          "relative box-border flex h-[124px] w-24 flex-col gap-1 rounded-md border-2 bg-card px-[9px] py-2.5",
          current_edge(@current)
        ]}
        aria-hidden="true"
      >
        <span
          id={"#{@id}-thumb-#{@number}"}
          data-pdf-thumb-host={@number}
          phx-update="ignore"
          class="absolute inset-0 overflow-hidden rounded-[4px] empty:hidden"
        ></span>
        <span class="h-1 w-3/5 rounded-sm bg-done-cell"></span>
        <span
          :for={width <- ["w-full", "w-[92%]", "w-[96%]", "w-[70%]"]}
          class={["h-[3px] rounded-sm bg-line", width]}
        ></span>
        <span
          :for={field <- @fields}
          class="absolute rounded-[3px] border border-dashed border-ai bg-tag-warn-bg"
          style={box(field)}
        ></span>
      </span>
      <span class={["text-xs", current_text(@current)]}>{@number}</span>
    </button>
    """
  end

  defp tab_stop(true), do: "0"
  defp tab_stop(false), do: "-1"
  defp current_edge(true), do: "border-ink"
  defp current_edge(false), do: "border-line"
  defp current_text(true), do: "text-ink"
  defp current_text(false), do: "text-muted"

  defp box(%{x: x, y: y, w: w, h: h}),
    do: "left: #{x}%; top: #{y}%; width: #{w}%; height: #{h}%"

  attr :field, :map, required: true
  attr :event, :any, default: nil
  attr :target, :any, default: nil
  attr :mine_label, :string, default: nil

  defp field(assigns) do
    assigns = assign(assigns, :kind, kind(assigns.event))

    ~H"""
    <.dynamic_tag
      tag_name={@kind.tag}
      {@kind.attrs}
      phx-click={@event}
      phx-target={@target}
      phx-value-page={@field.page}
      phx-value-signer={@field.signer}
      data-state={@field.state}
      class={[
        "pdf-field absolute flex flex-col items-center justify-center gap-0.5 rounded-md border-[1.5px] p-0 font-sans outline-none focus-visible:ring-4 focus-visible:ring-ink/20",
        @kind.class
      ]}
      style={box(@field)}
    >
      <span :if={Map.get(@field, :label)} class="pdf-field-label text-xs font-semibold">
        {@field.label}
      </span>
      <span class="pdf-field-who text-[11px]">{@field.signer}</span>
      <span
        :if={@field.state == :mine and @mine_label}
        class="pdf-field-mark absolute -top-2.5 -left-px flex h-[18px] items-center rounded-[5px_5px_5px_0] px-1.5 text-[10px] font-semibold uppercase"
      >
        {@mine_label}
      </span>
    </.dynamic_tag>
    """
  end

  defp kind(nil), do: %{tag: "div", attrs: %{}, class: nil}
  defp kind(_event), do: %{tag: "button", attrs: %{type: "button"}, class: "cursor-pointer"}

  attr :name, :string, required: true
  attr :page, :integer, required: true
  attr :pages, :integer, required: true
  attr :zoom, :integer, required: true
  attr :zoom_event, :string, required: true, doc: "sent with `zoom`, the next step in or out"
  attr :jump_event, :any, default: nil, doc: "the jump to my signature: a string or a `%JS{}`"
  attr :target, :any, default: nil
  attr :page_label, :string, required: true
  attr :zoom_label, :string, required: true
  attr :zoom_out_label, :string, required: true
  attr :zoom_in_label, :string, required: true

  attr :jump_label, :string,
    default: nil,
    doc: "names the jump button; the button shows when it is given"

  attr :class, :any, default: nil
  attr :rest, :global
  slot :jump_icon, doc: "the icon of the jump button, such as a signature"
  slot :zoom_out_icon, doc: "replaces the minus sign"
  slot :zoom_in_icon, doc: "replaces the plus sign"
  slot :actions, doc: "more buttons at the end, such as a download"

  @doc "The toolbar of the viewer: the file name, the zoom, the page n of total and the jump to my signature."
  @spec toolbar(map()) :: Phoenix.LiveView.Rendered.t()
  def toolbar(assigns) do
    assigns =
      assign(assigns,
        zoom_in: zoom_in(assigns.zoom),
        zoom_out: zoom_out(assigns.zoom)
      )

    ~H"""
    <div
      role="toolbar"
      aria-label={@name}
      class={[
        "flex h-12 shrink-0 items-center gap-2 border-b border-line bg-card px-3 text-[13px]",
        @class
      ]}
      {@rest}
    >
      <span class="min-w-0 truncate font-medium">{@name}</span>
      <span class="ml-auto flex items-center gap-1">
        <button
          type="button"
          aria-label={@zoom_out_label}
          disabled={@zoom_out == @zoom}
          phx-click={@zoom_event}
          phx-target={@target}
          phx-value-zoom={@zoom_out}
          class={tool_class()}
        >
          <span :if={@zoom_out_icon == []} aria-hidden="true">−</span>
          <span :if={@zoom_out_icon != []} aria-hidden="true" class="size-4 [&>*]:size-full">
            {render_slot(@zoom_out_icon)}
          </span>
        </button>
        <span
          role="status"
          aria-label={@zoom_label}
          class="w-[52px] text-center font-mono text-xs"
        >
          {@zoom}%
        </span>
        <button
          type="button"
          aria-label={@zoom_in_label}
          disabled={@zoom_in == @zoom}
          phx-click={@zoom_event}
          phx-target={@target}
          phx-value-zoom={@zoom_in}
          class={tool_class()}
        >
          <span :if={@zoom_in_icon == []} aria-hidden="true">+</span>
          <span :if={@zoom_in_icon != []} aria-hidden="true" class="size-4 [&>*]:size-full">
            {render_slot(@zoom_in_icon)}
          </span>
        </button>
      </span>
      <span class="h-5 w-px bg-line" aria-hidden="true"></span>
      <span class="shrink-0 font-mono text-xs whitespace-nowrap text-ink-2">
        <span class="sr-only">{@page_label}</span>{@page} / {@pages}
      </span>
      <button
        :if={@jump_label && @jump_event}
        type="button"
        aria-label={@jump_label}
        title={@jump_label}
        phx-click={@jump_event}
        phx-target={@target}
        class={tool_class()}
      >
        <span aria-hidden="true" class="size-4 [&>*]:size-full">{render_slot(@jump_icon)}</span>
      </button>
      {render_slot(@actions)}
    </div>
    """
  end

  defp tool_class,
    do:
      "inline-flex size-[30px] items-center justify-center rounded-lg border border-line bg-card text-ink-2 outline-none hover:border-line-strong focus-visible:ring-4 focus-visible:ring-ink/10 disabled:cursor-not-allowed disabled:opacity-50"

  attr :title, :string, required: true, doc: "the heading of the panel, such as `Signatures`"

  attr :signers, :list,
    required: true,
    doc:
      "`%{name, role, status, status_label}` per signer; `status` is `:signed` or `:pending`, `tone` is `:red`, `:indigo`, `:green` or `:gray` and `mine: true` marks the viewer's person"

  attr :jump_event, :any, default: nil, doc: "the jump to my signature: a string or a `%JS{}`"

  attr :jump_label, :string,
    default: nil,
    doc: "the text of the primary button, which shows when it is given"

  attr :target, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :note, doc: "a note under the signers, such as where the field is"

  @doc "The panel of signers: avatar, name, role and a status for each, a note, and the jump to my signature."
  @spec signatures(map()) :: Phoenix.LiveView.Rendered.t()
  def signatures(assigns) do
    ~H"""
    <div class={["flex min-h-0 flex-1 flex-col gap-3.5 text-sm", @class]} {@rest}>
      <h2 class="text-sm font-semibold">{@title}</h2>
      <ul class="m-0 flex list-none flex-col gap-3.5 p-0">
        <li
          :for={signer <- @signers}
          class="flex items-center gap-2.5 rounded-[10px] border border-line p-2.5"
        >
          <span
            aria-hidden="true"
            class={[
              "flex size-[30px] shrink-0 items-center justify-center rounded-[9px] text-xs font-semibold",
              avatar_class(signer)
            ]}
          >
            {DevactionUI.Avatar.initials(signer.name)}
          </span>
          <span class="min-w-0">
            <span class="block font-medium">{signer.name}</span>
            <span class="block text-xs text-muted">{signer.role}</span>
          </span>
          <span
            data-status={signer.status}
            class={[
              "ml-auto inline-flex h-[22px] items-center rounded-md border px-[7px] text-[11px] whitespace-nowrap",
              status_class(signer.status)
            ]}
          >
            {signer.status_label}
          </span>
        </li>
      </ul>
      <div
        :if={@note != []}
        class="rounded-[10px] border border-tag-warn-line bg-tag-warn-bg p-3 text-[13px] leading-normal text-tag-warn-strong"
      >
        {render_slot(@note)}
      </div>
      <button
        :if={@jump_label && @jump_event}
        type="button"
        phx-click={@jump_event}
        phx-target={@target}
        class="mt-auto h-[42px] shrink-0 cursor-pointer rounded-[10px] border border-ink bg-ink px-4 font-medium text-on-primary outline-none focus-visible:ring-4 focus-visible:ring-ink/20"
      >
        {@jump_label}
      </button>
    </div>
    """
  end

  defp avatar_class(%{mine: true}), do: "bg-ink text-on-primary"
  defp avatar_class(%{tone: :indigo}), do: "bg-avatar-indigo-bg text-avatar-indigo-fg"
  defp avatar_class(%{tone: :green}), do: "bg-avatar-green-bg text-avatar-green-fg"
  defp avatar_class(%{tone: :red}), do: "bg-avatar-red-bg text-avatar-red-fg"
  defp avatar_class(_signer), do: "bg-avatar-gray-bg text-avatar-gray-fg"

  defp status_class(:signed), do: "border-tag-ok-line bg-tag-ok-bg text-tag-ok-text"
  defp status_class(:pending), do: "border-tag-warn-line bg-tag-warn-bg text-tag-warn-text"
end
