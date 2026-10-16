defmodule DevactionUI.ComposerTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.Composer
  alias Phoenix.LiveView.Socket

  defp has?(html, selector),
    do: html |> LazyHTML.from_fragment() |> LazyHTML.query(selector) |> Enum.count() > 0

  defp attribute(html, selector, name),
    do:
      html
      |> LazyHTML.from_fragment()
      |> LazyHTML.query(selector)
      |> LazyHTML.attribute(name)

  defp upload do
    socket = %Socket{assigns: %{__changed__: %{}, flash: %{}}}

    socket
    |> Phoenix.LiveView.allow_upload(:attachments, accept: :any, max_entries: 3)
    |> then(& &1.assigns.uploads.attachments)
  end

  defp composer(extra \\ %{}) do
    assigns =
      Map.merge(
        %{busy: false, upload: nil, change_event: nil, stop_event: nil, target: nil, value: ""},
        extra
      )

    rendered_to_string(~H"""
    <Composer.composer
      id="chat"
      event="send"
      label="Message"
      send_label="Send"
      stop_label="Stop"
      placeholder="Ask about the project"
      max_length={4000}
      busy={@busy}
      upload={@upload}
      change_event={@change_event}
      stop_event={@stop_event}
      target={@target}
      value={@value}
      data-extra="yes"
    >
      <:icon>SEND-ICON</:icon>
      <:stop>STOP-ICON</:stop>
      <:leading>
        <Composer.button label="Dictate"><:icon>MIC</:icon></Composer.button>
      </:leading>
    </Composer.composer>
    """)
  end

  test "is a form that sends the text under its name, with the hook on the card" do
    html = composer()

    assert has?(html, "form#chat-form[phx-submit=send]")
    assert has?(html, "form[data-extra=yes]")
    assert has?(html, "form #chat.composer[phx-hook='DevactionUI.Composer']")
    assert has?(html, "textarea[name=prompt][data-composer-input][rows='1']")
    assert has?(html, "label[for=chat-input].sr-only")
    assert html =~ "Message"
    assert has?(html, "textarea[placeholder='Ask about the project']")
  end

  test "the card carries its limits for the hook" do
    html = composer()

    assert attribute(html, "#chat", "data-max-rows") == ["8"]
    assert attribute(html, "#chat", "data-max-length") == ["4000"]
    assert attribute(html, "#chat", "data-busy") == ["false"]
    assert attribute(html, "#chat", "data-size") == ["md"]
  end

  test "the hook's own attributes survive a patch" do
    html = composer()

    assert html =~ "ignore_attrs"
    assert has?(html, "#chat-count[phx-update=ignore][hidden]")
  end

  test "an empty field starts with the send button off, a filled one with it on" do
    assert has?(composer(), "button.composer-send[type=submit][disabled]")
    refute has?(composer(%{value: "hello"}), "button.composer-send[disabled]")
  end

  test "the text the field starts with is its content" do
    assert composer(%{value: "hello"}) =~ "hello</textarea>"
  end

  test "the send button has its icons and its name" do
    html = composer()

    assert html =~ "SEND-ICON"
    assert html =~ "STOP-ICON"
    assert attribute(html, "button.composer-send", "aria-label") == ["Send"]
    refute has?(html, "button.composer-send[data-stop]")
  end

  test "busy makes the field read only and the send button a stop button" do
    html = composer(%{busy: true})

    assert attribute(html, "#chat", "data-busy") == ["true"]
    assert has?(html, "textarea[readonly]")
    assert has?(html, "button.composer-send[data-stop]:not([disabled])")
    assert attribute(html, "button.composer-send", "aria-label") == ["Stop"]
  end

  test "the stop event is a push command, aimed at the target when there is one" do
    assert attribute(composer(), "#chat", "data-stop") == []

    plain = composer(%{stop_event: "stop"})
    assert [command] = attribute(plain, "#chat", "data-stop")
    assert command =~ "push"
    assert command =~ "stop"
    refute command =~ "target"

    aimed = composer(%{stop_event: "stop", target: "#panel"})
    assert [command] = attribute(aimed, "#chat", "data-stop")
    assert command =~ "#panel"
  end

  test "the actions of the row come in slots" do
    html = composer()

    assert has?(html, ".composer-leading button.composer-btn[aria-label=Dictate][type=button]")
    assert html =~ "MIC"
    refute has?(html, ".composer-header")
  end

  test "an upload adds the file input the hook feeds, and a form that listens to changes" do
    html = composer(%{upload: upload(), change_event: "validate"})

    assert has?(html, "form[phx-change=validate]")
    assert has?(html, "input[type=file][data-composer-files].hidden")
  end

  test "an upload without a change event is refused" do
    assert_raise ArgumentError, ~r/change_event/, fn ->
      composer(%{upload: upload()})
    end
  end

  test "an action given the upload is the label of its file input" do
    upload = upload()
    assigns = %{upload: upload}

    html =
      rendered_to_string(~H"""
      <Composer.button label="Attach" upload={@upload} variant={:filled}>
        <:icon>CLIP</:icon>
      </Composer.button>
      """)

    assert has?(html, "label.composer-btn[role=button][data-variant=filled][aria-label=Attach]")
    assert attribute(html, "label", "for") == [upload.ref]
  end

  test "a file chip names its file, shows progress and removes by ref" do
    entry = %Phoenix.LiveView.UploadEntry{
      ref: "7",
      client_name: "notes.txt",
      client_type: "text/plain",
      progress: 40
    }

    assigns = %{entry: entry}

    html =
      rendered_to_string(~H"""
      <Composer.file entry={@entry} remove_label="Remove notes.txt" cancel_event="drop" target="#panel">
        <:icon>X</:icon>
      </Composer.file>
      """)

    assert html =~ "notes.txt"
    assert html =~ "40%"

    assert has?(
             html,
             "button.composer-file-remove[phx-click=drop][phx-value-ref='7'][phx-target='#panel'][aria-label='Remove notes.txt']"
           )
  end
end
