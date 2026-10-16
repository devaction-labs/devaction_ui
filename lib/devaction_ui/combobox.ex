defmodule DevactionUI.Combobox do
  @moduledoc """
  A select with a search box: the button shows the choice, the panel has a field that filters the list while
  you type (ignoring case and accents), ↑ ↓ move, Enter chooses, Esc closes, and an empty result says so. ↓ or
  ↑ on the button opens it. The value goes in a hidden input named `name`, and the hook fires `input` on it so
  `phx-change` hears it.
  Options are `%{value: ..., label: ..., hint: ...}`; `hint` is a small mono text at the right.

  Written as the ARIA combobox pattern: the field keeps focus and points at the active option with
  `aria-activedescendant`. The button is named by `label` and by the chosen text together
  (`aria-labelledby`), so the choice is read out.

  The options are read live: when `options` changes (a dependent select, a search on the server) the list
  follows, and the filter is applied again. What the hook sets on the page itself (open, active, filtered) is
  kept across a patch; the chosen value is the caller's, as in any LiveView field, so a form that re-renders
  should hold `value` (with `phx-change`).

  `disabled` locks it (and keeps the value out of the form), `required` marks it for assistive technology
  (a hidden input cannot be validated by the browser, so check it on the server) and `error` is the message
  that goes under it and marks it invalid. With `clear_label` there is a button that empties the choice.
  Icons are slots: `chevron_icon` (a `⌄` when there is none), `search_icon`, `clear_icon`, and
  `option_marker`, drawn before the label of each option (a color swatch, an avatar) and given the option.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  attr :id, :string, required: true
  attr :name, :string, required: true

  attr :options, :list,
    required: true,
    doc: "`%{value, label, hint}` each (`hint` is optional); read live, so they may change"

  attr :value, :string, default: nil
  attr :label, :string, required: true, doc: "what is being chosen, for assistive technology"
  attr :placeholder, :string, required: true, doc: "shown on the button when nothing is chosen"
  attr :search_placeholder, :string, required: true
  attr :empty, :string, required: true, doc: "shown when the search finds nothing"
  attr :disabled, :boolean, default: false
  attr :required, :boolean, default: false
  attr :error, :string, default: nil, doc: "the message under the field; also marks it invalid"

  attr :clear_label, :string,
    default: nil,
    doc: "the name of the button that empties the choice; none when nil"

  attr :class, :any, default: nil

  attr :rest, :global
  slot :chevron_icon, doc: "the arrow at the end of the button; turns over when open"
  slot :search_icon, doc: "the magnifier in the search field"
  slot :clear_icon, doc: "the icon of the clear button"
  slot :option_marker, doc: "drawn before the label of each option; gets the option"

  @spec combobox(map()) :: Phoenix.LiveView.Rendered.t()
  def combobox(assigns) do
    assigns =
      assign(assigns, :current, Enum.find(assigns.options, &(&1.value == assigns.value)))

    ~H"""
    <div
      id={@id}
      phx-hook="DevactionUI.Combobox"
      data-placeholder={@placeholder}
      class={["relative", @class]}
      {@rest}
    >
      <input type="hidden" name={@name} value={@value} disabled={@disabled} />
      <span id={"#{@id}-label"} class="sr-only">{@label}</span>
      <button
        type="button"
        data-trigger
        aria-haspopup="listbox"
        aria-expanded="false"
        aria-labelledby={"#{@id}-label #{@id}-current"}
        aria-describedby={@error && "#{@id}-error"}
        aria-invalid={@error && "true"}
        aria-required={@required && "true"}
        disabled={@disabled}
        phx-mounted={JS.ignore_attributes(["aria-expanded"])}
        class={[
          "group/trigger flex h-11 w-full items-center justify-between gap-2 rounded-xl border bg-card px-3.5 text-left text-[15px] text-ink outline-none focus-visible:border-ink focus-visible:ring-4 focus-visible:ring-ink/10 aria-expanded:border-ink aria-expanded:ring-4 aria-expanded:ring-ink/10 disabled:cursor-not-allowed disabled:opacity-50",
          (@error && "border-risk-fg") || "border-line-strong",
          @clear_label && "pr-10"
        ]}
      >
        <span id={"#{@id}-current"} data-current class={[!@current && "text-muted"]}>
          {(@current && @current.label) || @placeholder}
        </span>
        <span
          class="text-muted group-aria-expanded/trigger:rotate-180"
          aria-hidden="true"
        >
          {render_slot(@chevron_icon)}<span :if={@chevron_icon == []}>⌄</span>
        </span>
      </button>
      <button
        :if={@clear_label}
        type="button"
        data-clear
        aria-label={@clear_label}
        hidden={is_nil(@current)}
        disabled={@disabled}
        phx-mounted={JS.ignore_attributes(["hidden"])}
        class="absolute top-1.5 right-9 grid size-8 place-items-center rounded-lg text-muted outline-none hover:bg-wrap hover:text-ink focus-visible:ring-4 focus-visible:ring-ink/10"
      >
        {render_slot(@clear_icon)}
      </button>
      <p :if={@error} id={"#{@id}-error"} role="alert" class="m-0 mt-1.5 text-[13px] text-risk-fg">
        {@error}
      </p>
      <div
        data-panel
        hidden
        phx-mounted={JS.ignore_attributes(["hidden"])}
        class="absolute z-40 mt-1.5 w-full overflow-hidden rounded-[14px] border border-line bg-card shadow-pop"
      >
        <label class="flex h-11 items-center gap-2 border-b border-line px-3">
          <span :if={@search_icon != []} class="size-3.5 shrink-0 text-muted" aria-hidden="true">
            {render_slot(@search_icon)}
          </span>
          <input
            type="text"
            data-search
            role="combobox"
            aria-expanded="true"
            aria-controls={"#{@id}-list"}
            aria-label={@label}
            placeholder={@search_placeholder}
            autocomplete="off"
            phx-mounted={JS.ignore_attributes(["aria-activedescendant"])}
            class="h-full min-w-0 flex-1 border-0 bg-transparent p-0 text-[15px] text-ink outline-none placeholder:text-muted focus:ring-0"
          />
        </label>
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
            phx-mounted={JS.ignore_attributes(["hidden", "data-active"])}
            class="flex min-h-[38px] cursor-pointer items-center gap-2.5 rounded-[9px] px-2.5 text-sm text-ink hover:bg-wrap data-[active]:bg-wrap aria-selected:bg-wrap aria-selected:font-medium"
          >
            <span :if={@option_marker != []} class="shrink-0" aria-hidden="true">
              {render_slot(@option_marker, option)}
            </span>
            <span class="flex-1">{option.label}</span>
            <span :if={Map.get(option, :hint)} class="font-mono text-xs text-muted">{option.hint}</span>
          </li>
          <li
            data-empty
            hidden
            phx-mounted={JS.ignore_attributes(["hidden"])}
            class="px-2.5 py-3 text-sm text-muted"
          >
            {@empty}
          </li>
        </ul>
      </div>
    </div>
    """
  end
end
