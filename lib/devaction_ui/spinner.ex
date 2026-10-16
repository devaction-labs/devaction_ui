defmodule DevactionUI.Spinner do
  @moduledoc """
  A spinning ring for work in progress, one turn in 0.8 s. The label is read by screen readers and never
  drawn. `size` is `:md` (22 px, the canvas's) or `:sm` (16 px, for inside a button); `tone` colors the
  moving arc (ink by default).
  """
  use Phoenix.Component

  attr :label, :string, required: true, doc: "what is happening, for assistive technology"
  attr :size, :atom, values: [:sm, :md], default: :md
  attr :tone, :atom, values: [:neutral, :warn, :ok, :risk, :info], default: :neutral
  attr :class, :any, default: nil
  attr :rest, :global

  def spinner(assigns) do
    ~H"""
    <span
      role="status"
      class={[
        "inline-block animate-spin-fast rounded-full border-line motion-reduce:animate-none",
        size_class(@size),
        arc(@tone),
        @class
      ]}
      {@rest}
    >
      <span class="sr-only">{@label}</span>
    </span>
    """
  end

  defp size_class(:md), do: "size-[22px] border-[3px]"
  defp size_class(:sm), do: "size-4 border-2"

  defp arc(:neutral), do: "border-t-ink"
  defp arc(:warn), do: "border-t-ai"
  defp arc(:ok), do: "border-t-tag-ok-text"
  defp arc(:risk), do: "border-t-missing"
  defp arc(:info), do: "border-t-learn"
end
