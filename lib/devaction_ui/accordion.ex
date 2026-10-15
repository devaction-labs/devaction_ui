defmodule DevactionUI.Accordion do
  @moduledoc """
  Sections that open and close. Built on `<details>`, so it works with the keyboard, in assistive
  technology and with no JavaScript. In `exclusive` mode (the default) opening one closes the others, which
  the browser does itself through the shared `name` of the `<details>`.

  Variants: `:group` is a bordered block with dividers and a plus or minus; `:flush` is bare rows with a line
  under each; `:plain` is the canvas's default accordion, dividers and a chevron that turns; `:card` gives each
  section its own card, with a lead (an icon, a score), a sub line, a tag and actions in the header. A section
  can hold another accordion: nest a `:plain` one in the panel and it indents with a rule.
  """
  use Phoenix.Component

  alias DevactionUI.Tag
  alias Phoenix.LiveView.JS

  attr :id, :string, required: true, doc: "also the `name` that makes the sections exclusive"
  attr :variant, :atom, values: [:group, :flush, :plain, :card], default: :group
  attr :exclusive, :boolean, default: true
  attr :class, :any, default: nil

  slot :item, required: true do
    attr :title, :string, required: true
    attr :subtitle, :string, doc: "a line under the title (`:card`)"
    attr :count, :any, doc: "a small count shown beside the title"
    attr :tag, :string, doc: "a tag in the header (`:card`)"
    attr :tone, :atom, doc: "the tone of the tag: risk, warn, ok, info or neutral"
    attr :open, :boolean
    attr :disabled, :boolean
  end

  slot :lead, doc: "what sits before the title of a `:card`; gets `%{index: n, title: text}`"

  slot :actions,
    doc: "what sits at the end of the header of a `:card`; gets `%{index: n, title: text}`"

  attr :rest, :global

  def accordion(assigns) do
    ~H"""
    <div id={@id} class={[container_class(@variant), @class]} {@rest}>
      <details
        :for={{item, index} <- Enum.with_index(@item)}
        id={"#{@id}-#{index}"}
        name={@exclusive && @id}
        open={Map.get(item, :open, false)}
        phx-mounted={JS.ignore_attributes(["open"])}
        class={details_class(@variant)}
      >
        <summary
          class={summary_class(@variant, Map.get(item, :disabled, false))}
          aria-disabled={Map.get(item, :disabled, false) && "true"}
          tabindex={Map.get(item, :disabled, false) && "-1"}
        >
          <span :if={@variant == :card and @lead != []} class="flex-none">
            {render_slot(@lead, %{index: index, title: item.title})}
          </span>
          <span class="flex min-w-0 flex-1 flex-col">
            <span class="flex items-center gap-2.5">
              {item.title}
              <span
                :if={Map.get(item, :count)}
                class="rounded-md bg-wrap px-1.5 py-0.5 font-mono text-[11px] text-muted"
              >
                {item.count}
              </span>
            </span>
            <span :if={Map.get(item, :subtitle)} class="text-[13px] font-normal text-muted">
              {item.subtitle}
            </span>
          </span>
          <Tag.tag :if={Map.get(item, :tag)} size={:sm} variant={Map.get(item, :tone, :neutral)}>
            {item.tag}
          </Tag.tag>
          <span :if={@variant == :card and @actions != []} class="flex-none">
            {render_slot(@actions, %{index: index, title: item.title})}
          </span>
          <.marker variant={@variant} />
        </summary>
        <div class={panel_class(@variant)}>{render_slot(item)}</div>
      </details>
    </div>
    """
  end

  attr :variant, :atom, required: true

  defp marker(%{variant: variant} = assigns) when variant in [:plain, :card] do
    ~H"""
    <svg
      viewBox="0 0 20 20"
      fill="none"
      stroke="currentColor"
      stroke-width="1.8"
      stroke-linecap="round"
      stroke-linejoin="round"
      aria-hidden="true"
      class="accordion-chevron"
    >
      <path d="M5 7.5l5 5 5-5" />
    </svg>
    """
  end

  defp marker(assigns) do
    ~H"""
    <span class="font-mono text-lg leading-none text-muted group-open:hidden" aria-hidden="true">
      +
    </span>
    <span
      class="hidden font-mono text-lg leading-none text-muted group-open:inline"
      aria-hidden="true"
    >
      −
    </span>
    """
  end

  defp container_class(:group),
    do: "divide-y divide-line overflow-hidden rounded-xl border border-line"

  defp container_class(:flush), do: nil
  defp container_class(:plain), do: "accordion"
  defp container_class(:card), do: "flex flex-col gap-2.5"

  defp details_class(:group), do: "group open:bg-wrap/60"
  defp details_class(:flush), do: "group border-b border-line-soft"
  defp details_class(:plain), do: "group"
  defp details_class(:card), do: "accordion-card group"

  defp summary_class(variant, disabled) when variant in [:plain, :card] do
    [
      "accordion-trigger gap-3 outline-none focus-visible:ring-4 focus-visible:ring-ink/10",
      disabled && "pointer-events-none opacity-60",
      variant == :card && "min-h-[60px]"
    ]
  end

  defp summary_class(_variant, _disabled) do
    "flex min-h-12 cursor-pointer list-none items-center justify-between gap-3 px-4 text-[15px] font-medium text-ink outline-none marker:hidden focus-visible:bg-wrap [&::-webkit-details-marker]:hidden"
  end

  defp panel_class(variant) when variant in [:plain, :card], do: "accordion-panel"
  defp panel_class(_variant), do: "px-4 pt-1 pb-4 text-sm leading-relaxed text-ink-2"
end
