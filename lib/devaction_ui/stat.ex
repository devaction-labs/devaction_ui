defmodule DevactionUI.Stat do
  @moduledoc """
  A number with its name: the mono caption over a large value, optionally with a small `trend` tag beside
  it. `highlight` is the inverted version, white on ink, for the one number a screen is about. The value
  is the slot, so it can carry a unit (`7<span>/12</span>`).
  """
  use Phoenix.Component

  attr :label, :string, required: true
  attr :tone, :atom, values: [:default, :risk, :warn, :ok], default: :default
  attr :highlight, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true, doc: "the value"
  slot :trend

  def stat(assigns) do
    ~H"""
    <div
      class={[
        "flex flex-col gap-1.5",
        @highlight && "rounded-[14px] bg-ink p-5 text-on-primary",
        @class
      ]}
      {@rest}
    >
      <span class={[
        "font-mono text-xs uppercase tracking-[0.08em]",
        (@highlight && "opacity-70") || "text-muted"
      ]}>
        {@label}
      </span>
      <div class="flex flex-wrap items-baseline gap-2.5">
        <span class={[
          "text-[32px] font-medium tracking-[-0.02em]",
          !@highlight && value_class(@tone)
        ]}>
          {render_slot(@inner_block)}
        </span>
        {render_slot(@trend)}
      </div>
    </div>
    """
  end

  defp value_class(:default), do: "text-ink"
  defp value_class(:risk), do: "text-missing"
  defp value_class(:warn), do: "text-tag-warn-text"
  defp value_class(:ok), do: "text-tag-ok-text"
end
