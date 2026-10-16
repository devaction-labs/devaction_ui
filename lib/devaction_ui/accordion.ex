defmodule DevactionUI.Accordion do
  @moduledoc """
  Sections that open and close. Built on `<details>`, so it works with the keyboard, in assistive
  technology and with no JavaScript. In `exclusive` mode (the default) opening one closes the others, which
  the browser does itself through the shared `name` of the `<details>`.

  Variants: `:group` is a bordered block with dividers and a chevron at the start; `:flush` is bare rows with a
  line under each and a plus that stays a plus; `:plain` is the canvas's default accordion, dividers and a
  chevron at the end that turns; `:card` gives each section its own card, with a chevron, a lead (an icon, a
  score), a sub line, a tag and actions in the header. The actions of a `:card` sit beside the header, not
  inside the `<summary>`, so pressing them does not open or close the section.

  A section can hold another accordion: nest a `:plain` one in the panel of a `:plain` or `:card` section
  and it indents 28px with a rule. A `disabled` section is drawn as a row that cannot be focused or opened,
  by pointer or by keyboard.

  The `<summary>` has no heading level of its own; `heading_level` wraps each title in an `<h2>` to `<h6>`.
  """
  use Phoenix.Component

  alias DevactionUI.{Tag, Tone}
  alias Phoenix.LiveView.JS

  attr :id, :string, required: true, doc: "also the `name` that makes the sections exclusive"

  attr :variant, :atom,
    values: [:group, :flush, :plain, :card],
    default: :group,
    doc: "the look of the sections; see the module doc"

  attr :exclusive, :boolean,
    default: true,
    doc: "opening a section closes the others; `false` lets several stay open"

  attr :heading_level, :integer,
    values: [nil, 2, 3, 4, 5, 6],
    default: nil,
    doc: "wraps each title in `<h2>`..`<h6>`; none by default"

  attr :class, :any, default: nil

  slot :item, required: true, doc: "one section; its content is the panel" do
    attr :title, :string, required: true
    attr :subtitle, :string, doc: "a line under the title (`:card`)"
    attr :count, :any, doc: "a small pill with a count beside the title"
    attr :count_tone, :atom, doc: "the tone of the count pill: risk, warn, ok, info or neutral"
    attr :tag, :string, doc: "a tag in the header (`:card`)"
    attr :tone, :atom, doc: "the tone of the tag: risk, warn, ok, info or neutral"
    attr :open, :boolean, doc: "open on first render"
    attr :disabled, :boolean, doc: "a section that cannot be opened yet"
  end

  slot :lead, doc: "what sits before the title of a `:card`; gets `%{index: n, title: text}`"

  slot :actions,
    doc: "what sits beside the header of a `:card`; gets `%{index: n, title: text}`"

  attr :rest, :global

  @doc "Sections that open and close."
  @spec accordion(map()) :: Phoenix.LiveView.Rendered.t()
  def accordion(assigns) do
    ~H"""
    <div id={@id} class={[container_class(@variant), @class]} {@rest}>
      <.section
        :for={{item, index} <- Enum.with_index(@item)}
        item={item}
        index={index}
        id={@id}
        variant={@variant}
        exclusive={@exclusive}
        heading_level={@heading_level}
        lead={@lead}
        actions={@actions}
      />
    </div>
    """
  end

  attr :item, :map, required: true
  attr :index, :integer, required: true
  attr :id, :string, required: true
  attr :variant, :atom, required: true
  attr :exclusive, :boolean, required: true
  attr :heading_level, :integer, required: true
  attr :lead, :list, required: true
  attr :actions, :list, required: true

  defp section(%{item: %{disabled: true}} = assigns) do
    ~H"""
    <div class="relative">
      <div class={details_class(@variant)}>
        <div class={[summary_class(@variant, false), "opacity-60"]} aria-disabled="true">
          <.header
            item={@item}
            index={@index}
            variant={@variant}
            heading_level={@heading_level}
            lead={@lead}
          />
        </div>
      </div>
    </div>
    """
  end

  defp section(assigns) do
    ~H"""
    <div class="relative">
      <details
        id={"#{@id}-#{@index}"}
        name={@exclusive && @id}
        open={Map.get(@item, :open, false)}
        phx-mounted={JS.ignore_attributes(["open"])}
        class={details_class(@variant)}
      >
        <summary class={summary_class(@variant, @actions != [])}>
          <.header
            item={@item}
            index={@index}
            variant={@variant}
            heading_level={@heading_level}
            lead={@lead}
          />
        </summary>
        <div class={panel_class(@variant)}>{render_slot(@item)}</div>
      </details>
      <div
        :if={@variant == :card and @actions != []}
        class="absolute top-0 right-3 flex h-[60px] items-center"
      >
        {render_slot(@actions, %{index: @index, title: @item.title})}
      </div>
    </div>
    """
  end

  attr :item, :map, required: true
  attr :index, :integer, required: true
  attr :variant, :atom, required: true
  attr :heading_level, :integer, required: true
  attr :lead, :list, required: true

  defp header(assigns) do
    ~H"""
    <.start_chevron :if={@variant in [:group, :card]} variant={@variant} />
    <span :if={@variant == :card and @lead != []} class="flex-none">
      {render_slot(@lead, %{index: @index, title: @item.title})}
    </span>
    <span class="flex min-w-0 flex-1 flex-col">
      <span class="flex items-center gap-2.5">
        <.title level={@heading_level}>{@item.title}</.title>
        <span
          :if={Map.get(@item, :count)}
          class={[
            "rounded-full px-[7px] py-0.5 font-mono text-[11px] font-normal",
            count_class(@item)
          ]}
        >
          {@item.count}
        </span>
      </span>
      <span :if={Map.get(@item, :subtitle)} class="text-[13px] font-normal text-muted">
        {@item.subtitle}
      </span>
    </span>
    <Tag.tag :if={Map.get(@item, :tag)} size={:sm} variant={Map.get(@item, :tone, :neutral)}>
      {@item.tag}
    </Tag.tag>
    <.end_marker :if={@variant in [:plain, :flush]} variant={@variant} />
    """
  end

  attr :level, :integer, required: true
  slot :inner_block, required: true

  defp title(%{level: nil} = assigns) do
    ~H"""
    {render_slot(@inner_block)}
    """
  end

  defp title(assigns) do
    ~H"""
    <.dynamic_tag tag_name={"h#{@level}"} class="m-0 [font:inherit]">
      {render_slot(@inner_block)}
    </.dynamic_tag>
    """
  end

  attr :variant, :atom, required: true

  defp start_chevron(assigns) do
    ~H"""
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="1.8"
      stroke-linecap="round"
      stroke-linejoin="round"
      aria-hidden="true"
      class={[
        "shrink-0 text-muted transition-transform duration-200 group-open:rotate-90 motion-reduce:transition-none",
        (@variant == :card && "size-4") || "size-3.5"
      ]}
    >
      <path d="m9 6 6 6-6 6" />
    </svg>
    """
  end

  attr :variant, :atom, required: true

  defp end_marker(%{variant: :plain} = assigns) do
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

  defp end_marker(assigns) do
    ~H"""
    <span class="font-mono text-lg leading-none text-muted" aria-hidden="true">+</span>
    """
  end

  defp container_class(:group),
    do: "divide-y divide-line overflow-hidden rounded-[14px] border border-line"

  defp container_class(:flush), do: nil
  defp container_class(:plain), do: "accordion"
  defp container_class(:card), do: "flex flex-col gap-2.5"

  defp details_class(:group), do: "group open:bg-wrap/60"
  defp details_class(:flush), do: "group border-b border-line-soft"
  defp details_class(:plain), do: "group"
  defp details_class(:card), do: "accordion-card group"

  defp count_class(%{count_tone: tone}) when not is_nil(tone),
    do: ["border", Tone.surface(tone), Tone.text(tone)]

  defp count_class(_item), do: "bg-wrap text-ink-2"

  defp summary_class(:plain, _actions) do
    "accordion-trigger gap-3 px-0.5 outline-none focus-visible:ring-4 focus-visible:ring-ink/10"
  end

  defp summary_class(:card, actions) do
    [
      "accordion-trigger min-h-[60px] gap-3 pl-3.5 outline-none focus-visible:ring-4 focus-visible:ring-ink/10",
      (actions && "pr-[58px]") || "pr-3"
    ]
  end

  defp summary_class(:group, _actions) do
    "flex min-h-[50px] cursor-pointer list-none items-center gap-2.5 px-3.5 text-sm font-medium text-ink outline-none marker:hidden focus-visible:bg-wrap aria-disabled:cursor-not-allowed aria-disabled:text-muted [&::-webkit-details-marker]:hidden"
  end

  defp summary_class(:flush, _actions) do
    "flex min-h-11 cursor-pointer list-none items-center justify-between gap-3 text-sm text-ink outline-none marker:hidden focus-visible:bg-wrap aria-disabled:cursor-not-allowed aria-disabled:text-muted [&::-webkit-details-marker]:hidden"
  end

  defp panel_class(variant) when variant in [:plain, :card], do: "accordion-panel"
  defp panel_class(:group), do: "pr-3.5 pb-3.5 pl-[38px] text-sm leading-relaxed text-ink-2"
  defp panel_class(:flush), do: "pt-1 pb-3.5 text-sm leading-relaxed text-ink-2"
end
