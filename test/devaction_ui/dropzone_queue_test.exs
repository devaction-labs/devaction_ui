defmodule DevactionUI.DropzoneQueueTest do
  @moduledoc "The upload queue: the drop area with its grid, the summary and a row for each state of a file."
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.Dropzone
  alias Phoenix.LiveView.{Socket, UploadEntry}

  @labels %{
    sent: "Sent",
    uploading: "uploading · %{size}",
    queued: "Queued",
    failed: "Connection dropped",
    stopped: "stopped at %{percent}%",
    rejected: "Type not accepted",
    rejected_hint: "use PDF, PNG or JPG",
    retry: "Try again",
    cancel: "Cancel %{name}",
    remove: "Remove %{name}"
  }

  @rows [
    %{ref: "1", name: "Contract.pdf", size: 1_800_000, state: :sent},
    %{ref: "2", name: "Report.pdf", size: 6_100_000, state: :uploading, progress: 64},
    %{ref: "3", name: "print.png", size: 3_400_000, state: :failed, progress: 38},
    %{ref: "4", name: "Minutes.pdf", size: 420_000, state: :queued},
    %{ref: "5", name: "sheet.xlsx", size: 88_000, state: :rejected}
  ]

  defp upload(entries, errors \\ []) do
    socket =
      Phoenix.LiveView.allow_upload(
        %Socket{assigns: %{__changed__: %{}, flash: %{}}},
        :files,
        accept: ~w(.pdf .png),
        max_file_size: 25_000_000
      )

    conf = socket.assigns.uploads.files
    %{conf | entries: entries, errors: Enum.map(errors, fn {ref, error} -> {ref, error} end)}
  end

  defp entry(name, progress, extra \\ []) do
    struct(
      %UploadEntry{
        ref: name,
        client_name: name,
        progress: progress,
        uuid: "u-#{name}",
        client_size: 2_000,
        valid?: true
      },
      extra
    )
  end

  defp queue(extra) do
    assigns =
      Map.merge(
        %{
          upload: nil,
          entries: [],
          failed: [],
          summary: nil,
          clear_label: nil,
          retry_event: nil,
          cancel_event: nil,
          clear_event: nil,
          over_title: nil,
          over_hint: nil,
          dragging: false,
          error_labels: %{}
        },
        extra
      )

    rendered_to_string(~H"""
    <Dropzone.queue
      id="q"
      upload={@upload}
      entries={@entries}
      failed={@failed}
      title="Drop files"
      hint="PDF or PNG"
      over_title={@over_title}
      over_hint={@over_hint}
      dragging={@dragging}
      summary={@summary}
      clear_label={@clear_label}
      labels={labels()}
      error_labels={@error_labels}
      retry_event={@retry_event}
      cancel_event={@cancel_event}
      clear_event={@clear_event}
    >
      <:icon>UP</:icon>
    </Dropzone.queue>
    """)
  end

  defp labels, do: @labels

  test "the area has the grid, the icon box and the hint, and takes the drop of the upload" do
    html = queue(%{upload: upload([])})

    assert html =~ ~s(phx-hook="DevactionUI.Dropzone")
    assert html =~ "dropzone-grid"
    assert html =~ "border-dashed"
    assert html =~ ~r/size-11.*?>\s*UP/s
    assert html =~ "Drop files"
    assert html =~ "PDF or PNG"
    assert html =~ ~r/<label[^>]*phx-drop-target="phx-/
    assert html =~ ~s(type="file")
    refute html =~ "<ul"
  end

  test "without an upload the area is only drawn: no file input, no drop target" do
    html = queue(%{})

    refute html =~ ~s(type="file")
    refute html =~ "phx-drop-target"
    assert html =~ "data-drop-area"
  end

  test "every state of a file is a row with its text, its bar and its size" do
    html = queue(%{entries: @rows})

    for state <- ~w(sent uploading failed queued rejected),
        do: assert(html =~ ~s(data-state="#{state}"))

    assert html =~ "Sent"
    assert html =~ "1.8 MB"
    assert html =~ "64%"
    assert html =~ "uploading · 6.1 MB"
    assert html =~ "Connection dropped"
    assert html =~ "stopped at 38%"
    assert html =~ "Queued"
    assert html =~ "Type not accepted"
    assert html =~ "use PDF, PNG or JPG"
  end

  test "the bar fills by state: whole when sent, by progress while it goes, empty when waiting or refused" do
    html = queue(%{entries: @rows})

    assert html =~ ~s(aria-valuenow="100")
    assert html =~ ~s(aria-valuenow="64")
    assert html =~ ~s(aria-valuenow="38")
    assert html =~ "width: 64%"
    assert html =~ "width: 0%"
    assert html =~ "bg-ok-fg"
    assert html =~ "bg-tag-risk-text"
    assert html =~ ~s(role="progressbar")
  end

  test "the type of a file is its extension on the thumb" do
    html = queue(%{entries: @rows})

    assert html =~ ~r/font-semibold[^>]*>\s*PDF/
    assert html =~ ~r/font-semibold[^>]*>\s*XLSX/
  end

  test "a message of the row replaces the text of its state and a hint the line of a refused file" do
    rows = [%{name: "a.exe", state: :rejected, message: "Not allowed", hint: "no programs"}]
    html = queue(%{entries: rows})

    assert html =~ "Not allowed"
    assert html =~ "no programs"
    refute html =~ "Type not accepted"
  end

  test "only a stopped file has the retry button, named and wired by the caller" do
    html = queue(%{entries: @rows, retry_event: "retry"})

    assert length(Regex.scan(~r/Try again/, html)) == 1
    assert html =~ ~s(phx-click="retry")
    assert html =~ ~s(phx-value-ref="3")
    refute queue(%{entries: @rows}) =~ "Try again"
  end

  test "each file has a button that cancels it, and one that is sent is removed instead" do
    html = queue(%{entries: @rows, cancel_event: "cancel"})

    assert html =~ ~s(aria-label="Remove Contract.pdf")
    assert html =~ ~s(aria-label="Cancel Report.pdf")
    assert html =~ ~s(aria-label="Cancel sheet.xlsx")
    assert length(Regex.scan(~r/phx-click="cancel"/, html)) == 5
    assert html =~ "×"
  end

  test "the summary and the clear action are the caller's words and event" do
    html =
      queue(%{
        summary: "5 files · 1 uploading",
        clear_label: "Clear finished",
        clear_event: "clear"
      })

    assert html =~ "5 files · 1 uploading"
    assert html =~ ~r/phx-click="clear"[^>]*>\s*Clear finished/
    refute queue(%{summary: "x", clear_label: "Clear"}) =~ "<button"
    refute queue(%{}) =~ "Clear"
  end

  test "the area can show a file over it, with its own title and hint" do
    html =
      queue(%{dragging: true, over_title: "Release to upload", over_hint: "3 files · 4.2 MB"})

    assert html =~ ~r/<label[^>]*data-over/
    assert html =~ "Release to upload"
    assert html =~ "3 files · 4.2 MB"
    assert html =~ "group-data-[over]:hidden"
  end

  test "the rows come from the entries of the upload, with the state worked out" do
    conf =
      upload([
        entry("done.pdf", 100, done?: true),
        entry("going.pdf", 40),
        entry("dropped.png", 12),
        entry("waiting.pdf", 0),
        entry("bad.exe", 0, valid?: false)
      ])

    html = queue(%{upload: conf, failed: ["dropped.png"]})

    for state <- ~w(sent uploading failed queued rejected),
        do: assert(html =~ ~s(data-state="#{state}"))

    assert html =~ "stopped at 12%"
    assert html =~ "2 KB"
  end

  test "a refused file says why in the words of the caller" do
    conf = upload([entry("bad.exe", 0, valid?: false)], [{"bad.exe", :not_accepted}])
    html = queue(%{upload: conf, error_labels: %{not_accepted: "This type is not accepted"}})

    assert html =~ "This type is not accepted"
  end

  test "the errors of the upload itself are alerts" do
    conf = upload([], [{:upload_ref, :too_many_files}])
    conf = %{conf | errors: [{conf.ref, :too_many_files}]}
    html = queue(%{upload: conf, error_labels: %{too_many_files: "Too many files"}})

    assert html =~ ~r/role="alert"[^>]*>\s*Too many files/
  end

  test "the colours are tokens" do
    refute queue(%{entries: @rows, dragging: true}) =~ ~r/#[0-9A-Fa-f]{6}/

    css = File.read!("assets/css/devaction_ui.css")
    assert css =~ "--dropzone-grid: light-dark("
    assert css =~ "--dropzone-over-bg: light-dark("
  end
end
