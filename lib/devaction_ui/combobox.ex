defmodule DevactionUI.Combobox do
  @moduledoc """
  A select with a search box: the button shows the choice, the panel has a field that filters the list while
  you type (ignoring case and accents), ↑ ↓ move, Enter chooses, Esc closes, and an empty result says so.
  The value goes in a hidden input named `name`, and the hook fires `input` on it so `phx-change` hears it.
  Options are `%{value: ..., label: ..., hint: ...}`; `hint` is a small mono text at the right.

  Written as the ARIA combobox pattern: the field keeps focus and points at the active option with
  `aria-activedescendant`.
  """
  use Phoenix.Component

  attr :id, :string, required: true
  attr :name, :string, required: true
  attr :options, :list, required: true
  attr :value, :string, default: nil
  attr :label, :string, required: true, doc: "what is being chosen, for assistive technology"
  attr :placeholder, :string, required: true, doc: "shown on the button when nothing is chosen"
  attr :search_placeholder, :string, required: true
  attr :empty, :string, required: true, doc: "shown when the search finds nothing"
  attr :class, :any, default: nil

  attr :rest, :global

  def combobox(assigns) do
    assigns = assign(assigns, :current, Enum.find(assigns.options, &(&1.value == assigns.value)))

    ~H"""
    <div
      id={@id}
      phx-hook="DevactionUI.Combobox"
      phx-update="ignore"
      class={["relative", @class]}
      {@rest}
    >
      <input type="hidden" name={@name} value={@value} />
      <button
        type="button"
        data-trigger
        aria-haspopup="listbox"
        aria-expanded="false"
        aria-label={@label}
        class="flex h-[46px] w-full items-center justify-between gap-2 rounded-xl border border-line-strong bg-card px-3.5 text-left text-[15px] text-ink outline-none focus-visible:border-ink focus-visible:ring-4 focus-visible:ring-ink/10"
      >
        <span data-current class={[!@current && "text-muted"]}>
          {(@current && @current.label) || @placeholder}
        </span>
        <span class="text-muted" aria-hidden="true">⌄</span>
      </button>
      <div
        data-panel
        hidden
        class="absolute z-40 mt-1.5 w-full rounded-[14px] border border-line bg-card shadow-[0_16px_40px_rgba(24,24,27,0.12)]"
      >
        <input
          type="text"
          data-search
          role="combobox"
          aria-expanded="true"
          aria-controls={"#{@id}-list"}
          aria-label={@label}
          placeholder={@search_placeholder}
          autocomplete="off"
          class="h-11 w-full rounded-t-[14px] border-0 border-b border-line bg-transparent px-3.5 text-[15px] text-ink outline-none placeholder:text-muted focus:ring-0"
        />
        <ul
          id={"#{@id}-list"}
          role="listbox"
          aria-label={@label}
          class="m-0 max-h-52 list-none overflow-y-auto p-1.5"
        >
          <li
            :for={{option, index} <- Enum.with_index(@options)}
            id={"#{@id}-option-#{index}"}
            role="option"
            data-value={option.value}
            data-label={option.label}
            aria-selected={to_string(option.value == @value)}
            class="flex min-h-[38px] cursor-pointer items-center justify-between gap-3 rounded-[9px] px-2.5 text-sm text-ink data-[active]:bg-wrap aria-selected:font-medium"
          >
            <span>{option.label}</span>
            <span :if={Map.get(option, :hint)} class="font-mono text-xs text-muted">{option.hint}</span>
          </li>
          <li data-empty hidden class="px-2.5 py-3 text-sm text-muted">{@empty}</li>
        </ul>
      </div>
    </div>
    """
  end
end
