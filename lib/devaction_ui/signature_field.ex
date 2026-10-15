defmodule DevactionUI.SignatureField do
  @moduledoc """
  A field to sign: draw with the mouse, the finger or the pen, or type the name; clear and start again. It
  writes what was signed into hidden inputs for the form: the method, the typed name or the SVG of the stroke
  (`DevactionUI.Signature` hook, `exportSvg`). The SVG is the drawing only, in its own coordinates, so it can be
  kept and drawn back at any size. A drawing is accepted by the server only after `safe_path?/1`.
  """
  use Phoenix.Component

  @doc "Whether a path is only path commands and numbers, so it can be drawn back without being trusted."
  @spec safe_path?(term()) :: boolean()
  def safe_path?(path) when is_binary(path),
    do: byte_size(path) <= 20_000 and Regex.match?(~r/\AM[MLl0-9.,\s\-]+\z/, path)

  def safe_path?(_other), do: false

  @doc "The SVG of a stroke, `nil` for one that is not safe."
  @spec to_svg(String.t()) :: String.t() | nil
  def to_svg(path), do: path |> safe_path?() |> svg(path)

  defp svg(true, path) do
    ~s(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 160"><path d="#{path}" fill="none" stroke="#18181B" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/></svg>)
  end

  defp svg(false, _path), do: nil

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
  attr :hint, :string, default: nil
  attr :class, :any, default: nil

  attr :target, :any,
    default: nil,
    doc: "a `phx-target` (a `@myself`) when used inside a LiveComponent"

  attr :rest, :global

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
          class="segment outline-none focus-visible:ring-4 focus-visible:ring-ink/10"
        >
          {text}
        </button>
      </div>
      <input type="hidden" name={"#{@name}[method]"} value={@mode} />
      <div
        :if={@mode == :draw}
        id={"#{@id}-pad"}
        phx-hook="DevactionUI.Signature"
        phx-update="ignore"
        class="signature-pad relative"
      >
        <svg
          viewBox="0 0 400 160"
          class="block h-full w-full cursor-crosshair"
          role="img"
          aria-label={@label}
        >
          <path
            d=""
            fill="none"
            stroke="currentColor"
            stroke-width="3"
            stroke-linecap="round"
            stroke-linejoin="round"
            class="text-ink"
          />
        </svg>
        <input type="hidden" name={"#{@name}[path]"} value="" />
        <button
          type="button"
          data-clear
          class="absolute top-2 right-2 h-8 rounded-lg border border-line bg-card px-2.5 text-[13px] text-ink-2 outline-none hover:bg-wrap focus-visible:ring-4 focus-visible:ring-ink/10"
        >
          {@clear_label}
        </button>
      </div>
      <div :if={@mode == :type} class="flex flex-col gap-2">
        <input
          id={"#{@id}-typed"}
          type="text"
          name={"#{@name}[typed]"}
          value={@typed}
          aria-label={@label}
          maxlength="120"
          class="h-11 rounded-xl border border-line-strong bg-card px-3.5 text-[15px] text-ink outline-none focus:border-ink focus:ring-4 focus:ring-ink/10"
        />
        <span class="signature-typed flex h-24 items-end rounded-xl border border-dashed border-muted/60 bg-wrap/60 px-4 pb-3">
          {@typed}
        </span>
      </div>
      <span :if={@hint} class="text-xs text-muted">{@hint}</span>
    </div>
    """
  end
end
