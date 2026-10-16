defmodule DevactionUI.Dropzone do
  @moduledoc """
  The place to drop a file: a dashed area with an icon, what it takes and the limits. It wraps a LiveView
  upload (`allow_upload/3`), so the same area takes a drop and a click, and highlights while a file is
  over it (`DevactionUI.Dropzone` hook). What went wrong with a file is shown under it, from `errors`, tied to
  the file field with `aria-describedby`, and the errors of the upload itself (`upload_errors/1`, such as too
  many files) are added to them, written with the texts of `error_labels`.

  The limits the browser already knows are in the upload config: `limits_label` (such as
  `"%{types} · up to %{size}"`) writes them as the hint, from the `accept` list and the `max_file_size` of the
  upload, so they cannot drift from what is enforced; `limits/1` and `size_text/1` give the pieces to write
  them by hand. The `accept` list also goes to the file input, so the file picker filters by it.

  The files chosen are listed under the area. By default each is a row with the name, a `DevactionUI.Progress`
  bar that fills as it goes up, its own errors (`upload_errors/2`) and, with `cancel_event`, a button that
  removes it (the event gets `phx-value-ref`, to call `cancel_upload/3`). To draw the row yourself give the
  `entry` slot, which gets the `Phoenix.LiveView.UploadEntry`; the cancel button is still added beside it.
  `over_label` is announced politely while a file is dragged over the area, so the state is not only colour.
  """
  use Phoenix.Component

  alias DevactionUI.Progress
  alias Phoenix.LiveView.JS
  alias Phoenix.LiveView.UploadConfig

  @units [{1_000_000_000, "GB"}, {1_000_000, "MB"}, {1_000, "KB"}]

  @doc "The limits of an upload as text: `types` (such as .txt, .mp3; blank for any) and `size` (such as 200 MB)."
  @spec limits(UploadConfig.t()) :: %{types: String.t(), size: String.t()}
  def limits(%UploadConfig{accept: accept, max_file_size: max_file_size}),
    do: %{types: types_text(accept), size: size_text(max_file_size)}

  @doc "A size in bytes as text in decimal units, such as `200 MB` or `1.5 KB`."
  @spec size_text(non_neg_integer()) :: String.t()
  def size_text(bytes) do
    {unit, name} = Enum.find(@units, {1, "B"}, fn {size, _name} -> bytes >= size end)
    "#{number_text(bytes / unit)} #{name}"
  end

  defp types_text(:any), do: ""
  defp types_text(accept), do: String.replace(accept, ",", ", ")

  defp number_text(value),
    do: value |> Float.round(1) |> to_string() |> String.replace_suffix(".0", "")

  attr :id, :string, required: true
  attr :upload, Phoenix.LiveView.UploadConfig, required: true

  attr :title, :string,
    required: true,
    doc: "what to drop, e.g. `Drop the transcript or the audio`"

  attr :hint, :string, default: nil, doc: "what it takes, e.g. `.mp3, .m4a, .txt · up to 200 MB`"

  attr :limits_label, :string,
    default: nil,
    doc:
      "the hint written from the upload's own limits when there is no `hint`; `%{types}` and `%{size}` are filled in, as in `\"%{types} · up to %{size}\"`"

  attr :errors, :list, default: [], doc: "messages about the files, already translated"

  attr :error_labels, :map,
    default: %{},
    doc:
      "the text of each upload error (`%{too_large: \"Too large\", not_accepted: \"Not accepted\", too_many_files: \"Too many\"}`); an error with no text shows its name"

  attr :disabled, :boolean, default: false, doc: "takes neither a click nor a drop"

  attr :over_label, :string,
    default: nil,
    doc: "announced while a file is dragged over the area, such as `Drop to upload`"

  attr :cancel_event, :string,
    default: nil,
    doc:
      "shows a button on each file that sends this event with `phx-value-ref`, for `cancel_upload/3`"

  attr :cancel_label, :string,
    default: nil,
    doc: "names the cancel button of a file, as in `\"Remove %{name}\"`"

  attr :target, :any,
    default: nil,
    doc: "a `phx-target` (a `@myself`) when used inside a LiveComponent"

  attr :class, :any, default: nil
  slot :icon, doc: "the upload icon, drawn by the caller; it gets a box of 22px"
  slot :cancel_icon, doc: "replaces the typographic × of the cancel button"

  slot :entry,
    doc:
      "one chosen file, drawn by the caller instead of the default row; gets the `UploadEntry`, with `progress` from 0 to 100"

  attr :rest, :global

  def dropzone(assigns) do
    assigns =
      assign(assigns,
        hint_text: hint_text(assigns.hint, assigns.limits_label, assigns.upload),
        messages:
          assigns.errors ++
            Enum.map(
              Phoenix.Component.upload_errors(assigns.upload),
              &error_text(&1, assigns.error_labels)
            )
      )

    ~H"""
    <div
      id={@id}
      phx-hook="DevactionUI.Dropzone"
      data-over-label={@over_label}
      class={["flex flex-col gap-2", @class]}
      {@rest}
    >
      <label
        for={@upload.ref}
        phx-drop-target={!@disabled && @upload.ref}
        phx-mounted={JS.ignore_attributes(["data-over"])}
        aria-disabled={@disabled && "true"}
        class="flex cursor-pointer flex-col items-center gap-2 rounded-[14px] border-[1.5px] border-dashed border-line-dashed bg-(--dropzone-bg) p-[22px] text-center transition-colors has-[:focus-visible]:ring-4 has-[:focus-visible]:ring-ink/10 hover:border-ink data-[over]:border-ink data-[over]:bg-card aria-disabled:cursor-not-allowed aria-disabled:opacity-50 aria-disabled:hover:border-line-dashed motion-reduce:transition-none"
      >
        <span :if={@icon != []} class="grid size-5.5 place-items-center text-ink-2" aria-hidden="true">
          {render_slot(@icon)}
        </span>
        <span class="font-medium text-ink">{@title}</span>
        <span :if={@hint_text} id={@id <> "-hint"} class="text-[13px] text-muted">{@hint_text}</span>
        <.live_file_input
          upload={@upload}
          class="sr-only"
          disabled={@disabled}
          aria-describedby={described_by(@id, @hint_text, @messages)}
        />
      </label>
      <span :if={@over_label} data-over-status role="status" aria-live="polite" class="sr-only"></span>
      <ul :if={@upload.entries != []} class="m-0 flex list-none flex-col gap-2 p-0">
        <li :for={entry <- @upload.entries} class="flex items-center gap-2">
          <div class="min-w-0 flex-1">
            <.entry_row
              :if={@entry == []}
              upload={@upload}
              entry={entry}
              error_labels={@error_labels}
            />
            {render_slot(@entry, entry)}
          </div>
          <button
            :if={@cancel_event}
            type="button"
            aria-label={fill_name(@cancel_label, entry.client_name)}
            phx-click={@cancel_event}
            phx-target={@target}
            phx-value-ref={entry.ref}
            class="grid size-8 shrink-0 cursor-pointer place-items-center rounded-lg text-muted outline-none hover:bg-wrap hover:text-ink focus-visible:ring-4 focus-visible:ring-ink/10"
          >
            <span aria-hidden="true">{render_slot(@cancel_icon) || "×"}</span>
          </button>
        </li>
      </ul>
      <div :if={@messages != []} id={@id <> "-errors"} class="flex flex-col gap-1">
        <p :for={message <- @messages} role="alert" class="m-0 text-[13px] text-missing">{message}</p>
      </div>
    </div>
    """
  end

  attr :upload, UploadConfig, required: true
  attr :entry, Phoenix.LiveView.UploadEntry, required: true
  attr :error_labels, :map, required: true

  defp entry_row(assigns) do
    assigns =
      assign(assigns, :errors, Phoenix.Component.upload_errors(assigns.upload, assigns.entry))

    ~H"""
    <div class="flex flex-col gap-1 text-left text-[13px]">
      <span class="truncate text-ink">{@entry.client_name}</span>
      <Progress.progress
        value={@entry.progress}
        label={@entry.client_name}
        tone={entry_tone(@errors)}
      />
      <span :for={error <- @errors} role="alert" class="text-missing">
        {error_text(error, @error_labels)}
      </span>
    </div>
    """
  end

  defp entry_tone([]), do: :neutral
  defp entry_tone(_errors), do: :risk

  defp hint_text(nil, nil, _upload), do: nil
  defp hint_text(nil, label, upload), do: fill(label, limits(upload))
  defp hint_text(hint, _label, _upload), do: hint

  defp fill(label, %{types: types, size: size}),
    do: label |> String.replace("%{types}", types) |> String.replace("%{size}", size)

  defp fill_name(nil, _name), do: nil
  defp fill_name(pattern, name), do: String.replace(pattern, "%{name}", name)

  defp error_text(error, labels), do: Map.get(labels, error, to_string(error))

  defp described_by(id, hint, messages),
    do:
      [hint && id <> "-hint", messages != [] && id <> "-errors"] |> Enum.filter(& &1) |> joined()

  defp joined([]), do: nil
  defp joined(ids), do: Enum.join(ids, " ")
end
