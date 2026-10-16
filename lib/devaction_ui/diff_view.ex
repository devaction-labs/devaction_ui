defmodule DevactionUI.DiffView do
  @moduledoc """
  The diff of one file in a review: a header with the path, the lines added and removed and a "viewed" checkbox,
  and the unified diff as a table with the old and the new line numbers, a gutter with the button that adds a
  comment, and tinted rows for the added and the removed lines. `line_thread/1` is the conversation that hangs
  from a line.

  The diff comes as data, never as text to parse: `hunks` is a list of `%{header: "@@ -12,6 +12,9 @@", lines:
  [...]}` (the `header` is optional) and each line is `%{old: 15, new: nil, kind: :del, text: "..."}`, where
  `kind` is `:context`, `:add` or `:del` and the number that does not exist is `nil`. With `lang: :elixir` the
  code is coloured through `DevactionUI.Highlight`; without it the row's own colour is used. The sign of the
  line (a space, `+` or `-`) is part of the text, so the difference is not only a colour.

  A thread is a `:thread` slot with the `line` it hangs from and its `side` (`:new`, the default, or `:old`);
  it opens under that line, and the button of that line turns amber. The button of a line sends
  `comment_event` with `path`, `line` and `side`; a removed line has no button unless `comment_removed` is
  set. The checkbox sends `viewed_event` with `path`. Events are attributes (a string or a `%JS{}`) and
  `target` is the `phx-target` when used inside a LiveComponent. The icons come through slots; the button
  falls back to `+` and the checkbox to `✓`.
  """
  use Phoenix.Component

  alias DevactionUI.Highlight

  @type line :: %{
          required(:kind) => :context | :add | :del,
          required(:text) => String.t(),
          optional(:old) => pos_integer() | nil,
          optional(:new) => pos_integer() | nil
        }
  @type hunk :: %{optional(:header) => String.t() | nil, required(:lines) => [line()]}

  attr :id, :string, required: true
  attr :path, :string, required: true, doc: "the path of the file, shown in the header"
  attr :hunks, :list, required: true, doc: "the diff as data; see the module documentation"

  attr :additions, :integer,
    default: nil,
    doc: "the lines added in the header; counted from the hunks when not given"

  attr :deletions, :integer,
    default: nil,
    doc: "the lines removed in the header; counted from the hunks when not given"

  attr :lang, :atom,
    values: [nil, :elixir],
    default: nil,
    doc: "`:elixir` colours the code through `DevactionUI.Highlight`"

  attr :viewed, :boolean, default: false, doc: "the file is marked as viewed"
  attr :viewed_label, :string, required: true, doc: "the label of the viewed checkbox"
  attr :viewed_event, :any, default: nil, doc: "sent with `path` when the checkbox is pressed"

  attr :comment_label, :string,
    required: true,
    doc: "names the button of a line, as in `\"Comment on line %{line}\"`"

  attr :comment_event, :any,
    default: nil,
    doc: "sent with `path`, `line` and `side` when the button of a line is pressed"

  attr :comment_removed, :boolean,
    default: false,
    doc: "removed lines get the comment button too (on the old side)"

  attr :target, :any,
    default: nil,
    doc: "a `phx-target` (a `@myself`) when used inside a LiveComponent"

  attr :class, :any, default: nil
  attr :rest, :global

  slot :thread, doc: "a conversation hung from a line; its content is a `line_thread/1`" do
    attr :line, :integer, required: true, doc: "the number of the line it hangs from"
    attr :side, :atom, doc: "`:new` (the default) or `:old`"
  end

  slot :file_icon, doc: "the icon before the path"
  slot :comment_icon, doc: "the content of the comment button; without it, `+`"
  slot :check_icon, doc: "the mark of the checked viewed checkbox; without it, `✓`"

  @doc "The header and the unified diff of one file."
  @spec diff(map()) :: Phoenix.LiveView.Rendered.t()
  def diff(assigns) do
    rows = rows(assigns.hunks, assigns.lang)
    counts = counts(assigns.hunks)

    assigns =
      assign(assigns,
        rows: rows,
        added: assigns.additions || counts.additions,
        removed: assigns.deletions || counts.deletions
      )

    ~H"""
    <section id={@id} class={["flex min-h-0 min-w-0 flex-col text-ink", @class]} {@rest}>
      <div class="flex h-[52px] shrink-0 items-center gap-2.5 border-b border-line-soft px-4">
        <span :if={@file_icon != []} aria-hidden="true" class="flex size-4 shrink-0 text-muted">
          {render_slot(@file_icon)}
        </span>
        <span class="min-w-0 truncate font-mono text-[13px]">{@path}</span>
        <span class="shrink-0 font-mono text-[11px]">
          <span class="text-tag-ok-text">+{@added}</span>
          <span class="text-tag-risk-text">−{@removed}</span>
        </span>
        <label class="ml-auto flex shrink-0 cursor-pointer items-center gap-1.5 text-[13px] text-diff-soft-fg">
          <input
            type="checkbox"
            checked={@viewed}
            phx-click={@viewed_event}
            phx-target={@target}
            phx-value-path={@path}
            class="peer sr-only"
          />
          <span
            aria-hidden="true"
            class="grid size-4 place-items-center rounded border border-done text-[11px] leading-none text-transparent peer-checked:border-ink peer-checked:bg-ink peer-checked:text-on-ink peer-focus-visible:ring-4 peer-focus-visible:ring-ink/10"
          >
            {render_slot(@check_icon) || "✓"}
          </span>
          {@viewed_label}
        </label>
      </div>
      <div class="min-h-0 flex-1 overflow-auto">
        <table aria-label={@path} class="w-full min-w-max table-fixed border-collapse">
          <colgroup>
            <col class="w-11" />
            <col class="w-11" />
            <col class="w-[22px]" />
            <col />
          </colgroup>
          <tbody :for={row <- @rows} data-row={row.type}>
            <tr :if={row.type == :header} class="h-[26px] bg-diff-surface">
              <td colspan="4" class="px-4 font-mono text-xs text-muted">{row.text}</td>
            </tr>
            <tr
              :if={row.type == :line}
              data-kind={row.kind}
              class={["h-[26px] font-mono text-[12.5px] leading-none", row_class(row.kind)]}
            >
              <td class="pr-2 text-right text-muted-2 select-none">{row.old}</td>
              <td class="pr-2 text-right text-muted-2 select-none">{row.new}</td>
              <td class="p-0 text-center">
                <button
                  :if={commentable?(row, @comment_removed)}
                  type="button"
                  aria-label={fill_label(@comment_label, row.line)}
                  phx-click={@comment_event}
                  phx-target={@target}
                  phx-value-path={@path}
                  phx-value-line={row.line}
                  phx-value-side={row.side}
                  class={[
                    "inline-grid size-[18px] cursor-pointer place-items-center rounded-[5px] border-0 p-0 text-[13px] leading-none outline-none focus-visible:ring-4 focus-visible:ring-ink/10",
                    button_class(threads_for(@thread, row) != [])
                  ]}
                >
                  {render_slot(@comment_icon) || "+"}
                </button>
              </td>
              <td class="py-1.5 pr-4 whitespace-pre" phx-no-format>{sign(row.kind)} <span :for={{kind, text} <- row.tokens} class={token_class(kind)}>{text}</span></td>
            </tr>
            <tr :for={thread <- threads_for(@thread, row)} data-thread>
              <td
                colspan="4"
                class="border-y border-line-soft bg-diff-surface py-2.5 pr-4 pl-[110px] text-sm leading-normal"
              >
                {render_slot([thread])}
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>
    """
  end

  attr :id, :string, required: true

  attr :label, :string,
    required: true,
    doc: "the name of the conversation for assistive technology"

  attr :path, :string, required: true, doc: "the file the conversation is about"
  attr :line, :integer, required: true, doc: "the line it hangs from"
  attr :side, :atom, values: [:new, :old], default: :new

  attr :placeholder, :string, required: true, doc: "the placeholder of the reply field"
  attr :reply_label, :string, required: true, doc: "the name of the reply field"

  attr :note, :string,
    required: true,
    doc: "the small note under the field, e.g. `Markdown supported`"

  attr :resolve_label, :string,
    required: true,
    doc: "the label of the button that closes the thread"

  attr :comment_label, :string,
    required: true,
    doc: "the label of the button that sends the reply"

  attr :suggestion_label, :string,
    default: nil,
    doc: "the title of a suggested change"

  attr :apply_label, :string,
    default: nil,
    doc: "the label of the button that applies a suggested change"

  attr :resolved, :boolean,
    default: false,
    doc: "the thread is closed: the `:summary` slot shows instead, or nothing without it"

  attr :resolve_event, :any, default: nil, doc: "sent with `path`, `line` and `side`"

  attr :comment_event, :any,
    default: nil,
    doc: "the form's submit event, with `body`, `path`, `line` and `side`"

  attr :apply_event, :any, default: nil, doc: "sent with `path`, `line`, `side` and `message`"

  attr :target, :any,
    default: nil,
    doc: "a `phx-target` (a `@myself`) when used inside a LiveComponent"

  attr :class, :any, default: nil
  attr :rest, :global

  slot :message, required: true, doc: "one message; its content is the text" do
    attr :id, :string, doc: "sent as `message` when its suggestion is applied"
    attr :author, :string, required: true
    attr :initials, :string, required: true, doc: "in the square before the author"
    attr :time, :string, doc: "when it was written, as text"
    attr :ai_label, :string, doc: "the tag after the author; given, the author is an AI"

    attr :suggestion, :map, doc: "a suggested change, `%{from: \"old line\", to: \"new line\"}`"
  end

  slot :summary, doc: "what shows in place of the thread when it is resolved"

  @doc "The conversation attached to a line of the diff."
  @spec line_thread(map()) :: Phoenix.LiveView.Rendered.t()
  def line_thread(%{resolved: true} = assigns) do
    ~H"""
    <div
      :if={@summary != []}
      id={@id}
      data-resolved
      class={["max-w-[680px] text-[13px] text-muted", @class]}
      {@rest}
    >
      {render_slot(@summary)}
    </div>
    """
  end

  def line_thread(assigns) do
    ~H"""
    <div
      id={@id}
      role="group"
      aria-label={@label}
      class={[
        "max-w-[680px] overflow-hidden rounded-xl border border-line bg-card text-ink",
        @class
      ]}
      {@rest}
    >
      <div
        :for={message <- @message}
        class="flex gap-2.5 border-b border-line-soft px-3.5 py-3"
      >
        <span
          aria-hidden="true"
          class={[
            "flex size-[26px] shrink-0 items-center justify-center rounded-lg text-[11px] font-semibold",
            avatar_class(message)
          ]}
        >
          {message.initials}
        </span>
        <div class="min-w-0 flex-1">
          <div class="flex items-center gap-2 text-[13px]">
            <span class="font-semibold">{message.author}</span>
            <span
              :if={Map.get(message, :ai_label)}
              class="inline-flex h-[18px] items-center rounded-[5px] border border-tag-warn-line bg-tag-warn-bg px-1.5 font-mono text-[10px] text-tag-warn-text"
            >
              {message.ai_label}
            </span>
            <span :if={Map.get(message, :time)} class="text-muted">{message.time}</span>
          </div>
          <div class="mt-1 text-ink-2">{render_slot(message)}</div>
          <.suggestion
            :if={Map.get(message, :suggestion)}
            suggestion={message.suggestion}
            label={@suggestion_label}
            apply_label={@apply_label}
            message={Map.get(message, :id)}
            event={@apply_event}
            target={@target}
            path={@path}
            line={@line}
            side={@side}
          />
        </div>
      </div>
      <form
        id={"#{@id}-reply"}
        phx-submit={@comment_event}
        phx-target={@target}
        class="flex flex-col gap-2 px-3.5 py-2.5"
      >
        <input type="hidden" name="path" value={@path} />
        <input type="hidden" name="line" value={@line} />
        <input type="hidden" name="side" value={@side} />
        <textarea
          name="body"
          rows="2"
          placeholder={@placeholder}
          aria-label={@reply_label}
          class="min-h-14 w-full resize-y rounded-lg border border-done bg-transparent px-2.5 py-2 text-sm text-ink outline-none placeholder:text-muted-2 focus-visible:ring-4 focus-visible:ring-ink/10"
        ></textarea>
        <div class="flex items-center gap-2">
          <span class="text-xs text-muted">{@note}</span>
          <button
            type="button"
            phx-click={@resolve_event}
            phx-target={@target}
            phx-value-path={@path}
            phx-value-line={@line}
            phx-value-side={@side}
            class="ml-auto h-[30px] cursor-pointer rounded-lg border border-line bg-card px-2.5 text-[13px] text-ink outline-none hover:bg-wrap focus-visible:ring-4 focus-visible:ring-ink/10"
          >
            {@resolve_label}
          </button>
          <button
            type="submit"
            class="h-[30px] cursor-pointer rounded-lg border border-ink bg-ink px-3 text-[13px] font-medium text-on-ink outline-none focus-visible:ring-4 focus-visible:ring-ink/20"
          >
            {@comment_label}
          </button>
        </div>
      </form>
    </div>
    """
  end

  attr :suggestion, :map, required: true
  attr :label, :string, required: true
  attr :apply_label, :string, required: true
  attr :message, :string, default: nil
  attr :event, :any, required: true
  attr :target, :any, required: true
  attr :path, :string, required: true
  attr :line, :integer, required: true
  attr :side, :atom, required: true

  defp suggestion(assigns) do
    ~H"""
    <div class="mt-2 overflow-hidden rounded-lg border border-line font-mono text-xs">
      <div class="flex items-center bg-diff-surface px-2.5 py-1.5 font-sans text-xs text-diff-soft-fg">
        {@label}
        <button
          type="button"
          phx-click={@event}
          phx-target={@target}
          phx-value-path={@path}
          phx-value-line={@line}
          phx-value-side={@side}
          phx-value-message={@message}
          class="ml-auto cursor-pointer rounded border-0 bg-transparent p-0 font-medium text-ink outline-none focus-visible:ring-4 focus-visible:ring-ink/10"
        >
          {@apply_label}
        </button>
      </div>
      <div class="bg-tag-risk-bg px-2.5 py-1.5 whitespace-pre text-tag-risk-text">
        - {@suggestion.from}
      </div>
      <div class="bg-tag-ok-bg px-2.5 py-1.5 whitespace-pre text-tag-ok-text">+ {@suggestion.to}</div>
    </div>
    """
  end

  defp rows(hunks, lang), do: Enum.flat_map(hunks, &hunk_rows(&1, lang))

  defp hunk_rows(%{header: header, lines: lines}, lang) when is_binary(header),
    do: [%{type: :header, text: header} | Enum.map(lines, &line_row(&1, lang))]

  defp hunk_rows(%{lines: lines}, lang), do: Enum.map(lines, &line_row(&1, lang))

  defp line_row(%{kind: kind, text: text} = line, lang) do
    old = Map.get(line, :old)
    new = Map.get(line, :new)

    %{
      type: :line,
      kind: kind,
      old: old,
      new: new,
      text: text,
      tokens: tokens(text, lang),
      line: new || old,
      side: side(kind)
    }
  end

  defp side(:del), do: :old
  defp side(_kind), do: :new

  defp tokens(text, :elixir), do: Highlight.elixir(text)
  defp tokens(text, nil), do: [{:text, text}]

  defp counts(hunks) do
    lines = Enum.flat_map(hunks, & &1.lines)

    %{
      additions: Enum.count(lines, &(&1.kind == :add)),
      deletions: Enum.count(lines, &(&1.kind == :del))
    }
  end

  defp threads_for(threads, %{type: :line, line: line, side: side}),
    do: Enum.filter(threads, &(&1.line == line and Map.get(&1, :side, :new) == side))

  defp threads_for(_threads, _row), do: []

  defp commentable?(%{kind: :del}, comment_removed), do: comment_removed
  defp commentable?(_row, _comment_removed), do: true

  defp sign(:add), do: "+"
  defp sign(:del), do: "-"
  defp sign(:context), do: " "

  defp row_class(:add), do: "bg-tag-ok-bg text-diff-add-fg"
  defp row_class(:del), do: "bg-tag-risk-bg text-diff-del-fg"
  defp row_class(:context), do: "text-diff-ctx-fg"

  defp button_class(true), do: "bg-ai text-on-finding"
  defp button_class(false), do: "bg-line text-diff-soft-fg"

  defp avatar_class(%{ai_label: label}) when is_binary(label),
    do: "bg-tag-warn-bg text-tag-warn-text"

  defp avatar_class(_message), do: "bg-ink text-on-ink"

  defp fill_label(label, line), do: String.replace(label, "%{line}", to_string(line))

  defp token_class(kind) when kind in [:keyword, :directive], do: "text-tag-indigo-text"
  defp token_class(kind) when kind in [:atom, :number, :expr], do: "text-tag-warn-text"
  defp token_class(kind) when kind in [:module, :html, :component], do: "text-tag-info-text"
  defp token_class(kind) when kind in [:assign, :slot, :string], do: "text-tag-emerald-text"
  defp token_class(:comment), do: "text-muted italic"
  defp token_class(_kind), do: nil
end
