defmodule DevactionUI.EditorTest do
  @moduledoc "The editor component: the toolbar it draws from its tools, the inputs it sends and what it leaves to the hook."
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.Editor

  defp editor(extra \\ %{}) do
    assigns =
      Map.merge(
        %{styles: [{"Paragraph", "paragraph"}, {"Heading", "h2"}], value: "<p>hi</p>"},
        extra
      )

    rendered_to_string(~H"""
    <Editor.editor
      id="e"
      name="note"
      label="Notes"
      placeholder="Write"
      styles={@styles}
      value={@value}
    >
      <:tool name="bold" label="Bold">B</:tool>
      <:tool name="italic" label="Italic" separator>I</:tool>
      <:tool name="link" label="Link">L</:tool>
    </Editor.editor>
    """)
  end

  test "is a hook that LiveView leaves alone, named by its label" do
    html = editor()

    assert html =~ ~s(phx-hook="DevactionUI.Editor")
    assert html =~ ~s(phx-update="ignore")
    assert html =~ ~s(data-label="Notes")
    assert html =~ ~s(data-placeholder="Write")
    assert html =~ ~s(role="toolbar")
  end

  test "draws a button for each tool, a divider where asked and the link on its own" do
    html = editor()

    assert html =~
             ~r/id="e-tool-bold"[^>]*data-command="bold"|data-command="bold"[^>]*id="e-tool-bold"/s

    assert html =~ ~s(aria-label="Italic")
    assert length(Regex.scan(~r/class="editor-sep"/, html)) == 1
    assert html =~ ~r/id="e-tool-link"[^>]*data-link|data-link[^>]*id="e-tool-link"/s
    refute html =~ ~s(data-command="link")
  end

  test "sends the text as HTML and as Markdown, starting from the HTML it was given" do
    html = editor()

    assert html =~ ~s(name="note[html]")
    assert html =~ ~s(name="note[markdown]")
    assert html =~ "&lt;p&gt;hi&lt;/p&gt;"
  end

  test "gives the hook the slash menu, the members and the send key" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Editor.editor
        id="c"
        name="comment"
        label="Comment"
        compact
        send_on_enter
        slash={[%{key: "h2", label: "Heading 2"}]}
        mentions={[%{id: "u1", label: "Maria"}]}
      />
      """)

    assert html =~ ~s(data-send="true")
    assert html =~ "editor editor-compact"

    assert html =~ "&quot;key&quot;:&quot;h2&quot;"
    assert html =~ "&quot;label&quot;:&quot;Heading 2&quot;"
    assert html =~ "&quot;id&quot;:&quot;u1&quot;"
    refute html =~ ~s(role="toolbar")
  end

  test "the menus and the send key are off by default" do
    html = editor()

    assert html =~ ~s(data-slash="[]")
    assert html =~ ~s(data-mentions="[]")
    assert html =~ ~s(data-send="false")
  end

  test "the image tool needs an upload address, and gives the hook what it needs to send" do
    assigns = %{}

    off =
      rendered_to_string(~H"""
      <Editor.editor id="e" name="n" label="L">
        <:tool name="image" label="Image">I</:tool>
      </Editor.editor>
      """)

    refute off =~ ~s(type="file")

    on =
      rendered_to_string(~H"""
      <Editor.editor
        id="e"
        name="n"
        label="L"
        upload_url="/uploads/images"
        upload_errors={%{"failed" => "No"}}
      >
        <:tool name="image" label="Image">I</:tool>
      </Editor.editor>
      """)

    assert on =~ ~s(data-upload-url="/uploads/images")
    assert on =~ ~s(data-upload-max="5242880")
    assert on =~ "&quot;failed&quot;:&quot;No&quot;"
    assert on =~ ~s(type="file")
    assert on =~ ~s(data-image)
    assert on =~ ~s(data-editor-status)
    refute on =~ ~s(data-command="image")
  end

  test "the style select shows only when styles are given, and the link bar starts hidden" do
    assert editor() =~ ~s(data-style)
    refute editor(%{styles: []}) =~ ~s(data-style)
    assert editor() =~ ~r/data-link-bar[^>]*hidden|hidden[^>]*data-link-bar/s
  end
end
