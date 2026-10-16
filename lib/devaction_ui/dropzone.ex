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

  `queue/1` is the same drop area with a gridded face and, under it, the whole queue: one row per file with its
  state (sent, uploading, stopped, waiting, refused), a progress bar, the size, a "Try again" button for a file that
  stopped and a button that cancels or removes it, above a summary line with a "Clear finished" action. The rows
  come from the `entries` of a LiveView upload (`upload`) or, for a queue of your own, from plain maps (`entries`).
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

  attr :id, :string, required: true

  attr :upload, UploadConfig,
    default: nil,
    doc:
      "the upload whose `entries` are the rows, and whose input takes the click and the drop; leave it out for a queue of your own"

  attr :entries, :list,
    default: [],
    doc:
      "the rows when there is no `upload`: maps with `name` and, as they apply, `ref`, `size` (bytes or text), `progress` (0 to 100), `state` (`:sent`, `:uploading`, `:failed`, `:queued` or `:rejected`), `message` (replaces the state's text) and `hint` (replaces the line under a refused file)"

  attr :failed, :list,
    default: [],
    doc:
      "the `ref`s of the upload entries that stopped (LiveView does not know a connection dropped; the server does)"

  attr :title, :string, required: true, doc: "what to drop, e.g. `Drop files or click to choose`"

  attr :hint, :string,
    default: nil,
    doc: "what it takes, e.g. `PDF, PNG or JPG · up to 25 MB each`"

  attr :over_title, :string,
    default: nil,
    doc: "replaces the title while a file is over the area, e.g. `Release to upload`"

  attr :over_hint, :string,
    default: nil,
    doc: "replaces the hint while a file is over the area, e.g. `3 files · 4.2 MB`"

  attr :dragging, :boolean,
    default: false,
    doc: "draws the area as if a file were over it (for a page that shows the state)"

  attr :summary, :string,
    default: nil,
    doc:
      "the line over the rows, written by the caller: `5 files · 1 uploading · 1 with an error`"

  attr :clear_label, :string,
    default: nil,
    doc: "the action beside the summary, e.g. `Clear finished`; it shows with `clear_event`"

  attr :labels, :map,
    required: true,
    doc:
      "the words of the rows, by key: `sent`, `uploading` (`uploading · %{size}`), `queued`, `failed`, `stopped` (`stopped at %{percent}%`), `rejected`, `rejected_hint`, `retry`, `cancel` and `remove` (`Cancel %{name}`, `Remove %{name}`)"

  attr :error_labels, :map,
    default: %{},
    doc:
      "the text of each upload error, as in `dropzone/1`; the text of a refused file comes from here"

  attr :retry_event, :any,
    default: nil,
    doc: "sent with `phx-value-ref` by the button of a stopped file: a string or a `%JS{}`"

  attr :cancel_event, :any,
    default: nil,
    doc:
      "sent with `phx-value-ref` by the button that cancels a file that is not sent and removes one that is (`cancel_upload/3`)"

  attr :clear_event, :any, default: nil, doc: "sent by the clear action"

  attr :target, :any,
    default: nil,
    doc: "a `phx-target` (a `@myself`) when used inside a LiveComponent"

  attr :class, :any, default: nil
  slot :icon, doc: "the upload icon in the box of the area; it gets 22px"
  slot :retry_icon, doc: "before the text of the retry button; a `↻` when empty"
  slot :cancel_icon, doc: "the icon of the cancel button; a `×` when empty"
  slot :remove_icon, doc: "the icon of the remove button of a sent file; a `×` when empty"
  attr :rest, :global

  def queue(assigns) do
    assigns =
      assign(assigns,
        rows: rows(assigns),
        messages:
          Enum.map(
            upload_messages(assigns.upload),
            &error_text(&1, assigns.error_labels)
          )
      )

    ~H"""
    <div id={@id} phx-hook="DevactionUI.Dropzone" class={["flex flex-col", @class]} {@rest}>
      <label
        for={@upload && @upload.ref}
        phx-drop-target={@upload && @upload.ref}
        phx-mounted={JS.ignore_attributes(["data-over"])}
        data-drop-area
        data-over={@dragging || nil}
        class="dropzone-grid group flex h-[170px] cursor-pointer flex-col items-center justify-center gap-2 rounded-[14px] border-[1.5px] border-dashed border-line-dashed bg-card text-center transition-colors has-[:focus-visible]:ring-4 has-[:focus-visible]:ring-ink/10 hover:border-ink data-[over]:border-ai data-[over]:bg-(--dropzone-over-bg) motion-reduce:transition-none"
      >
        <span
          :if={@icon != []}
          aria-hidden="true"
          class="grid size-11 place-items-center rounded-xl border border-line bg-card text-ink group-data-[over]:border-ai group-data-[over]:bg-ai group-data-[over]:text-card [&>*]:size-5.5"
        >
          {render_slot(@icon)}
        </span>
        <span class={["font-medium text-ink", @over_title && "group-data-[over]:hidden"]}>{@title}</span>
        <span :if={@over_title} class="hidden font-medium text-ink group-data-[over]:inline">
          {@over_title}
        </span>
        <span
          :if={@hint}
          id={@id <> "-hint"}
          class={["text-[13px] text-muted", @over_hint && "group-data-[over]:hidden"]}
        >
          {@hint}
        </span>
        <span :if={@over_hint} class="hidden text-[13px] text-muted group-data-[over]:inline">
          {@over_hint}
        </span>
        <.live_file_input
          :if={@upload}
          upload={@upload}
          class="sr-only"
          aria-describedby={@hint && @id <> "-hint"}
        />
      </label>
      <div :if={@messages != []} class="mt-2 flex flex-col gap-1">
        <p :for={message <- @messages} role="alert" class="m-0 text-[13px] text-missing">{message}</p>
      </div>
      <div :if={@summary} class="mt-4 flex items-center text-[13px] text-ink-2">
        <span>{@summary}</span>
        <button
          :if={@clear_event && @clear_label}
          type="button"
          phx-click={@clear_event}
          phx-target={@target}
          class="ml-auto cursor-pointer rounded-md bg-transparent px-1 font-medium text-ink outline-none hover:underline focus-visible:ring-4 focus-visible:ring-ink/10"
        >
          {@clear_label}
        </button>
      </div>
      <ul :if={@rows != []} class="m-0 mt-2.5 flex list-none flex-col gap-2 p-0">
        <li
          :for={row <- @rows}
          data-state={row.state}
          class={["flex items-center gap-3 rounded-xl border px-3 py-2.5", row_class(row.state)]}
        >
          <span class={[
            "flex size-10 flex-none items-center justify-center rounded-[9px] border border-line font-mono text-[10px] font-semibold",
            thumb_class(row.state)
          ]}>
            {row.ext}
          </span>
          <div class="min-w-0 flex-1">
            <div class="flex items-center gap-2 text-sm">
              <span class="truncate font-medium text-ink">{row.name}</span>
              <span class={["ml-auto flex-none text-xs", status_class(row.state)]}>
                {status_text(row, @labels)}
              </span>
            </div>
            <div class="mt-1.5 flex items-center gap-2.5">
              <span
                role="progressbar"
                aria-label={row.name}
                aria-valuemin="0"
                aria-valuemax="100"
                aria-valuenow={row.percent}
                class="h-1 flex-1 overflow-hidden rounded-sm bg-line-soft"
              >
                <span class={["block h-full", bar_class(row.state)]} style={"width: #{row.percent}%"}></span>
              </span>
              <span class="min-w-[92px] flex-none text-right font-mono text-[11px] text-muted">
                {meta_text(row, @labels)}
              </span>
            </div>
          </div>
          <button
            :if={row.state == :failed && @retry_event}
            type="button"
            phx-click={@retry_event}
            phx-target={@target}
            phx-value-ref={row.ref}
            class="inline-flex h-[30px] flex-none cursor-pointer items-center gap-1.5 rounded-lg border border-line-strong bg-card px-2.5 text-[13px] text-ink outline-none hover:bg-wrap focus-visible:ring-4 focus-visible:ring-ink/10"
          >
            <span aria-hidden="true" class="grid size-3.5 place-items-center [&>*]:size-full">
              {(@retry_icon != [] && render_slot(@retry_icon)) || "↻"}
            </span>
            {Map.get(@labels, :retry)}
          </button>
          <button
            :if={@cancel_event}
            type="button"
            aria-label={put_values(Map.get(@labels, closer_key(row.state)), %{name: row.name})}
            phx-click={@cancel_event}
            phx-target={@target}
            phx-value-ref={row.ref}
            class="grid size-7 flex-none cursor-pointer place-items-center rounded-lg text-muted outline-none hover:bg-wrap hover:text-ink focus-visible:ring-4 focus-visible:ring-ink/10"
          >
            <span aria-hidden="true" class="grid size-[15px] place-items-center [&>*]:size-full">
              {(row.state == :sent && @remove_icon != [] && render_slot(@remove_icon)) ||
                (row.state != :sent && @cancel_icon != [] && render_slot(@cancel_icon)) || "×"}
            </span>
          </button>
        </li>
      </ul>
    </div>
    """
  end

  defp upload_messages(nil), do: []
  defp upload_messages(upload), do: Phoenix.Component.upload_errors(upload)

  defp closer_key(:sent), do: :remove
  defp closer_key(_state), do: :cancel

  defp rows(%{upload: %UploadConfig{} = upload} = assigns),
    do: Enum.map(upload.entries, &entry_row(&1, upload, assigns))

  defp rows(assigns), do: Enum.map(assigns.entries, &map_row/1)

  defp entry_row(entry, upload, assigns) do
    state = entry_state(entry, assigns.failed)

    finish(%{
      ref: entry.ref,
      name: entry.client_name,
      size: entry.client_size,
      progress: entry.progress,
      state: state,
      message:
        entry_message(
          state,
          Phoenix.Component.upload_errors(upload, entry),
          assigns.error_labels
        ),
      hint: nil
    })
  end

  defp entry_state(%{valid?: false}, _failed), do: :rejected
  defp entry_state(%{done?: true}, _failed), do: :sent

  defp entry_state(entry, failed) do
    case {entry.ref in failed, entry.progress} do
      {true, _progress} -> :failed
      {false, 0} -> :queued
      {false, _progress} -> :uploading
    end
  end

  defp entry_message(:rejected, [error | _], error_labels), do: Map.get(error_labels, error)
  defp entry_message(_state, _errors, _error_labels), do: nil

  defp map_row(row) do
    %{ref: nil, size: nil, progress: 0, state: :queued, message: nil, hint: nil}
    |> Map.merge(row)
    |> finish()
  end

  defp finish(row) do
    Map.merge(row, %{
      ext: row.name |> Path.extname() |> String.trim_leading(".") |> String.upcase(),
      size_text: size_label(row.size),
      percent: percent(row.state, row.progress)
    })
  end

  defp size_label(nil), do: ""
  defp size_label(bytes) when is_integer(bytes), do: size_text(bytes)
  defp size_label(text), do: text

  defp percent(:sent, _progress), do: 100
  defp percent(state, _progress) when state in [:queued, :rejected], do: 0
  defp percent(_state, progress), do: progress

  defp status_text(%{message: message}, _labels) when is_binary(message), do: message
  defp status_text(%{state: :uploading, percent: percent}, _labels), do: "#{percent}%"
  defp status_text(%{state: state}, labels), do: Map.get(labels, state)

  defp meta_text(%{state: :uploading} = row, labels),
    do: put_values(Map.get(labels, :uploading), %{size: row.size_text})

  defp meta_text(%{state: :failed} = row, labels),
    do: put_values(Map.get(labels, :stopped), %{percent: row.percent})

  defp meta_text(%{state: :rejected, hint: hint}, _labels) when is_binary(hint), do: hint
  defp meta_text(%{state: :rejected}, labels), do: Map.get(labels, :rejected_hint)
  defp meta_text(row, _labels), do: row.size_text

  defp put_values(nil, _values), do: nil

  defp put_values(text, values),
    do:
      Enum.reduce(values, text, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)

  defp row_class(state) when state in [:failed, :rejected],
    do: "border-tag-risk-line bg-(--field-error-fill)"

  defp row_class(_state), do: "border-line bg-card"

  defp thumb_class(:sent), do: "bg-tag-risk-bg text-tag-risk-text"
  defp thumb_class(state) when state in [:uploading, :failed], do: "bg-wrap text-ink-2"
  defp thumb_class(_state), do: "bg-wrap text-muted"

  defp status_class(:sent), do: "text-ok-fg"
  defp status_class(:uploading), do: "text-ink"
  defp status_class(state) when state in [:failed, :rejected], do: "text-tag-risk-text"
  defp status_class(:queued), do: "text-muted"

  defp bar_class(:sent), do: "bg-ok-fg"
  defp bar_class(state) when state in [:failed, :rejected], do: "bg-tag-risk-text"
  defp bar_class(_state), do: "bg-ink"

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
