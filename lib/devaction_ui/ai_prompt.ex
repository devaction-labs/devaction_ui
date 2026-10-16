defmodule DevactionUI.AiPrompt do
  @moduledoc """
  The field that talks to the AI: a pill in ink with the amber dot, a text field and a round send button.
  It is a form, so Enter sends; the LiveView gets `event` with `%{name => text}` (`%{"prompt" => "..."}` by
  default). The field is `required`, so an empty send never leaves the browser.

  `loading` marks the form `aria-busy` and disables the send button while the AI answers; `disabled` locks the
  whole field. `streaming` is the answer arriving: the form is busy and, with `on_stop` (and its `stop_label`),
  the send button becomes a stop button that sends that event; its icon is the `stop` slot. The `attachments`
  slot is what goes with the question (chips of files, a pasted link), drawn by the caller between the amber
  dot and the field. LiveView does not overwrite a field that has focus, so the text stays after a send: to
  clear it, render the component with a new `id` (it remounts empty).

  The pill is `bg-ink` with `text-on-primary` and the button `bg-card text-ink`: the tokens swap together, so
  in the dark theme it is a light pill with a dark button, on purpose (the canvas only draws the light one).
  """
  use Phoenix.Component

  attr :id, :string, required: true
  attr :name, :string, default: "prompt"
  attr :value, :string, default: ""
  attr :label, :string, required: true, doc: "what the field is, for assistive technology"
  attr :placeholder, :string, default: nil
  attr :event, :string, required: true
  attr :send_label, :string, required: true, doc: "the name of the send button"
  attr :loading, :boolean, default: false, doc: "an answer is on its way: the send button is off"
  attr :disabled, :boolean, default: false

  attr :streaming, :boolean,
    default: false,
    doc: "the answer is arriving: busy, and a stop button instead of send when `on_stop` is set"

  attr :on_stop, :string, default: nil, doc: "the event of the stop button"
  attr :stop_label, :string, default: nil, doc: "the name of the stop button; `on_stop` needs it"
  attr :class, :any, default: nil
  slot :icon, required: true, doc: "the arrow of the send button, drawn by the caller"
  slot :stop, doc: "the icon of the stop button, drawn by the caller"
  slot :attachments, doc: "what goes with the question, between the dot and the field"

  attr :target, :any,
    default: nil,
    doc: "a `phx-target` (a `@myself`) when used inside a LiveComponent"

  attr :rest, :global

  def ai_prompt(%{on_stop: on_stop, stop_label: nil}) when is_binary(on_stop),
    do: raise(ArgumentError, "ai_prompt: `on_stop` needs a `stop_label`")

  def ai_prompt(assigns) do
    assigns = assign(assigns, :stoppable, assigns.streaming and is_binary(assigns.on_stop))

    ~H"""
    <form
      id={@id}
      phx-submit={@event}
      phx-target={@target}
      aria-busy={(@loading or @streaming) && "true"}
      autocomplete="off"
      class={[
        "m-0 flex h-[52px] items-center gap-2.5 rounded-full bg-ink py-0 pr-2 pl-4 text-on-primary focus-within:ring-4 focus-within:ring-ink/20",
        @class
      ]}
      {@rest}
    >
      <span class="size-3 shrink-0 rounded-full bg-ai" aria-hidden="true" />
      <div
        :if={@attachments != []}
        class="flex max-w-[40%] shrink-0 items-center gap-1.5 overflow-x-auto"
      >
        {render_slot(@attachments)}
      </div>
      <label for={"#{@id}-input"} class="sr-only">{@label}</label>
      <input
        id={"#{@id}-input"}
        type="text"
        name={@name}
        value={@value}
        required
        disabled={@disabled}
        placeholder={@placeholder}
        class="min-w-0 flex-1 border-0 bg-transparent p-0 text-on-primary outline-none placeholder:text-on-primary/60 focus:ring-0"
      />
      <button
        :if={@stoppable}
        type="button"
        data-stop
        disabled={@disabled}
        aria-label={@stop_label}
        phx-click={@on_stop}
        phx-target={@target}
        class="flex size-10 shrink-0 items-center justify-center rounded-full border-0 bg-card text-ink outline-none transition-transform hover:scale-105 focus-visible:ring-2 focus-visible:ring-card disabled:opacity-50 disabled:hover:scale-100 motion-reduce:transition-none"
      >
        {render_slot(@stop)}
      </button>
      <button
        :if={!@stoppable}
        type="submit"
        disabled={@disabled or @loading or @streaming}
        aria-label={@send_label}
        class="flex size-10 shrink-0 items-center justify-center rounded-full border-0 bg-card text-ink outline-none transition-transform hover:scale-105 focus-visible:ring-2 focus-visible:ring-card disabled:opacity-50 disabled:hover:scale-100 motion-reduce:transition-none"
      >
        {render_slot(@icon)}
      </button>
    </form>
    """
  end
end
