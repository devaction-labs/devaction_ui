defmodule DevactionUI.Dropzone do
  @moduledoc """
  The place to drop a file: a dashed area with an icon, what it takes and the limits. It wraps a LiveView
  upload (`allow_upload/3`), so the same area takes a drop and a click, and highlights while a file is
  over it (`DevactionUI.Dropzone` hook). What went wrong with a file is shown under it, from `errors`, tied to
  the file field with `aria-describedby`.

  The files chosen are the caller's to draw: the `entry` slot is rendered once for each of `upload.entries`
  (it gets the `Phoenix.LiveView.UploadEntry`), so the name, the progress bar from `entry.progress`, the
  translated `upload_errors/2` and the button that cancels it (`cancel_upload/3`) are written in the words and
  the look of the page.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  attr :id, :string, required: true
  attr :upload, Phoenix.LiveView.UploadConfig, required: true

  attr :title, :string,
    required: true,
    doc: "what to drop, e.g. `Drop the transcript or the audio`"

  attr :hint, :string, default: nil, doc: "what it takes, e.g. `.mp3, .m4a, .txt · up to 200 MB`"
  attr :errors, :list, default: [], doc: "messages about the files, already translated"
  attr :disabled, :boolean, default: false, doc: "takes neither a click nor a drop"
  attr :class, :any, default: nil
  slot :icon, doc: "the upload icon, drawn by the caller; it gets a box of 22px"

  slot :entry,
    doc:
      "one chosen file, drawn by the caller; gets the `UploadEntry`, with `progress` from 0 to 100"

  attr :rest, :global

  def dropzone(assigns) do
    ~H"""
    <div id={@id} phx-hook="DevactionUI.Dropzone" class={["flex flex-col gap-2", @class]} {@rest}>
      <label
        for={@upload.ref}
        phx-drop-target={!@disabled && @upload.ref}
        phx-mounted={JS.ignore_attributes(["data-over"])}
        aria-disabled={@disabled && "true"}
        class="flex cursor-pointer flex-col items-center gap-2 rounded-[14px] border-[1.5px] border-dashed border-line-strong bg-wrap p-[22px] text-center transition-colors has-[:focus-visible]:ring-4 has-[:focus-visible]:ring-ink/10 hover:border-ink data-[over]:border-ink data-[over]:bg-card aria-disabled:cursor-not-allowed aria-disabled:opacity-50 aria-disabled:hover:border-line-strong motion-reduce:transition-none"
      >
        <span :if={@icon != []} class="grid size-5.5 place-items-center text-ink-2" aria-hidden="true">
          {render_slot(@icon)}
        </span>
        <span class="font-medium text-ink">{@title}</span>
        <span :if={@hint} class="text-[13px] text-muted">{@hint}</span>
        <.live_file_input
          upload={@upload}
          class="sr-only"
          disabled={@disabled}
          aria-describedby={@errors != [] && @id <> "-errors"}
        />
      </label>
      <ul :if={@upload.entries != [] and @entry != []} class="m-0 flex list-none flex-col gap-2 p-0">
        <li :for={entry <- @upload.entries}>{render_slot(@entry, entry)}</li>
      </ul>
      <div :if={@errors != []} id={@id <> "-errors"} class="flex flex-col gap-1">
        <p :for={error <- @errors} role="alert" class="m-0 text-[13px] text-missing">{error}</p>
      </div>
    </div>
    """
  end
end
