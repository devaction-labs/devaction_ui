defmodule DevactionUI.Dropzone do
  @moduledoc """
  The place to drop a file: a dashed area with an icon, what it takes and the limits. It wraps a LiveView
  upload (`allow_upload/3`), so the same area takes a drop and a click, and highlights while a file is
  over it (`DevactionUI.Dropzone` hook). What went wrong with a file is shown under it, from `errors`.
  """
  use Phoenix.Component

  attr :id, :string, required: true
  attr :upload, Phoenix.LiveView.UploadConfig, required: true

  attr :title, :string,
    required: true,
    doc: "what to drop, e.g. `Drop the transcript or the audio`"

  attr :hint, :string, default: nil, doc: "what it takes, e.g. `.mp3, .m4a, .txt · up to 200 MB`"
  attr :errors, :list, default: [], doc: "messages about the files, already translated"
  attr :class, :any, default: nil
  slot :icon, doc: "the upload icon, drawn by the caller"

  attr :rest, :global

  def dropzone(assigns) do
    ~H"""
    <div id={@id} phx-hook="DevactionUI.Dropzone" class={["flex flex-col gap-2", @class]} {@rest}>
      <label
        for={@upload.ref}
        phx-drop-target={@upload.ref}
        class="flex cursor-pointer flex-col items-center gap-2 rounded-[14px] border-[1.5px] border-dashed border-line-strong bg-wrap p-[22px] text-center transition-colors has-[:focus-visible]:ring-4 has-[:focus-visible]:ring-ink/10 hover:border-ink data-[over]:border-ink data-[over]:bg-card motion-reduce:transition-none"
      >
        <span :if={@icon != []} class="text-ink-2" aria-hidden="true">{render_slot(@icon)}</span>
        <span class="font-medium text-ink">{@title}</span>
        <span :if={@hint} class="text-[13px] text-muted">{@hint}</span>
        <.live_file_input upload={@upload} class="sr-only" />
      </label>
      <p :for={error <- @errors} role="alert" class="m-0 text-[13px] text-missing">{error}</p>
    </div>
    """
  end
end
