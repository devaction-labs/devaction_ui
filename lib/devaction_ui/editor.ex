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
  Each `slash` and `mentions` entry may also carry an `icon` (a glyph) and a `hint` (what is written at the end
  of the row, such as `#`). `compact` is the comment form: a short surface, usually without a toolbar, and with
  `send_on_enter` the command (or control) and Enter submit the form the editor is in; its `footer` slot is for
  the buttons under the surface. With `toolbar_position={:bottom}` the toolbar goes under the surface, in one bar
  with the `footer` (tools on the left, the send button on the right), as the canvas draws a comment box.

  The hook is tied to the host by names the caller can change: the image is sent with the CSRF token of the
  `<meta>` called `csrf_meta` in the header `csrf_header`, and the `ai` tool sends the event `improve_event` and
  listens for `replace_event` and `failed_event` (the defaults are Phoenix's `csrf-token` and `x-csrf-token`, and
  `improve`, `editor:replace` and `editor:failed`).

  The field has a visible label (`show_label`), a `hint` slot beside the word count, an `error` and a `disabled`
  state. The label and the error sit outside the ignored root and the flags are `data-*` attributes, so they
  follow the server; the toolbar, the `hint` and the `footer` are drawn once.

  TipTap is loaded by the hook only when an editor is mounted (a dynamic `import()`), so an app that never
  renders one does not need its npm packages: see `assets/package.json` for the list and the versions.

  Buttons come from the `:tool` slot, each with the command it runs (`bold`, `italic`, `strike`, `code`,
  `bulletList`, `orderedList`, `taskList`, `blockquote`, `indent`, `outdent`, `alignLeft`, `alignCenter`,
  `alignRight`, `undo`, `redo`, `link`, `image` (which sends a file to `upload_url`) or `ai` (which sends the Markdown as the event
  `improve` to the component the editor is in, and takes back the text it answers with in `editor:replace`)), its label and its icon as the body. A tool with `separator` is
  preceded by a divider. The library holds no icons and no language: the caller gives both.

  `suggest/1` is the popup of those two menus as a component of its own, for a page that draws it itself (a
  mock, a server-rendered mention list, the docs): a listbox with a group label (`PEOPLE`, `COMMANDS`), rows of
  a 26px mark (the initials of a person, or an icon), a title and a hint, the active row highlighted and
  carrying the Enter key cap.
  """
  use Phoenix.Component

  alias DevactionUI.Tone

  attr :id, :string, required: true

  attr :name, :string,
    required: true,
    doc: "prefix of the two inputs: `name[html]` and `name[markdown]`"

  attr :value, :string, default: "", doc: "the initial content, as HTML"
  attr :label, :string, required: true, doc: "the name of the text area, shown when `show_label`"

  attr :toolbar_label, :string,
    required: true,
    doc: "the name of the toolbar, distinct from the text area's (e.g. `Formatting`)"

  attr :show_label, :boolean, default: false, doc: "draw `label` above the editor"
  attr :error, :string, default: nil, doc: "what is wrong; marks the field invalid"
  attr :disabled, :boolean, default: false, doc: "the text cannot be edited and the tools are off"
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

  attr :toolbar_position, :atom,
    values: [:top, :bottom],
    default: :top,
    doc: "`:bottom` puts the toolbar under the surface, in one bar with the `footer`"

  attr :csrf_meta, :string,
    default: "csrf-token",
    doc: "the name of the `<meta>` that holds the CSRF token sent with an image"

  attr :csrf_header, :string,
    default: "x-csrf-token",
    doc: "the header that carries the token with an image"

  attr :improve_event, :string,
    default: "improve",
    doc: "the event the `ai` tool sends, with the Markdown"

  attr :replace_event, :string,
    default: "editor:replace",
    doc: "the event the server answers `improve_event` with: `%{id, markdown}`"

  attr :failed_event, :string,
    default: "editor:failed",
    doc: "the event the server answers with when it could not improve the text: `%{id}`"

  attr :send_on_enter, :boolean, default: false, doc: "⌘↵ or Ctrl↵ submits the form"
  attr :link_label, :string, required: true
  attr :class, :any, default: nil

  attr :rest, :global,
    include: ~w(phx-target),
    doc: "`phx-target`: where the `ai` tool sends `improve`"

  slot :hint, doc: "text on the left of the word count, e.g. what Markdown is understood"
  slot :footer, doc: "a bar under the surface, e.g. the send button of a comment"

  slot :tool do
    attr :name, :string, required: true
    attr :label, :string, required: true
    attr :separator, :boolean
  end

  def editor(assigns) do
    assigns =
      assign(assigns,
        described_by: described_by(assigns),
        bar?: assigns.tool != [] or assigns.styles != []
      )

    ~H"""
    <div id={"#{@id}-field"} class={["flex flex-col gap-1.5", @class]}>
      <span :if={@show_label} id={"#{@id}-label"} class="text-sm font-medium text-ink">{@label}</span>
      <div
        id={@id}
        phx-hook="DevactionUI.Editor"
        phx-update="ignore"
        data-label={@label}
        data-labelledby={@show_label && "#{@id}-label"}
        data-described-by={@described_by}
        data-invalid={to_string(@error != nil)}
        data-disabled={to_string(@disabled)}
        data-placeholder={@placeholder}
        data-slash={Jason.encode!(@slash)}
        data-mentions={Jason.encode!(@mentions)}
        data-send={to_string(@send_on_enter)}
        data-ai-labels={Jason.encode!(@ai_labels)}
        data-upload-url={@upload_url}
        data-upload-max={@upload_max}
        data-upload-errors={Jason.encode!(@upload_errors)}
        data-csrf-meta={@csrf_meta}
        data-csrf-header={@csrf_header}
        data-improve-event={@improve_event}
        data-replace-event={@replace_event}
        data-failed-event={@failed_event}
        class="editor-root flex flex-col"
        {@rest}
      >
        <div class={["editor", @compact && "editor-compact"]}>
          <.toolbar
            :if={@bar? and @toolbar_position == :top}
            id={@id}
            label={@toolbar_label}
            style_label={@style_label}
            styles={@styles}
            tool={@tool}
            class="editor-toolbar"
          />
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
          <div :if={@toolbar_position == :top and @footer != []} class="editor-footer">
            {render_slot(@footer)}
          </div>
          <div
            :if={@toolbar_position == :bottom and (@bar? or @footer != [])}
            class="editor-bar"
          >
            <.toolbar
              :if={@bar?}
              id={@id}
              label={@toolbar_label}
              style_label={@style_label}
              styles={@styles}
              tool={@tool}
              class="editor-toolbar-inline"
            />
            <div :if={@footer != []} class="ml-auto flex items-center gap-2">
              {render_slot(@footer)}
            </div>
          </div>
        </div>
        <p class="editor-meta">
          <span :if={@hint != []} id={"#{@id}-hint"}>{render_slot(@hint)}</span>
          <span class="ml-auto"><span id={"#{@id}-count"} data-count>0</span> {@words_label}</span>
        </p>
      </div>
      <p :if={@error} id={"#{@id}-error"} class="m-0 text-sm text-tag-risk-text">{@error}</p>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :label, :string, required: true
  attr :style_label, :string, required: true
  attr :styles, :list, required: true
  attr :tool, :list, required: true
  attr :class, :string, required: true

  defp toolbar(assigns) do
    ~H"""
    <div role="toolbar" aria-label={@label} class={@class}>
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
    """
  end

  defp described_by(%{error: nil}), do: nil
  defp described_by(%{id: id}), do: "#{id}-error"

  defp tool_data("link"), do: %{"data-link": true}
  defp tool_data("image"), do: %{"data-image": true}
  defp tool_data("ai"), do: %{"data-ai": true}
  defp tool_data(name), do: %{"data-command": name}

  attr :id, :string, required: true
  attr :label, :string, required: true, doc: "the name of the list, for assistive technology"
  attr :heading, :string, default: nil, doc: "the label of the group: `PEOPLE`, `COMMANDS`"
  attr :active, :integer, default: 0, doc: "the index of the highlighted row; -1 for none"
  attr :enter, :string, default: "↵", doc: "the key cap at the end of the active row"
  attr :class, :any, default: nil

  attr :target, :any,
    default: nil,
    doc: "a `phx-target` (a `@myself`) when used inside a LiveComponent"

  slot :option,
    required: true,
    doc: "a row; its body is the mark before the title: initials or an icon" do
    attr :title, :string, required: true

    attr :hint, :string,
      doc: "the second line, such as the role of a person or what a command does"

    attr :tone, :atom, doc: "`:ink` (the default) or a `DevactionUI.Tone`: the colour of the mark"
    attr :event, :string, doc: "sent when the row is chosen, with its `value`"
    attr :value, :string, doc: "sent as `choice`"
  end

  attr :rest, :global

  @doc "The popup of the `@` and `/` menus: a listbox with a group label and rows of a mark, a title and a hint."
  @spec suggest(map()) :: Phoenix.LiveView.Rendered.t()
  def suggest(assigns) do
    ~H"""
    <div
      id={@id}
      role="listbox"
      aria-label={@label}
      class={[
        "flex w-[330px] max-w-full flex-col rounded-xl border border-line bg-card p-1.5 text-sm text-ink shadow-menu",
        @class
      ]}
      {@rest}
    >
      <span
        :if={@heading}
        role="presentation"
        class="px-2 pt-1 pb-1.5 font-mono text-[10px] tracking-[0.08em] text-muted"
      >
        {@heading}
      </span>
      <div
        :for={{option, index} <- Enum.with_index(@option)}
        id={"#{@id}-option-#{index}"}
        role="option"
        aria-selected={to_string(index == @active)}
        phx-click={Map.get(option, :event)}
        phx-target={@target}
        phx-value-choice={Map.get(option, :value)}
        class={[
          "flex h-10 items-center gap-2.5 rounded-lg px-2",
          index == @active && "bg-wrap",
          Map.get(option, :event) && "cursor-pointer hover:bg-wrap"
        ]}
      >
        <span
          aria-hidden="true"
          class={[
            "flex size-6.5 shrink-0 items-center justify-center rounded-lg text-[11px] font-semibold",
            mark_class(Map.get(option, :tone))
          ]}
        >
          {render_slot(option)}
        </span>
        <span class="min-w-0">
          <span class="block truncate font-medium">{option.title}</span>
          <span :if={Map.get(option, :hint)} class="block truncate text-xs text-muted">
            {option.hint}
          </span>
        </span>
        <kbd :if={index == @active} class="ml-auto font-mono text-[11px] text-muted">{@enter}</kbd>
      </div>
    </div>
    """
  end

  defp mark_class(nil), do: "bg-ink text-on-primary"
  defp mark_class(:ink), do: "bg-ink text-on-primary"
  defp mark_class(tone), do: [Tone.bg(tone), Tone.text(tone)]
end
