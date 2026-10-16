defmodule DevactionUI.Progress do
  @moduledoc """
  A progress bar (`role="progressbar"`) with a value from 0 to 100 and the tone it fills with: ink by default,
  amber for what the AI did, green when it is done. `:segmented` shows the same value in `segments` pieces (the
  steps of a job), `:thin` is the 4 px line of the work in the background, and `indeterminate` is for what
  has no end in sight: it shimmers (still, under reduced motion) and gives no value.

  `size` is the thickness of a bar or a segmented one (`:md` 6 px, `:lg` 8 px); by default a bar is 6 px and a
  segmented one 8 px. `parts` draws one bar in several chunks, each with its own tone (what is done, what is
  in review). `value_label` is the text of the value (`3 of 5`, `69%`), drawn by `show_value` and read by
  assistive technology as `aria-valuetext`.
  """
  use Phoenix.Component

  alias DevactionUI.Tone

  attr :value, :integer, default: 0, doc: "0 to 100; ignored when indeterminate or with `parts`"
  attr :label, :string, required: true, doc: "what is being measured, for assistive technology"
  attr :tone, :atom, values: [:neutral, :warn, :ok, :risk, :info], default: :neutral
  attr :variant, :atom, values: [:bar, :segmented, :thin], default: :bar

  attr :size, :atom,
    values: [:auto, :md, :lg],
    default: :auto,
    doc: "thickness of a bar or a segmented one"

  attr :segments, :integer, default: 5, doc: "how many pieces the segmented one has"

  attr :parts, :list,
    default: [],
    doc:
      "chunks of one bar, in order: `[%{value: 40, tone: :ok}, %{value: 20, tone: :warn}]`; their sum is the value"

  attr :indeterminate, :boolean, default: false

  attr :value_label, :string,
    default: nil,
    doc: "the value in words (`3 of 5`); without it the value reads as a percentage"

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
        <span :if={!@indeterminate} class="font-mono text-ink-2">{@value_label ||
          "#{total(@parts, @value)}%"}</span>
      </div>
      <.progress
        value={@value}
        label={@label}
        tone={@tone}
        variant={@variant}
        size={@size}
        segments={@segments}
        parts={@parts}
        indeterminate={@indeterminate}
        value_label={@value_label}
        class={@class}
        {@rest}
      />
    </div>
    """
  end

  def progress(assigns) do
    assigns = assign(assigns, :value, assigns.parts |> total(assigns.value) |> max(0) |> min(100))
    assigns = assign(assigns, :chunks, chunks(assigns.parts, assigns.value, assigns.tone))

    ~H"""
    <div
      role="progressbar"
      aria-label={@label}
      aria-valuemin="0"
      aria-valuemax="100"
      aria-valuenow={!@indeterminate && @value}
      aria-valuetext={!@indeterminate && @value_label}
      aria-busy={@indeterminate && "true"}
      class={[
        "flex w-full overflow-hidden rounded-full bg-line",
        height(@variant, @size),
        @variant == :segmented && "gap-1.5 bg-transparent",
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
        :for={chunk <- bar_chunks(@indeterminate, @variant, @chunks)}
        class={["block h-full", Tone.fill(chunk.tone)]}
        style={"width: #{chunk.value}%"}
      />
    </div>
    """
  end

  @doc "Whether piece `index` of `segments` is filled at `value` percent."
  @spec filled?(pos_integer(), pos_integer(), 0..100) :: boolean()
  def filled?(index, segments, value), do: index * 100 <= value * segments

  defp total([], value), do: value
  defp total(parts, _value), do: parts |> Enum.map(& &1.value) |> Enum.sum()

  defp chunks([], value, tone), do: [%{value: value, tone: tone}]
  defp chunks(parts, _value, tone), do: Enum.map(parts, &Map.put_new(&1, :tone, tone))

  defp pieces(false, :segmented, segments), do: 1..segments//1
  defp pieces(_indeterminate, _variant, _segments), do: []

  defp bar_chunks(true, _variant, _chunks), do: []
  defp bar_chunks(false, :segmented, _chunks), do: []
  defp bar_chunks(false, _variant, chunks), do: chunks

  defp height(:thin, _size), do: "h-1"
  defp height(:bar, size) when size in [:auto, :md], do: "h-1.5"
  defp height(:segmented, size) when size in [:auto, :lg], do: "h-2"
  defp height(:segmented, :md), do: "h-1.5"
  defp height(:bar, :lg), do: "h-2"
end
