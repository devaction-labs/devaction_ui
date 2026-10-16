defmodule DevactionUI.Stat do
  @moduledoc """
  A number with its name: the mono caption over a large value, then a line below with a small `trend` tag and
  a `hint`. By default it is a bordered card (`bordered`); `highlight` is the inverted version, white on ink,
  for the one number a screen is about. The value is the slot, and its `unit` (`%`, `/12`, `k`) sits beside it
  in the muted 24px of the canvas.

  The label and the value are a `<dl>` pair, so assistive technology reads them together. The label is drawn
  in capitals by CSS (`uppercase`), the text itself is yours.
  """
  use Phoenix.Component

  alias DevactionUI.Tone

  attr :label, :string, required: true, doc: "the caption over the value"

  attr :tone, :atom,
    values: [:default, :risk, :warn, :ok, :info, :neutral],
    default: :default,
    doc: "the tone of the value; `:default` is plain ink"

  attr :highlight, :boolean, default: false, doc: "the inverted card, white on ink"

  attr :bordered, :boolean,
    default: true,
    doc: "the 1px card around it (not drawn when `highlight`)"

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true, doc: "the value"
  slot :unit, doc: "what the value is counted in, muted beside it"
  slot :trend, doc: "a small tag on the line below the value"
  slot :hint, doc: "a muted line of support on the line below the value"

  @doc "A captioned number."
  @spec stat(map()) :: Phoenix.LiveView.Rendered.t()
  def stat(assigns) do
    ~H"""
    <dl
      class={[
        "m-0 flex flex-col gap-2",
        @highlight && "rounded-[14px] bg-ink p-5 text-on-primary",
        !@highlight && @bordered && "rounded-[14px] border border-line p-5",
        @class
      ]}
      {@rest}
    >
      <dt class={[
        "font-mono text-xs uppercase tracking-[0.08em]",
        (@highlight && "opacity-70") || "text-muted"
      ]}>
        {@label}
      </dt>
      <dd class={[
        "m-0 text-[44px] leading-none font-medium tracking-[-0.04em]",
        !@highlight && value_class(@tone)
      ]}>
        {render_slot(@inner_block)}<span
          :if={@unit != []}
          class={["text-2xl", (@highlight && "opacity-70") || "text-muted"]}
        >{render_slot(@unit)}</span>
      </dd>
      <dd
        :if={@trend != [] or @hint != []}
        class={["m-0 flex flex-wrap items-center gap-2 text-[13px]", !@highlight && "text-muted"]}
      >
        {render_slot(@trend)}
        <span :if={@hint != []} class={@highlight && "opacity-70"}>
          {render_slot(@hint)}
        </span>
      </dd>
    </dl>
    """
  end

  defp value_class(:default), do: "text-ink"
  defp value_class(tone), do: Tone.text(tone)
end
