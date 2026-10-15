defmodule DevactionUI.ColorPicker do
  @moduledoc """
  A colour field with a panel: a square for saturation and brightness, a hue strip, an optional opacity strip, a
  row of preset colours and, in a browser that has one, the eyedropper. It always sends hex (`#RRGGBB`, or
  `#RRGGBBAA` with `alpha`) in the text field named `name`, so a form reads it like any other field and
  `phx-change` hears every change.

  The area is a `role="slider"` moved with the pointer or the arrow keys (Shift for a bigger step); the hue and
  opacity strips are native range inputs. Esc closes the panel and gives the focus back to the field. All words
  are given by the caller, including the template that says the colour aloud (`area_text`), where `%{color}`,
  `%{saturation}` and `%{brightness}` are filled by the browser.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  @color ~r/\A#[0-9A-Fa-f]{6}(?:[0-9A-Fa-f]{2})?\z/
  @fallback "#2563EB"
  @presets ~w(#DC2626 #EA580C #D29A1E #16A34A #0D9488 #2563EB #7C3AED #DB2777)

  attr :id, :string, required: true
  attr :name, :string, required: true
  attr :value, :string, default: "#2563EB", doc: "`#RRGGBB`, or `#RRGGBBAA` with `alpha`"
  attr :label, :string, required: true, doc: "the visible name of the field"
  attr :presets, :list, default: @presets, doc: "the ready colours, as hex"
  attr :alpha, :boolean, default: false, doc: "adds the opacity strip"
  attr :error, :string, default: nil
  attr :toggle_label, :string, required: true, doc: "names the swatch button that opens the panel"
  attr :area_label, :string, required: true, doc: "names the saturation and brightness square"

  attr :area_text, :string,
    default: "%{color}, saturation %{saturation}%, brightness %{brightness}%",
    doc: "what the square says aloud; `%{color}`, `%{saturation}`, `%{brightness}` are filled in"

  attr :hue_label, :string, required: true
  attr :alpha_label, :string, default: nil, doc: "names the opacity strip; required with `alpha`"
  attr :presets_label, :string, required: true

  attr :eyedropper_label, :string,
    default: nil,
    doc: "the eyedropper button's text; it shows only when given"

  attr :class, :any, default: nil
  attr :rest, :global

  def color_picker(assigns) do
    assigns =
      assign(assigns,
        safe_value: safe(assigns.value),
        safe_presets: Enum.filter(assigns.presets, &(safe(&1, nil) != nil))
      )

    ~H"""
    <div
      id={@id <> "-picker"}
      phx-hook="DevactionUI.ColorPicker"
      phx-mounted={keep_client_attributes()}
      data-value={@safe_value}
      data-area-text={@area_text}
      style={"--cp-color: #{@safe_value}"}
      class={["color-picker", @class]}
      {@rest}
    >
      <label for={@id} class="mb-1.5 block text-sm font-medium text-ink">{@label}</label>
      <div class="color-picker-field" data-invalid={@error && "true"}>
        <button
          type="button"
          class="color-picker-swatch"
          data-toggle
          aria-haspopup="dialog"
          aria-expanded="false"
          aria-label={@toggle_label}
          phx-mounted={keep_client_attributes()}
        ></button>
        <input
          type="text"
          id={@id}
          name={@name}
          value={@value}
          class="color-picker-input"
          data-input
          spellcheck="false"
          autocomplete="off"
          maxlength="9"
          aria-invalid={@error && "true"}
          aria-describedby={@error && @id <> "-error"}
        />
      </div>
      <div
        class="color-picker-panel"
        role="dialog"
        aria-label={@label}
        data-panel
        hidden
        phx-mounted={keep_client_attributes()}
      >
        <div
          class="color-picker-area"
          role="slider"
          tabindex="0"
          aria-label={@area_label}
          data-area
        >
          <span class="color-picker-handle" data-handle></span>
        </div>
        <input
          type="range"
          min="0"
          max="360"
          class="color-picker-hue"
          aria-label={@hue_label}
          data-hue
        />
        <input
          :if={@alpha}
          type="range"
          min="0"
          max="100"
          class="color-picker-alpha"
          aria-label={@alpha_label}
          data-alpha
        />
        <button
          :if={@eyedropper_label}
          type="button"
          hidden
          data-eyedropper
          class="self-start rounded-lg px-2 py-1 text-sm text-ink-2 hover:bg-wrap"
        >
          {@eyedropper_label}
        </button>
        <div class="color-picker-presets" role="radiogroup" aria-label={@presets_label}>
          <button
            :for={preset <- @safe_presets}
            type="button"
            role="radio"
            class="color-picker-preset"
            style={"background: #{preset}"}
            data-preset={preset}
            aria-label={preset}
            aria-checked="false"
            phx-mounted={keep_client_attributes()}
          ></button>
        </div>
      </div>
      <p :if={@error} id={@id <> "-error"} class="mt-1.5 mb-0 text-[13px] text-risk-fg">{@error}</p>
    </div>
    """
  end

  defp safe(color, fallback \\ @fallback),
    do: safe(color, fallback, Regex.match?(@color, to_string(color)))

  defp safe(color, _fallback, true), do: color
  defp safe(_color, fallback, false), do: fallback

  defp keep_client_attributes do
    JS.ignore_attributes(["hidden", "aria-expanded", "aria-checked", "style", "data-open"])
  end
end
