defmodule DevactionUI.Timeline do
  @moduledoc """
  Things that happened, in order, on a thin line: each item has a dot in a tone, a title, its time on the line
  below and optional text. The colour of the dot is decoration; give an item a `tone_label` (`"Failed"`) so
  assistive technology reads what the colour says, and a `datetime` to make its time a machine-readable
  `<time>`.
  """
  use Phoenix.Component

  alias DevactionUI.Tone

  attr :class, :any, default: nil

  slot :item, required: true do
    attr :tone, :atom, doc: "risk, warn, ok, info or neutral (the default, a muted dot)"
    attr :title, :string, required: true
    attr :time, :string, doc: "when it happened, as the person reads it"
    attr :datetime, :string, doc: "the same moment as an ISO 8601 value, for the `<time>` element"
    attr :tone_label, :string, doc: "what the tone of the dot means, read out before the title"
  end

  attr :rest, :global

  @doc "The list of events on a line."
  @spec timeline(map()) :: Phoenix.LiveView.Rendered.t()
  def timeline(assigns) do
    ~H"""
    <ol class={["m-0 flex list-none flex-col p-0", @class]} {@rest}>
      <li :for={item <- @item} class="group relative flex gap-3 pb-4 last:pb-0">
        <span class="relative flex w-5 shrink-0 justify-center">
          <span
            class="absolute top-5 bottom-[-4px] w-px bg-line group-last:hidden"
            aria-hidden="true"
          />
          <span
            class={["mt-[5px] size-2.5 rounded-full", dot(Map.get(item, :tone, :neutral))]}
            aria-hidden="true"
          />
        </span>
        <div class="flex min-w-0 flex-col gap-0.5">
          <span class="text-sm font-medium text-ink">
            <span :if={item[:tone_label]} class="sr-only">{item.tone_label} </span>{item.title}
          </span>
          <.moment :if={item[:time]} time={item.time} datetime={item[:datetime]} />
          <span :if={item.inner_block} class="text-sm text-ink-2">{render_slot(item)}</span>
        </div>
      </li>
    </ol>
    """
  end

  attr :time, :string, required: true
  attr :datetime, :string, default: nil

  defp moment(%{datetime: nil} = assigns) do
    ~H"""
    <span class="text-xs text-muted">{@time}</span>
    """
  end

  defp moment(assigns) do
    ~H"""
    <time datetime={@datetime} class="text-xs text-muted">{@time}</time>
    """
  end

  defp dot(:neutral), do: "bg-muted-2"
  defp dot(tone), do: Tone.fill(tone)
end
