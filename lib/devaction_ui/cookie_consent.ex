defmodule DevactionUI.CookieConsent do
  @moduledoc """
  The cookie notice, a bordered card anchored to the bottom of the page.

  It has a short text, three actions (preferences, only the necessary, accept all) and, when the person asks for the preferences, the list of cookie categories each with its own switch.

  It is a `role="dialog"` that is not modal (`aria-modal="false"`): the page behind stays usable, so nothing
  traps the focus and nothing takes it on mount. The server owns what is open and what is chosen: `open` shows
  the categories, `preferences_event` toggles them, `necessary_event` and `accept_event` answer the notice and
  `category_event` (with `phx-value-id`) flips a category; events are strings or `%JS{}`, and `target` serves a
  LiveComponent. A category with `locked` is on and cannot change (the necessary ones).

  The `DevactionUI.CookieConsent` hook handles the keyboard and the focus: Esc closes only the categories (it
  presses the preferences button, so the server decides), opening them moves the focus to the first switch you can
  change when it was the preferences button that had it, and closing them returns it to the button if it was lost.

  `fixed` (the default) anchors the notice to the bottom of the viewport; with `fixed={false}` it flows in the
  page, for a preview.
  """
  use Phoenix.Component

  alias DevactionUI.Switch

  attr :id, :string, required: true
  attr :title, :string, required: true, doc: "the bold lead of the text; it names the dialog"
  attr :open, :boolean, default: false, doc: "whether the list of categories is shown"
  attr :fixed, :boolean, default: true, doc: "anchored to the bottom of the viewport"

  attr :privacy_label, :string, default: nil, doc: "the text of the link to the privacy policy"
  attr :privacy_href, :string, default: nil
  attr :preferences_label, :string, required: true

  attr :preferences_event, :any,
    default: nil,
    doc: "string or `%JS{}`; toggles `open` on the server"

  attr :necessary_label, :string, required: true
  attr :necessary_event, :any, default: nil
  attr :accept_label, :string, required: true
  attr :accept_event, :any, default: nil

  attr :category_event, :any,
    default: nil,
    doc: "string or `%JS{}`, with `phx-value-id` of the category"

  attr :target, :any,
    default: nil,
    doc: "a `phx-target` (a `@myself`) when used inside a LiveComponent"

  attr :class, :any, default: nil
  attr :rest, :global

  slot :inner_block, required: true, doc: "the text of the notice, after the title"

  slot :category, doc: "a kind of cookie with its switch" do
    attr :id, :string, required: true
    attr :title, :string, required: true
    attr :description, :string
    attr :checked, :boolean
    attr :locked, :boolean, doc: "on and unchangeable"
  end

  @doc "The cookie notice."
  @spec banner(map()) :: Phoenix.LiveView.Rendered.t()
  def banner(assigns) do
    ~H"""
    <section
      id={@id}
      role="dialog"
      aria-modal="false"
      aria-labelledby={@id <> "-title"}
      aria-describedby={@id <> "-text"}
      phx-hook="DevactionUI.CookieConsent"
      data-open={to_string(@open)}
      data-fixed={to_string(@fixed)}
      class={["cookie-region", @class]}
      {@rest}
    >
      <div class="cookie-card">
        <div class="flex flex-col gap-4 sm:flex-row sm:items-start">
          <p id={@id <> "-text"} class="m-0 flex-1 text-sm leading-[1.55] text-ink-2">
            <b id={@id <> "-title"} class="font-semibold text-ink">{@title}</b>
            {render_slot(@inner_block)}
            <a
              :if={@privacy_label}
              href={@privacy_href}
              class="underline underline-offset-[3px] outline-none focus-visible:ring-4 focus-visible:ring-ink/10"
            >
              {@privacy_label}
            </a>
          </p>
          <div class="flex flex-none flex-wrap gap-2">
            <button
              type="button"
              class="cookie-btn"
              data-prefs-toggle
              aria-expanded={to_string(@open)}
              aria-controls={@id <> "-categories"}
              phx-click={@preferences_event}
              phx-target={@target}
            >
              {@preferences_label}
            </button>
            <button type="button" class="cookie-btn" phx-click={@necessary_event} phx-target={@target}>
              {@necessary_label}
            </button>
            <button
              type="button"
              class="cookie-btn cookie-btn-primary"
              phx-click={@accept_event}
              phx-target={@target}
            >
              {@accept_label}
            </button>
          </div>
        </div>
        <ul
          :if={@open}
          id={@id <> "-categories"}
          class="m-0 mt-3.5 list-none border-t border-line-soft p-0 pt-1.5"
        >
          <li
            :for={category <- @category}
            class="flex items-center gap-3 border-b border-line-soft py-2.5 text-sm"
          >
            <div class="flex-1">
              <div id={"#{@id}-cat-#{category.id}-title"} class="font-medium">{category.title}</div>
              <div
                :if={Map.get(category, :description)}
                id={"#{@id}-cat-#{category.id}-description"}
                class="text-xs text-muted"
              >
                {category.description}
              </div>
            </div>
            <Switch.switch
              id={"#{@id}-cat-#{category.id}"}
              checked={Map.get(category, :checked, false) or Map.get(category, :locked, false)}
              disabled={Map.get(category, :locked, false)}
              labelledby={"#{@id}-cat-#{category.id}-title"}
              aria-describedby={
                Map.get(category, :description) && "#{@id}-cat-#{category.id}-description"
              }
              phx-click={@category_event}
              phx-value-id={category.id}
              phx-target={@target}
            />
          </li>
        </ul>
      </div>
    </section>
    """
  end
end
