defmodule DevactionUI.SignatureField do
  @moduledoc """
  A field to sign: draw with the mouse, the finger or the pen, or type the name; clear and start again. It
  writes what was signed into hidden inputs for the form: the method, the typed name or the SVG of the stroke
  (`DevactionUI.Signature` hook, `exportSvg`). The SVG is the drawing only, in its own coordinates, so it can be
  kept and drawn back at any size. A drawing is accepted by the server only after `safe_path?/1`.

  The pad stays mounted when the mode changes (it is only hidden), so a stroke is not lost by a look at the
  typed name; the form reads `name[method]` to know which of `name[path]` and `name[typed]` counts. Drawing has
  no keyboard equivalent: the typed mode is the way for whoever cannot draw. The typed name is set in the
  Caveat font (`.signature-typed`), which the package does not load: add Caveat (weight 500) to the page, for
  example from Google Fonts, or the name falls back to the browser's cursive. To use another face, give `font`
  (a CSS `font-family` value such as `"'Dancing Script', cursive"`) and load that one instead.

  `guide_label` writes a line of text under the guide line of the pad ("Sign above the line"); `typed_label` is
  the visible label of the name field; `required` marks the name field as required (a drawing is checked by the
  server, with `safe_path?/1`). `error` marks both ways of signing as invalid and `disabled` makes the whole field
  inert.
  """
  use Phoenix.Component

  @color ~r/\A(?:#[0-9A-Fa-f]{6}|currentColor)\z/
  @font ~r/\A[\w\s,'"-]{1,120}\z/u

  @doc "Whether a path is only path commands and numbers, so it can be drawn back without being trusted."
  @spec safe_path?(term()) :: boolean()
  def safe_path?(path) when is_binary(path),
    do: byte_size(path) <= 20_000 and Regex.match?(~r/\AM[MLl0-9.,\s\-]+\z/, path)

  def safe_path?(_other), do: false

  @doc """
  The SVG of a stroke, `nil` for one that is not safe. `color` is `#RRGGBB` or `currentColor` (default ink on
  white); another value gives `nil` too.
  """
  @spec to_svg(String.t(), String.t()) :: String.t() | nil
  def to_svg(path, color \\ "#18181B"),
    do: svg(safe_path?(path) and Regex.match?(@color, to_string(color)), path, color)

  defp font_style(font), do: font_style(font, Regex.match?(@font, to_string(font)))
  defp font_style(font, true), do: "--signature-font: #{font}"
  defp font_style(_font, false), do: nil

  defp svg(true, path, color) do
    ~s(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 360 170"><path d="#{path}" fill="none" stroke="#{color}" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/></svg>)
  end

  defp svg(false, _path, _color), do: nil

  attr :id, :string, required: true

  attr :name, :string,
    required: true,
    doc: "the form field: `name[method]`, `name[typed]` and `name[path]`"

  attr :mode, :atom, values: [:draw, :type], default: :draw
  attr :typed, :string, default: ""
  attr :label, :string, required: true
  attr :mode_event, :string, required: true, doc: "sent with `phx-value-mode` by the two buttons"
  attr :draw_label, :string, required: true
  attr :type_label, :string, required: true
  attr :clear_label, :string, required: true

  attr :pad_label, :string,
    default: nil,
    doc:
      "names the drawing area for assistive technology, as `Signature area`; without it the area is hidden from them"

  attr :empty_label, :string,
    default: nil,
    doc:
      "the status while nothing is drawn, such as \"Signature empty\"; the status shows when given"

  attr :ready_label, :string, default: nil, doc: "the status once there is a stroke"

  attr :guide_label, :string,
    default: nil,
    doc: "text under the guide line of the pad, such as \"Sign above the line\""

  attr :typed_label, :string,
    default: nil,
    doc: "the visible label of the name field; without it the field is named by `label`"

  attr :font, :string,
    default: nil,
    doc:
      "a CSS `font-family` for the typed name, such as `\"'Dancing Script', cursive\"`; the page loads the font. Letters, digits, spaces, commas, quotes and hyphens only"

  attr :hint, :string, default: nil
  attr :error, :string, default: nil
  attr :required, :boolean, default: false, doc: "marks the name field as required"
  attr :disabled, :boolean, default: false
  attr :class, :any, default: nil

  attr :target, :any,
    default: nil,
    doc: "a `phx-target` (a `@myself`) when used inside a LiveComponent"

  attr :rest, :global

  slot :clear_icon, doc: "the icon of the clear button, such as an eraser"

  def signature_field(assigns) do
    ~H"""
    <div id={@id} class={["flex flex-col gap-2.5", @class]} {@rest}>
      <div role="group" aria-label={@label} class="segmented self-start">
        <button
          :for={{mode, text} <- [draw: @draw_label, type: @type_label]}
          type="button"
          aria-pressed={to_string(@mode == mode)}
          phx-click={@mode_event}
          phx-target={@target}
          phx-value-mode={mode}
          disabled={@disabled}
          class="segment outline-none focus-visible:ring-4 focus-visible:ring-ink/10"
        >
          {text}
        </button>
      </div>
      <input type="hidden" name={"#{@name}[method]"} value={@mode} />
      <div
        hidden={@mode != :draw}
        data-invalid={@error && "true"}
        class={[
          "flex flex-col gap-1.5 data-[invalid=true]:[&_.signature-pad]:border-missing",
          @disabled && "pointer-events-none opacity-50"
        ]}
        inert={@disabled}
      >
        <div id={"#{@id}-pad"} phx-hook="DevactionUI.Signature" phx-update="ignore" class="contents">
          <div class="signature-pad relative">
            <svg
              viewBox="0 0 360 170"
              class="block h-full w-full cursor-crosshair"
              role={@pad_label && "img"}
              aria-label={@pad_label}
              aria-hidden={!@pad_label && "true"}
            >
              <line
                x1="24"
                x2="336"
                y1="128"
                y2="128"
                stroke="currentColor"
                stroke-width="1"
                class="text-line-strong"
              />
              <path
                d=""
                fill="none"
                stroke="currentColor"
                stroke-width="2.2"
                stroke-linecap="round"
                stroke-linejoin="round"
                class="text-ink"
              />
              <text :if={@guide_label} x="24" y="148" font-size="11" class="fill-muted-2">
                {@guide_label}
              </text>
            </svg>
            <input type="hidden" name={"#{@name}[path]"} value="" />
          </div>
          <div class="mt-1.5 flex items-center justify-between gap-3">
            <button
              type="button"
              data-clear
              class="inline-flex h-9 items-center gap-1.5 rounded-[9px] px-2.5 text-[13px] text-ink-2 outline-none hover:bg-wrap focus-visible:ring-4 focus-visible:ring-ink/10"
            >
              <span :if={@clear_icon != []} aria-hidden="true">{render_slot(@clear_icon)}</span>
              {@clear_label}
            </button>
            <span
              :if={@empty_label || @ready_label}
              data-status
              data-empty={@empty_label}
              data-ready={@ready_label}
              role="status"
              class="text-xs text-muted"
            >
              {@empty_label}
            </span>
          </div>
        </div>
      </div>
      <div :if={@mode == :type} class="flex flex-col gap-2">
        <label :if={@typed_label} for={"#{@id}-typed"} class="text-sm font-medium text-ink">
          {@typed_label}
        </label>
        <input
          id={"#{@id}-typed"}
          type="text"
          name={"#{@name}[typed]"}
          value={@typed}
          aria-label={!@typed_label && @label}
          required={@required}
          aria-invalid={@error && "true"}
          aria-describedby={@error && "#{@id}-error"}
          disabled={@disabled}
          maxlength="120"
          class="h-11 rounded-xl border border-line-strong bg-card px-3.5 text-[15px] text-ink outline-none focus:border-ink focus:ring-4 focus:ring-ink/10 aria-invalid:border-missing disabled:border-dashed disabled:bg-wrap"
        />
        <span
          class="signature-typed flex h-[110px] items-end rounded-xl border border-dashed border-muted/60 bg-wrap/60 px-5 pb-[18px]"
          style={font_style(@font)}
        >
          {@typed}
        </span>
      </div>
      <span :if={@hint} class="text-xs text-muted">{@hint}</span>
      <p :if={@error} id={@id <> "-error"} role="alert" class="m-0 text-[13px] text-risk-fg">
        {@error}
      </p>
    </div>
    """
  end
end
