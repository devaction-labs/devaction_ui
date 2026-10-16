defmodule DevactionUI.DropzoneTest do
  @moduledoc "The drop area over a LiveView upload: the label that takes the drop, the files and the errors."
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.Dropzone
  alias Phoenix.LiveView.{Socket, UploadEntry}

  defp upload(entries \\ []) do
    socket =
      Phoenix.LiveView.allow_upload(
        %Socket{assigns: %{__changed__: %{}, flash: %{}}},
        :transcript,
        accept: ~w(.txt .mp3)
      )

    %{socket.assigns.uploads.transcript | entries: entries}
  end

  defp entry(name, progress),
    do: %UploadEntry{ref: name, client_name: name, progress: progress, uuid: "u-#{name}"}

  defp render_zone(extra \\ %{}) do
    assigns = Map.merge(%{upload: upload(), errors: [], disabled: false}, extra)

    rendered_to_string(~H"""
    <Dropzone.dropzone
      id="dz"
      upload={@upload}
      title="Drop the transcript"
      hint=".txt · up to 200 MB"
      errors={@errors}
      disabled={@disabled}
    >
      <:icon>ICON</:icon>
      <:entry :let={entry}>{entry.client_name}: {entry.progress}%</:entry>
    </Dropzone.dropzone>
    """)
  end

  test "the area is a label over the file input and takes the drop" do
    html = render_zone()

    assert html =~ ~s(phx-hook="DevactionUI.Dropzone")
    assert html =~ ~r/<label[^>]*phx-drop-target="phx-/
    assert html =~ ~s(type="file")
    assert html =~ "Drop the transcript"
    assert html =~ ".txt · up to 200 MB"
    assert html =~ "border-dashed"
  end

  test "the icon sits in a 22px box and the colours are tokens" do
    html = render_zone()

    assert html =~ ~r/size-5\.5[^>]*>\s*ICON/
    assert html =~ "border-line-strong"
    assert html =~ "bg-wrap"
    refute html =~ ~r/#[0-9A-Fa-f]{6}/
  end

  test "each chosen file is drawn by the caller's slot, with its progress" do
    html = render_zone(%{upload: upload([entry("a.txt", 40), entry("b.txt", 100)])})

    assert html =~ "a.txt: 40%"
    assert html =~ "b.txt: 100%"
    refute render_zone() =~ "<ul"
  end

  test "the errors are alerts, and the file input points at them" do
    html = render_zone(%{errors: ["Too large", "Not a text"]})

    assert length(Regex.scan(~r/role="alert"/, html)) == 2
    assert html =~ ~s(id="dz-errors")
    assert html =~ ~r/<input[^>]*aria-describedby="dz-errors"/s
    refute render_zone() =~ "aria-describedby"
  end

  test "disabled takes neither a click nor a drop" do
    html = render_zone(%{disabled: true})

    assert html =~ ~s(aria-disabled="true")
    refute html =~ "phx-drop-target"
    assert html =~ ~r/<input[^>]*type="file"[^>]* disabled/s
  end
end
