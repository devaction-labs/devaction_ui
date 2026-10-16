defmodule DevactionUI.DiffViewTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.DiffView

  @hunks [
    %{
      header: "@@ -12,3 +12,4 @@",
      lines: [
        %{old: 12, new: 12, kind: :context, text: "defmodule A do"},
        %{old: 13, new: nil, kind: :del, text: "  @a 1"},
        %{old: nil, new: 13, kind: :add, text: "  @a 2"},
        %{old: nil, new: 14, kind: :add, text: "  def a, do: :ok"}
      ]
    },
    %{lines: [%{old: 40, new: 41, kind: :context, text: "end"}]}
  ]

  defp render_diff(extra \\ %{}) do
    assigns = Map.merge(%{hunks: @hunks, viewed: false, lang: nil, removed?: false}, extra)

    rendered_to_string(~H"""
    <DiffView.diff
      id="d"
      path="lib/a.ex"
      hunks={@hunks}
      viewed={@viewed}
      lang={@lang}
      comment_removed={@removed?}
      viewed_label="Viewed"
      viewed_event="viewed"
      comment_label="Comment on line %{line}"
      comment_event="comment"
    >
      <:thread line={14}>THREAD-NEW</:thread>
      <:thread line={13} side={:old}>THREAD-OLD</:thread>
    </DiffView.diff>
    """)
  end

  test "the header has the path, the counts from the hunks and the viewed checkbox" do
    html = render_diff()
    assert html =~ "lib/a.ex"
    assert html =~ "+2"
    assert html =~ "−1"
    assert html =~ ~r/type="checkbox"[^>]*phx-click="viewed"[^>]*phx-value-path="lib\/a.ex"/s
    assert html =~ "Viewed"
  end

  test "given counts win over the counted ones" do
    assigns = %{hunks: @hunks}

    html =
      rendered_to_string(~H"""
      <DiffView.diff
        id="d"
        path="a"
        hunks={@hunks}
        additions={18}
        deletions={6}
        viewed_label="V"
        comment_label="C %{line}"
      />
      """)

    assert html =~ "+18"
    assert html =~ "−6"
  end

  test "viewed checks the box" do
    assert render_diff(%{viewed: true}) =~ ~r/type="checkbox"[^>]*checked/s
    refute render_diff() =~ ~r/type="checkbox"[^>]*checked/s
  end

  test "rows carry their numbers, signs and tints" do
    html = render_diff()
    assert html =~ ~s(data-kind="add")
    assert html =~ "bg-tag-ok-bg text-diff-add-fg"
    assert html =~ "bg-tag-risk-bg text-diff-del-fg"
    assert html =~ ~r/data-kind="del".*?>\s*13\s*<\/td>/s
    assert html =~ ~r/>\+ <span/
    assert html =~ ~r/>- <span/
  end

  test "a hunk with a header gets a header row and one without does not" do
    html = render_diff()
    assert html =~ "@@ -12,3 +12,4 @@"
    assert length(Regex.scan(~r/data-row="header"/, html)) == 1
  end

  test "the comment button sends the path, the line and the side" do
    html = render_diff()
    assert html =~ ~s(aria-label="Comment on line 14")

    assert html =~
             ~r/phx-click="comment"[^>]*phx-value-path="lib\/a.ex"[^>]*phx-value-line="14"[^>]*phx-value-side="new"/s
  end

  test "removed lines have no button unless asked" do
    assert length(Regex.scan(~r/<button/, render_diff())) == 4
    refute render_diff() =~ ~s(phx-value-side="old")
    assert length(Regex.scan(~r/<button/, render_diff(%{removed?: true}))) == 5
    assert render_diff(%{removed?: true}) =~ ~s(phx-value-side="old")
  end

  test "a thread opens under its line, on its side, and tints the button" do
    html = render_diff(%{removed?: true})
    assert html =~ "THREAD-NEW"
    assert html =~ "THREAD-OLD"
    assert html =~ "bg-ai text-on-finding"
    [before_new, _rest] = String.split(html, "THREAD-NEW")
    assert before_new =~ "def a, do: :ok"
    [before_old, _rest] = String.split(html, "THREAD-OLD")
    assert before_old =~ "@a 1"
    refute before_old =~ "@a 2"
  end

  test "without lang the code is one piece and with :elixir it is coloured" do
    refute render_diff() =~ "text-tag-indigo-text"
    assert render_diff(%{lang: :elixir}) =~ "text-tag-indigo-text"
  end

  test "icons come from slots with a glyph fallback" do
    assigns = %{hunks: @hunks}

    html =
      rendered_to_string(~H"""
      <DiffView.diff id="d" path="a" hunks={@hunks} viewed_label="V" comment_label="C %{line}">
        <:file_icon><i class="fi"></i></:file_icon>
        <:comment_icon><i class="ci"></i></:comment_icon>
        <:check_icon><i class="ki"></i></:check_icon>
      </DiffView.diff>
      """)

    assert html =~ ~s(class="fi")
    assert html =~ ~s(class="ci")
    assert html =~ ~s(class="ki")
    refute html =~ "✓"
    assert render_diff() =~ "✓"
  end

  defp render_thread(extra \\ %{}) do
    assigns = Map.merge(%{resolved: false}, extra)

    rendered_to_string(~H"""
    <DiffView.line_thread
      id="th"
      label="Conversation on line 18"
      path="lib/a.ex"
      line={18}
      resolved={@resolved}
      placeholder="Reply…"
      reply_label="Reply"
      note="Markdown supported"
      resolve_label="Resolve"
      comment_label="Comment"
      suggestion_label="Suggested change"
      apply_label="Apply suggestion"
      resolve_event="resolve"
      comment_event="reply"
      apply_event="apply"
    >
      <:message author="Reviewer" initials="AI" time="now" ai_label="AI">first</:message>
      <:message
        id="m2"
        author="Alex"
        initials="AN"
        time="2 min ago"
        suggestion={%{from: "a(1)", to: "a(2)"}}
      >
        second
      </:message>
      <:summary>Resolved</:summary>
    </DiffView.line_thread>
    """)
  end

  test "a thread is a named group with its messages, the AI tag and times" do
    html = render_thread()
    assert html =~ ~s(role="group")
    assert html =~ ~s(aria-label="Conversation on line 18")
    assert html =~ "Reviewer"
    assert html =~ "first"
    assert html =~ "2 min ago"
    assert length(Regex.scan(~r/>\s*AI\s*</, html)) == 2
  end

  test "the AI author has the amber avatar and the human the ink one" do
    html = render_thread()
    assert html =~ "bg-tag-warn-bg text-tag-warn-text"
    assert html =~ "bg-ink text-on-ink"
  end

  test "a suggestion shows the red and green lines and the apply action with the message" do
    html = render_thread()
    assert html =~ "Suggested change"
    assert html =~ "- a(1)"
    assert html =~ "+ a(2)"
    assert html =~ ~r/phx-click="apply"[^>]*phx-value-message="m2"/s
    assert html =~ "Apply suggestion"
  end

  test "the reply form has the field, the note and the two buttons" do
    html = render_thread()
    assert html =~ ~s(phx-submit="reply")
    assert html =~ ~s(placeholder="Reply…")
    assert html =~ ~s(aria-label="Reply")
    assert html =~ "Markdown supported"

    assert html =~
             ~r/phx-click="resolve"[^>]*phx-value-path="lib\/a.ex"[^>]*phx-value-line="18"/s

    assert html =~ ~r/type="submit"[^>]*>\s*Comment\s*</
    assert html =~ ~s(name="line" value="18")
    assert html =~ ~s(name="side" value="new")
  end

  test "a resolved thread collapses to its summary" do
    html = render_thread(%{resolved: true})
    assert html =~ "Resolved"
    assert html =~ "data-resolved"
    refute html =~ "<textarea"
  end

  test "a resolved thread without a summary draws nothing" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <DiffView.line_thread
        id="th"
        label="L"
        path="a"
        line={1}
        resolved
        placeholder="p"
        reply_label="r"
        note="n"
        resolve_label="x"
        comment_label="c"
      >
        <:message author="A" initials="A">hi</:message>
      </DiffView.line_thread>
      """)

    refute html =~ "textarea"
    refute html =~ "hi"
  end
end
