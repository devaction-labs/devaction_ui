defmodule DevactionUI.Timeline do
  @moduledoc "Things that happened, in order, on a thin line: each item has a dot in a tone, a title, a time and optional text."
  use Phoenix.Component

  alias DevactionUI.Tone

  attr :class, :any, default: nil

  slot :item, required: true do
    attr :tone, :atom
    attr :title, :string, required: true
    attr :time, :string
  end

  attr :rest, :global

  def timeline(assigns) do
    ~H"""
    <ol class={["m-0 flex list-none flex-col p-0", @class]} {@rest}>
      <li :for={item <- @item} class="group relative flex gap-3 pb-5 last:pb-0">
        <span class="relative flex w-2.5 shrink-0 justify-center">
          <span
            class="absolute top-3 bottom-[-4px] w-px bg-line group-last:hidden"
            aria-hidden="true"
          />
          <span
            class={["mt-1.5 size-2.5 rounded-full", Tone.fill(Map.get(item, :tone, :neutral))]}
            aria-hidden="true"
          />
        </span>
        <div class="flex min-w-0 flex-col gap-0.5">
          <span class="flex flex-wrap items-baseline gap-2">
            <span class="font-medium text-ink">{item.title}</span>
            <span :if={item[:time]} class="text-xs text-muted">{item.time}</span>
          </span>
          <span :if={item.inner_block} class="text-sm text-ink-2">{render_slot(item)}</span>
        </div>
      </li>
    </ol>
    """
  end
end
