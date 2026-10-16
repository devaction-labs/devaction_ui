defmodule DevactionUI.Spinner do
  @moduledoc """
  A spinning ring for work in progress, one turn in 0.8 s. The label is read by screen readers and never
  drawn. `size` is `:md` (22 px, the canvas's) or `:sm` (16 px, for inside a button); `tone` colors the
  moving arc (ink by default).

  `dots/1` is the other indicator of the canvas: three dots of 7 px that pulse one after the other, for a
  line of text that is being written (the AI answering). It stands still under `prefers-reduced-motion`.
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

  attr :label, :string, required: true, doc: "what is happening, for assistive technology"
  attr :tone, :atom, values: [:neutral, :warn, :ok, :risk, :info], default: :neutral
  attr :class, :any, default: nil
  attr :rest, :global

  @doc "Three dots that pulse one after the other."
  @spec dots(map()) :: Phoenix.LiveView.Rendered.t()
  def dots(assigns) do
    ~H"""
    <span role="status" class={["inline-flex items-center gap-1", @class]} {@rest}>
      <span class="sr-only">{@label}</span>
      <span
        :for={delay <- ["", "[animation-delay:0.2s]", "[animation-delay:0.4s]"]}
        aria-hidden="true"
        class={[
          "size-[7px] animate-pulse-dot-fast rounded-full motion-reduce:animate-none",
          dot(@tone),
          delay
        ]}
      />
    </span>
    """
  end

  defp dot(:neutral), do: "bg-ink"
  defp dot(:warn), do: "bg-ai"
  defp dot(:ok), do: "bg-tag-ok-text"
  defp dot(:risk), do: "bg-missing"
  defp dot(:info), do: "bg-learn"
end
