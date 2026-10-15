defmodule DevactionUI.Editor do
  @moduledoc """
  A rich text editor for delivery notes, scope and long comments: a toolbar over a TipTap (ProseMirror)
  surface, the way the canvas draws it (`.editor`, `.editor-toolbar`, `.editor-btn`, `.editor-content`).

  The text lives in the browser (`DevactionUI.Editor` hook) and goes out as HTML and as Markdown in two hidden
  inputs, `<name>[html]` and `<name>[markdown]`, which fire `input` on every change so a form with `phx-change`
  hears it. The initial content is `value`, as HTML. The root is ignored by LiveView patches, so the text is
  never lost to a re-render; to replace it, give the editor a new `id`.

  The server must treat what comes back as untrusted: sanitize the HTML before it is stored or shown.

  Typing `/` at the start of a line opens a menu of blocks (`slash`, each `%{key, label}` with a key of
  `paragraph`, `h2`, `h3`, `bulletList`, `orderedList`, `taskList`, `blockquote`, `codeBlock` or `divider`),
  and `@` opens the members (`mentions`, each `%{id, label}`); a chosen member stays in the text as
  `<span data-type="mention" data-id="...">`, which is what the server reads to know who was mentioned.
  `compact` is the comment form: a short surface, usually without a toolbar, and with `send_on_enter` the
  command (or control) and Enter submit the form the editor is in.

  Buttons come from the `:tool` slot, each with the command it runs (`bold`, `italic`, `strike`, `code`,
  `bulletList`, `orderedList`, `taskList`, `blockquote`, `indent`, `outdent`, `alignLeft`, `alignCenter`,
  `alignRight`, `undo`, `redo`, `link`, `image` (which sends a file to `upload_url`) or `ai` (which sends the Markdown as the event
  `improve` to the component the editor is in, and takes back the text it answers with in `editor:replace`)), its label and its icon as the body. A tool with `separator` is
  preceded by a divider. The library holds no icons and no language: the caller gives both.
  """
  use Phoenix.Component

  attr :id, :string, required: true

  attr :name, :string,
    required: true,
    doc: "prefix of the two inputs: `name[html]` and `name[markdown]`"

  attr :value, :string, default: "", doc: "the initial content, as HTML"
  attr :label, :string, required: true, doc: "the accessible name of the text area"
  attr :placeholder, :string, default: ""

  attr :styles, :list,
    default: [],
    doc: "`[{label, value}]` with values `paragraph`, `h2`, `h3`; empty hides the select"

  attr :style_label, :string, required: true
  attr :words_label, :string, required: true
  attr :slash, :list, default: [], doc: "`[%{key, label}]` for the `/` menu; empty turns it off"
  attr :mentions, :list, default: [], doc: "`[%{id, label}]` for the `@` menu; empty turns it off"

  attr :upload_url, :string,
    default: nil,
    doc:
      "where the `image` tool sends a file (the image is the body of the request; it answers `{url}`); nil turns the tool off"

  attr :upload_max, :integer, default: 5_242_880, doc: "the largest image, in bytes"

  attr :upload_errors, :map,
    default: %{},
    doc: "what to say when an upload fails: `unsupported`, `too_large`, `failed`"

  attr :ai_labels, :map,
    default: %{},
    doc:
      "texts of the `ai` tool: `working`, `done` and `failed`; the tool sends `improve` with the Markdown to the component the editor is in"

  attr :compact, :boolean, default: false, doc: "the short comment form"
  attr :send_on_enter, :boolean, default: false, doc: "⌘↵ or Ctrl↵ submits the form"
  attr :link_label, :string, required: true
  attr :class, :any, default: nil

  attr :rest, :global,
    include: ~w(phx-target),
    doc: "`phx-target`: where the `ai` tool sends `improve`"

  slot :tool do
    attr :name, :string, required: true
    attr :label, :string, required: true
    attr :separator, :boolean
  end

  def editor(assigns) do
    ~H"""
    <div
      id={@id}
      phx-hook="DevactionUI.Editor"
      phx-update="ignore"
      data-label={@label}
      data-placeholder={@placeholder}
      data-slash={Jason.encode!(@slash)}
      data-mentions={Jason.encode!(@mentions)}
      data-send={to_string(@send_on_enter)}
      data-ai-labels={Jason.encode!(@ai_labels)}
      data-upload-url={@upload_url}
      data-upload-max={@upload_max}
      data-upload-errors={Jason.encode!(@upload_errors)}
      class={["flex flex-col", @class]}
      {@rest}
    >
      <div class={["editor", @compact && "editor-compact"]}>
        <div
          :if={@tool != [] or @styles != []}
          role="toolbar"
          aria-label={@label}
          class="editor-toolbar"
        >
          <select
            :if={@styles != []}
            id={"#{@id}-style"}
            data-style
            aria-label={@style_label}
            class="h-8.5 rounded-lg border border-line bg-card px-2 text-sm text-ink outline-none focus-visible:ring-4 focus-visible:ring-ink/10"
          >
            <option :for={{label, value} <- @styles} value={value}>{label}</option>
          </select>
          <%= for tool <- @tool do %>
            <span :if={tool[:separator]} class="editor-sep" aria-hidden="true" />
            <button
              type="button"
              id={"#{@id}-tool-#{tool.name}"}
              aria-label={tool.label}
              title={tool.label}
              aria-pressed="false"
              {tool_data(tool.name)}
              class="editor-btn outline-none focus-visible:ring-4 focus-visible:ring-ink/10"
            >
              {render_slot(tool)}
            </button>
          <% end %>
        </div>
        <div
          id={"#{@id}-link-bar"}
          data-link-bar
          hidden
          class="flex items-center gap-2 border-b border-line bg-wrap/40 px-3 py-2"
        >
          <input
            id={"#{@id}-link-input"}
            type="text"
            data-link-input
            aria-label={@link_label}
            placeholder="https://"
            class="h-8.5 flex-1 rounded-lg border border-line bg-card px-3 text-sm text-ink outline-none focus-visible:ring-4 focus-visible:ring-ink/10"
          />
        </div>
        <input
          :if={@upload_url}
          id={"#{@id}-image-input"}
          type="file"
          data-image-input
          accept="image/png,image/jpeg,image/gif,image/webp"
          hidden
          tabindex="-1"
        />
        <p
          id={"#{@id}-status"}
          data-editor-status
          role="alert"
          hidden
          class="m-0 px-4 py-2 text-xs text-tag-risk-text"
        >
        </p>
        <div id={"#{@id}-content"} data-editor-content class="editor-content-host"></div>
        <input type="hidden" name={"#{@name}[html]"} data-html value={@value} />
        <input type="hidden" name={"#{@name}[markdown]"} data-markdown value="" />
      </div>
      <p class="editor-meta">
        <span><span id={"#{@id}-count"} data-count>0</span> {@words_label}</span>
      </p>
    </div>
    """
  end

  defp tool_data("link"), do: %{"data-link": true}
  defp tool_data("image"), do: %{"data-image": true}
  defp tool_data("ai"), do: %{"data-ai": true}
  defp tool_data(name), do: %{"data-command": name}
end
