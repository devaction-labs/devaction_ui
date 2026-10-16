defmodule DevactionUI.Composer do
  @moduledoc """
  The message field of the AI chat, of comments and of notes: a card with a textarea that grows with the text
  (up to `max_rows`, then it scrolls inside), a row of actions under it and a round send button. Enter sends the
  form, Shift + Enter breaks the line, and Enter while an accent or a word is being composed does neither; the send
  button is off while there is nothing to send, and over `max_length` the card turns red and a counter shows from
  80% of the limit (`DevactionUI.Composer` hook).

  It is a form: the LiveView gets `event` with `%{name => text}` (`%{"prompt" => "..."}` by default). LiveView
  never overwrites a field that has focus, so after a send the server empties it with
  `push_event(socket, "composer:clear", %{id: "chat"})` (the id of the composer).

  With `busy` the AI is answering: the field is read only and the send button becomes a stop button (its icon is
  the `stop` slot, its name `stop_label`). A click on it, or Esc, sends `stop_event` to `target` when there is one,
  and fires `composer:stop` on the card for a hook of your own.

  With an `upload` (an `allow_upload` of the LiveView) a file pasted into the field or dropped on the card is
  uploaded by LiveView, and `Composer.file/1` chips in the `header` slot show each one with a button to remove it.
  The form then needs a `change_event`, which LiveView requires of a form with a file input. `Composer.button/1` is
  a round action of the row under the field (`leading` on the left, `trailing` before the send button); given the
  `upload`, it opens the file chooser.

  Every text comes from the caller (`label`, `send_label`, `stop_label`, the labels of the buttons and chips), and
  so do the icons, as slots.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  attr :id, :string, required: true
  attr :name, :string, default: "prompt", doc: "the name of the field in the params of `event`"
  attr :value, :string, default: "", doc: "the text the field starts with"
  attr :label, :string, required: true, doc: "what the field is, for assistive technology"
  attr :placeholder, :string, default: nil
  attr :event, :string, required: true, doc: "the `phx-submit` of the form"
  attr :send_label, :string, required: true, doc: "the name of the send button"

  attr :stop_label, :string,
    required: true,
    doc: "the name of the button while the AI answers (`busy`)"

  attr :change_event, :string,
    default: nil,
    doc: "the `phx-change` of the form; an `upload` needs it"

  attr :stop_event, :string,
    default: nil,
    doc:
      "the event the stop button and Esc send; leave it out to listen to `composer:stop` instead"

  attr :max_rows, :integer, default: 8, doc: "how many lines the field grows to before it scrolls"
  attr :max_length, :integer, default: 0, doc: "the longest text that can be sent; 0 for no limit"
  attr :busy, :boolean, default: false, doc: "the AI is answering: stop instead of send"

  attr :size, :atom,
    values: [:md, :sm],
    default: :md,
    doc: ":sm is a one-line field with the actions at its end"

  attr :upload, :any, default: nil, doc: "a `@uploads.name` to paste and drop files into"
  attr :class, :any, default: nil

  attr :target, :any,
    default: nil,
    doc: "a `phx-target` (a `@myself`) when used inside a LiveComponent"

  slot :header, doc: "above the field: the chips of the files, `Composer.file/1` for each entry"
  slot :leading, doc: "actions at the start of the row under the field"
  slot :trailing, doc: "actions before the send button"
  slot :icon, required: true, doc: "the arrow of the send button"
  slot :stop, required: true, doc: "the icon of the stop button"
  attr :rest, :global

  @spec composer(map()) :: Phoenix.LiveView.Rendered.t()
  def composer(%{upload: %{}, change_event: nil}),
    do: raise(ArgumentError, "composer: an `upload` needs a `change_event`")

  def composer(assigns) do
    assigns =
      assigns
      |> assign(:stop_command, stop_command(assigns.stop_event, assigns.target))
      |> assign(:disabled, not assigns.busy and String.trim(assigns.value) == "")

    ~H"""
    <form
      id={"#{@id}-form"}
      phx-submit={@event}
      phx-change={@change_event}
      phx-target={@target}
      autocomplete="off"
      class={["m-0", @class]}
      {@rest}
    >
      <div
        id={@id}
        class="composer"
        phx-hook="DevactionUI.Composer"
        phx-mounted={JS.ignore_attributes(["data-over", "data-dragging"])}
        data-size={@size}
        data-max-rows={@max_rows}
        data-max-length={@max_length}
        data-busy={to_string(@busy)}
        data-stop={@stop_command}
      >
        <div :if={@header != []} class="composer-header">{render_slot(@header)}</div>
        <label for={"#{@id}-input"} class="sr-only">{@label}</label>
        <textarea
          id={"#{@id}-input"}
          name={@name}
          class="composer-input"
          data-composer-input
          rows="1"
          readonly={@busy}
          placeholder={@placeholder}
          phx-mounted={JS.ignore_attributes(["style"])}
          phx-debounce="150"
        >{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
        <div class="composer-actions">
          <div :if={@leading != []} class="composer-leading">{render_slot(@leading)}</div>
          <div class="composer-trailing">
            <span
              id={"#{@id}-count"}
              class="composer-count"
              data-composer-count
              hidden
              phx-update="ignore"
            />
            {render_slot(@trailing)}
            <button
              type="submit"
              class="composer-send"
              data-composer-send
              data-stop={@busy}
              disabled={@disabled}
              aria-label={(@busy && @stop_label) || @send_label}
              phx-mounted={JS.ignore_attributes(["disabled"])}
            >
              <span class="composer-send-icon">{render_slot(@icon)}</span>
              <span class="composer-stop-icon">{render_slot(@stop)}</span>
            </button>
          </div>
        </div>
        <.live_file_input
          :if={@upload}
          upload={@upload}
          class="hidden"
          data-composer-files
        />
      </div>
    </form>
    """
  end

  defp stop_command(nil, _target), do: nil
  defp stop_command(event, nil), do: JS.push(event)
  defp stop_command(event, target), do: JS.push(event, target: target)

  attr :label, :string, required: true, doc: "the name of the button, also its tooltip"
  attr :variant, :atom, values: [:plain, :filled], default: :plain

  attr :upload, :any,
    default: nil,
    doc: "a `@uploads.name`: the button opens the file chooser of the composer"

  slot :icon, required: true
  attr :rest, :global

  @doc "An action of the row under the field; with an `upload` it is the label of the file input."
  @spec button(map()) :: Phoenix.LiveView.Rendered.t()
  def button(%{upload: %{}} = assigns) do
    ~H"""
    <label
      for={@upload.ref}
      class="composer-btn"
      data-variant={@variant}
      title={@label}
      aria-label={@label}
      role="button"
      tabindex="0"
      {@rest}
    >
      {render_slot(@icon)}
    </label>
    """
  end

  def button(assigns) do
    ~H"""
    <button
      type="button"
      class="composer-btn"
      data-variant={@variant}
      title={@label}
      aria-label={@label}
      {@rest}
    >
      {render_slot(@icon)}
    </button>
    """
  end

  attr :entry, :any, required: true, doc: "a `Phoenix.LiveView.UploadEntry`"
  attr :remove_label, :string, required: true, doc: "the name of the remove button, for this file"

  attr :cancel_event, :string,
    default: "cancel-upload",
    doc: "sent with `ref`, the entry to cancel"

  attr :target, :any,
    default: nil,
    doc: "a `phx-target` (a `@myself`) when used inside a LiveComponent"

  slot :icon, required: true, doc: "the cross of the remove button"
  attr :rest, :global

  @doc "The chip of one file of the upload: its preview when it is an image, its name and progress when it is not."
  @spec file(map()) :: Phoenix.LiveView.Rendered.t()
  def file(assigns) do
    ~H"""
    <div class="composer-file" {@rest}>
      <.preview entry={@entry} />
      <button
        type="button"
        class="composer-file-remove"
        phx-click={@cancel_event}
        phx-target={@target}
        phx-value-ref={@entry.ref}
        aria-label={@remove_label}
      >
        {render_slot(@icon)}
      </button>
    </div>
    """
  end

  attr :entry, :any, required: true

  defp preview(%{entry: %{client_type: "image/" <> _subtype}} = assigns) do
    ~H"""
    <.live_img_preview entry={@entry} alt={@entry.client_name} />
    """
  end

  defp preview(assigns) do
    ~H"""
    <span class="flex flex-col pr-2">
      <span class="font-medium">{@entry.client_name}</span>
      <span class="text-[11px] text-muted">{@entry.progress}%</span>
    </span>
    """
  end
end
