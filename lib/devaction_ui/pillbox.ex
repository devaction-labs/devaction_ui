defmodule DevactionUI.Pillbox do
  @moduledoc """
  A field of removable pills, for labels, e-mails, stacks: type and press Enter (or a comma) to add one,
  Backspace on an empty field removes the last, the × on a pill removes that one. Each pill is a hidden
  input named `name[]`, so the form submits the list as it stands; the hook fires `input` on the box so
  `phx-change` hears every change. The browser owns the pills after mount (`phx-update="ignore"`): give
  it a new `id` to reset it from the server.
  """
  use Phoenix.Component

  attr :id, :string, required: true
  attr :name, :string, required: true, doc: "the field name; the values are sent as `name[]`"
  attr :values, :list, default: []
  attr :label, :string, required: true, doc: "what the field is, for assistive technology"
  attr :placeholder, :string, default: nil
  attr :remove_label, :string, required: true, doc: "\"Remove\", for the × of each pill"
  attr :class, :any, default: nil

  attr :rest, :global

  def pillbox(assigns) do
    ~H"""
    <div
      id={@id}
      phx-hook="DevactionUI.Pillbox"
      phx-update="ignore"
      data-name={@name}
      class={[
        "flex min-h-[46px] flex-wrap items-center gap-1.5 rounded-xl border border-line-strong bg-card px-2 py-1.5 focus-within:border-ink focus-within:ring-4 focus-within:ring-ink/10",
        @class
      ]}
      {@rest}
    >
      <.pill :for={value <- @values} name={@name} value={value} remove_label={@remove_label} />
      <input
        type="text"
        aria-label={@label}
        placeholder={@placeholder}
        autocomplete="off"
        class="min-w-24 flex-1 border-0 bg-transparent p-1 text-[15px] text-ink outline-none placeholder:text-muted focus:ring-0"
      />
      <template data-pill>
        <.pill name={@name} value="" remove_label={@remove_label} />
      </template>
    </div>
    """
  end

  attr :name, :string, required: true
  attr :value, :string, required: true
  attr :remove_label, :string, required: true

  defp pill(assigns) do
    ~H"""
    <span
      data-pill-item
      class="inline-flex h-[30px] items-center gap-1 rounded-lg bg-wrap pl-2.5 text-[13px] text-ink"
    >
      <span data-label>{@value}</span>
      <input type="hidden" name={@name <> "[]"} value={@value} />
      <button
        type="button"
        data-remove
        aria-label={@remove_label}
        class="flex size-[22px] items-center justify-center rounded-md text-muted outline-none hover:bg-line focus-visible:ring-2 focus-visible:ring-ink/20"
      >
        <span aria-hidden="true">×</span>
      </button>
    </span>
    """
  end
end
