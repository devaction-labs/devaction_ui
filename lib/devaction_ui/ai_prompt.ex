defmodule DevactionUI.AiPrompt do
  @moduledoc """
  The field that talks to the AI: a pill in ink with the amber dot, a text field and a round send button.
  It is a form, so Enter sends; the LiveView gets `event` with the text under `name`.
  """
  use Phoenix.Component

  attr :id, :string, required: true
  attr :name, :string, default: "prompt"
  attr :value, :string, default: ""
  attr :label, :string, required: true, doc: "what the field is, for assistive technology"
  attr :placeholder, :string, default: nil
  attr :event, :string, required: true
  attr :send_label, :string, required: true, doc: "the name of the send button"
  attr :class, :any, default: nil
  slot :icon, required: true, doc: "the arrow of the send button, drawn by the caller"

  attr :rest, :global

  def ai_prompt(assigns) do
    ~H"""
    <form
      id={@id}
      phx-submit={@event}
      autocomplete="off"
      class={[
        "m-0 flex h-[52px] items-center gap-2.5 rounded-full bg-ink py-0 pr-2 pl-4 text-on-primary focus-within:ring-4 focus-within:ring-ink/20",
        @class
      ]}
      {@rest}
    >
      <span class="size-3 shrink-0 rounded-full bg-ai" aria-hidden="true" />
      <label for={"#{@id}-input"} class="sr-only">{@label}</label>
      <input
        id={"#{@id}-input"}
        type="text"
        name={@name}
        value={@value}
        placeholder={@placeholder}
        class="min-w-0 flex-1 border-0 bg-transparent p-0 text-on-primary outline-none placeholder:text-on-primary/60 focus:ring-0"
      />
      <button
        type="submit"
        aria-label={@send_label}
        class="flex size-10 shrink-0 items-center justify-center rounded-full border-0 bg-card text-ink outline-none transition-transform hover:scale-105 focus-visible:ring-2 focus-visible:ring-card motion-reduce:transition-none"
      >
        {render_slot(@icon)}
      </button>
    </form>
    """
  end
end
