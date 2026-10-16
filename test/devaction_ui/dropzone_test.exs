defmodule DevactionUI.DropzoneTest do
  @moduledoc "The drop area over a LiveView upload: the label that takes the drop, the files, the limits and the errors."
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.Dropzone
  alias Phoenix.LiveView.{Socket, UploadEntry}

  defp upload(entries \\ [], errors \\ [], opts \\ []) do
    socket =
      Phoenix.LiveView.allow_upload(
        %Socket{assigns: %{__changed__: %{}, flash: %{}}},
        :transcript,
        Keyword.merge([accept: ~w(.txt .mp3), max_file_size: 200_000_000], opts)
      )

    conf = socket.assigns.uploads.transcript

    %{
      conf
      | entries: entries,
        errors: Enum.map(errors, fn {ref, error} -> {ref(conf, ref), error} end)
    }
  end

  defp ref(conf, :upload), do: conf.ref
  defp ref(_conf, ref), do: ref

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

  defp render_default(extra) do
    assigns = %{upload: extra[:upload] || upload(), extra: extra}

    rendered_to_string(~H"""
    <Dropzone.dropzone
      id="dz"
      upload={@upload}
      title="Drop"
      cancel_event={@extra[:cancel_event]}
      cancel_label={@extra[:cancel_label]}
      error_labels={@extra[:error_labels] || %{}}
      over_label={@extra[:over_label]}
      limits_label={@extra[:limits_label]}
    >
      <:cancel_icon :if={@extra[:cancel_icon]}>X-ICON</:cancel_icon>
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

  test "the icon sits in a 22px box and the colours are the canvas's tokens" do
    html = render_zone()

    assert html =~ ~r/size-5\.5[^>]*>\s*ICON/
    assert html =~ "border-line-dashed"
    assert html =~ "bg-(--dropzone-bg)"
    refute html =~ "border-line-strong"
    refute html =~ ~r/#[0-9A-Fa-f]{6}/

    css = File.read!("assets/css/devaction_ui.css")
    assert css =~ "--dropzone-bg: light-dark(#FAFAFB"
  end

  test "each chosen file is drawn by the caller's slot, with its progress" do
    html = render_zone(%{upload: upload([entry("a.txt", 40), entry("b.txt", 100)])})

    assert html =~ "a.txt: 40%"
    assert html =~ "b.txt: 100%"
    refute html =~ "progressbar"
    refute render_zone() =~ "<ul"
  end

  test "without a slot each file is a row with its name and a progress bar" do
    html = render_default(%{upload: upload([entry("a.txt", 40)])})

    assert html =~ "a.txt"
    assert html =~ ~s(role="progressbar")
    assert html =~ ~s(aria-valuenow="40")
    assert html =~ ~s(aria-label="a.txt")
    refute html =~ "<button"
  end

  test "a file with errors shows them in the words of the caller and tints its bar" do
    conf = upload([entry("a.txt", 10)], [{"a.txt", :too_large}, {"a.txt", :odd}])
    html = render_default(%{upload: conf, error_labels: %{too_large: "Too large"}})

    assert html =~ ~r/role="alert"[^>]*>\s*Too large/
    assert html =~ ~r/role="alert"[^>]*>\s*odd/
    assert html =~ "bg-missing"
  end

  test "the errors of the upload itself join the messages of the caller" do
    conf = upload([], [{:upload, :too_many_files}])

    html =
      render_default(%{upload: conf, error_labels: %{too_many_files: "Only one file"}})

    assert html =~ ~s(id="dz-errors")
    assert html =~ "Only one file"
    assert html =~ ~r/<input[^>]*aria-describedby="dz-errors"/
  end

  test "each file can be removed with a button named by it" do
    conf = upload([entry("a.txt", 40), entry("b.txt", 100)])

    html =
      render_default(%{upload: conf, cancel_event: "cancel", cancel_label: "Remove %{name}"})

    assert length(Regex.scan(~r/<button/, html)) == 2
    assert html =~ ~s(aria-label="Remove a.txt")
    assert html =~ ~s(aria-label="Remove b.txt")
    assert html =~ ~s(phx-click="cancel")
    assert html =~ ~s(phx-value-ref="a.txt")
    assert html =~ "×"
  end

  test "the cancel button also sits beside a row the caller draws, with its own icon" do
    conf = upload([entry("a.txt", 40)])
    html = render_default(%{upload: conf, cancel_event: "cancel", cancel_icon: true})

    assert html =~ "X-ICON"
    refute html =~ "×"
  end

  test "the errors are alerts, and the file input points at them" do
    html = render_zone(%{errors: ["Too large", "Not a text"]})

    assert length(Regex.scan(~r/role="alert"/, html)) == 2
    assert html =~ ~s(id="dz-errors")
    assert html =~ ~r/<input[^>]*aria-describedby="dz-hint dz-errors"/s
    refute render_zone() =~ "dz-errors"
  end

  test "the hint is tied to the field" do
    html = render_zone()

    assert html =~ ~s(id="dz-hint")
    assert html =~ ~r/<input[^>]*aria-describedby="dz-hint"/s
  end

  test "the limits of the upload write the hint when there is none" do
    html = render_default(%{limits_label: "%{types} · up to %{size}"})

    assert html =~ ".txt, .mp3 · up to 200 MB"
    assert html =~ ~s(accept=".txt,.mp3")
    refute render_default(%{}) =~ "dz-hint"
  end

  test "a hint of the caller wins over the limits" do
    assigns = %{upload: upload()}

    html =
      rendered_to_string(~H"""
      <Dropzone.dropzone id="dz" upload={@upload} title="T" hint="Mine" limits_label="%{size}" />
      """)

    assert html =~ "Mine"
    refute html =~ "200 MB"
  end

  test "the limits are read from the upload config" do
    assert Dropzone.limits(upload()) == %{types: ".txt, .mp3", size: "200 MB"}

    assert Dropzone.limits(upload([], [], accept: :any, max_file_size: 1_500)) ==
             %{types: "", size: "1.5 KB"}
  end

  test "a size is written in decimal units" do
    assert Dropzone.size_text(512) == "512 B"
    assert Dropzone.size_text(1_000) == "1 KB"
    assert Dropzone.size_text(2_500_000) == "2.5 MB"
    assert Dropzone.size_text(200_000_000) == "200 MB"
    assert Dropzone.size_text(3_000_000_000) == "3 GB"
  end

  test "the drag state is announced when the caller gives the words" do
    html = render_default(%{over_label: "Drop to upload"})

    assert html =~ ~s(data-over-label="Drop to upload")
    assert html =~ ~r/<span[^>]*data-over-status[^>]*role="status"/
    assert html =~ ~s(aria-live="polite")
    refute render_default(%{}) =~ "data-over-status"
  end

  test "disabled takes neither a click nor a drop" do
    html = render_zone(%{disabled: true})

    assert html =~ ~s(aria-disabled="true")
    refute html =~ "phx-drop-target"
    assert html =~ ~r/<input[^>]*type="file"[^>]* disabled/s
  end
end
