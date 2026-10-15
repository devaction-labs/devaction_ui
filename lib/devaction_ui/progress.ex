defmodule DevactionUI.Progress do
  @moduledoc """
  A progress bar (`role="progressbar"`) with a value from 0 to 100 and the tone it fills with: ink by default,
  amber for what the AI did, green when it is done. `:segmented` shows the same value in `segments` pieces (the
  steps of a job), `:thin` is the 2 px line of the work in the background, and `indeterminate` is for what
  has no end in sight: it shimmers (still, under reduced motion) and gives no value.
  """
  use Phoenix.Component

  alias DevactionUI.Tone

  attr :value, :integer, default: 0, doc: "0 to 100; ignored when indeterminate"
  attr :label, :string, required: true, doc: "what is being measured, for assistive technology"
  attr :tone, :atom, values: [:neutral, :warn, :ok, :risk, :info], default: :neutral
  attr :variant, :atom, values: [:bar, :segmented, :thin], default: :bar
  attr :segments, :integer, default: 4, doc: "how many pieces the segmented one has"
  attr :indeterminate, :boolean, default: false

  attr :show_value, :boolean,
    default: false,
    doc: "draws the label on the left and the value in mono on the right, above the bar"

  attr :class, :any, default: nil
  attr :rest, :global

  def progress(%{show_value: true} = assigns) do
    ~H"""
    <div class="flex w-full flex-col gap-1.5">
      <div class="flex items-baseline justify-between gap-3 text-[13px] text-ink">
        <span>{@label}</span>
        <span :if={!@indeterminate} class="font-mono text-ink-2">{@value}%</span>
      </div>
      <.progress
        value={@value}
        label={@label}
        tone={@tone}
        variant={@variant}
        segments={@segments}
        indeterminate={@indeterminate}
        class={@class}
        {@rest}
      />
    </div>
    """
  end

  def progress(assigns) do
    assigns = assign(assigns, :value, assigns.value |> max(0) |> min(100))

    ~H"""
    <div
      role="progressbar"
      aria-label={@label}
      aria-valuemin="0"
      aria-valuemax="100"
      aria-valuenow={!@indeterminate && @value}
      aria-busy={@indeterminate && "true"}
      class={[
        "w-full overflow-hidden rounded-full bg-line",
        height(@variant),
        @variant == :segmented && "flex gap-0.5 bg-transparent",
        @class
      ]}
      {@rest}
    >
      <span
        :if={@indeterminate}
        class="block h-full w-full animate-shimmer rounded-full bg-[linear-gradient(90deg,var(--line)_0,var(--line-strong)_50%,var(--line)_100%)] bg-[length:800px_100%] motion-reduce:animate-none"
      />
      <span
        :for={index <- pieces(@indeterminate, @variant, @segments)}
        data-filled={to_string(filled?(index, @segments, @value))}
        class={[
          "block h-full flex-1 rounded-full",
          (filled?(index, @segments, @value) && Tone.fill(@tone)) || "bg-line"
        ]}
      />
      <span
        :if={!@indeterminate and @variant != :segmented}
        class={["block h-full rounded-full", Tone.fill(@tone)]}
        style={"width: #{@value}%"}
      />
    </div>
    """
  end

  @doc "Whether piece `index` of `segments` is filled at `value` percent."
  @spec filled?(pos_integer(), pos_integer(), 0..100) :: boolean()
  def filled?(index, segments, value), do: index * 100 <= value * segments

  defp pieces(false, :segmented, segments), do: 1..segments//1
  defp pieces(_indeterminate, _variant, _segments), do: []

  defp height(:bar), do: "h-1.5"
  defp height(:segmented), do: "h-2"
  defp height(:thin), do: "h-0.5"
end
