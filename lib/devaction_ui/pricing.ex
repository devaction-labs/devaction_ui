defmodule DevactionUI.Pricing do
  @moduledoc """
  A table of plans with a billing toggle and a card per plan.

  The toggle (monthly or yearly) is built on `DevactionUI.Segmented`; a card has the name, tagline, price, the features with a check and the action.

  One plan can be highlighted with a ribbon, and a plan can be only text ("talk to us"). The component never
  invents a value: the price, the period, the note under it and the features all come by attr, already
  formatted by the caller. The server owns the billing period (`period`, and `billing_event` with
  `phx-value-value`) and receives the chosen plan on `event` (`phx-value-plan`); events are strings or `%JS{}`,
  and `target` serves a LiveComponent. A plan is a `:plan` slot; a `:check` slot draws the mark of a feature (a
  typographic check is the fallback).

  Each plan is an `article` named by its heading. The highlighted plan has a 2px border and the dark action; its
  ribbon is part of its text.
  """
  use Phoenix.Component

  alias DevactionUI.Segmented

  attr :id, :string, required: true

  attr :billing_label, :string,
    required: true,
    doc: "names the billing toggle for assistive technology"

  attr :billing, :list,
    default: [],
    doc:
      "`[%{value: ..., label: ..., tag: ...}]`; empty hides the toggle. `tag` is the small note beside a label"

  attr :period, :string, default: nil, doc: "the `value` of the chosen billing option"
  attr :billing_event, :any, default: nil, doc: "string or `%JS{}`, with `phx-value-value`"
  attr :event, :any, default: nil, doc: "sent by the action of a plan, with `phx-value-plan`"
  attr :target, :any, default: nil, doc: "a `phx-target` (a `@myself`) inside a LiveComponent"
  attr :class, :any, default: nil
  attr :rest, :global

  slot :title, doc: "a heading beside the billing toggle"

  slot :plan, required: true, doc: "one plan" do
    attr :id, :string, required: true
    attr :name, :string, required: true
    attr :tagline, :string
    attr :price, :string, doc: "the price as the caller writes it; never made up here"
    attr :period, :string, doc: "what the price is per, beside it (\"/month\")"
    attr :note, :string, doc: "a line under the price (\"billed yearly\")"
    attr :custom, :string, doc: "text in place of the price, for a plan with no list price"
    attr :features, :list, doc: "the lines of the feature list"
    attr :highlighted, :boolean
    attr :ribbon, :string, doc: "the label on the border of a highlighted plan"
    attr :cta, :string, required: true, doc: "the text of the action"
  end

  slot :check, doc: "the mark before a feature; the fallback is a typographic check"
  slot :footnote, doc: "small print under the plans"

  @doc "The table of plans."
  @spec table(map()) :: Phoenix.LiveView.Rendered.t()
  def table(assigns) do
    ~H"""
    <div id={@id} class={@class} {@rest}>
      <div :if={@title != [] or @billing != []} class="flex flex-wrap items-center gap-3">
        <div class="text-[17px] font-semibold text-ink">{render_slot(@title)}</div>
        <Segmented.segmented
          :if={@billing != []}
          id={@id <> "-billing"}
          label={@billing_label}
          value={@period}
          event={@billing_event}
          target={@target}
          size={:sm}
          class="pricing-billing ms-auto"
        >
          <:option
            :for={option <- @billing}
            value={option.value}
            label={option.label}
            tag={option[:tag]}
          />
        </Segmented.segmented>
      </div>
      <div class="mt-[18px] grid grid-cols-[repeat(auto-fit,minmax(12rem,1fr))] gap-3.5">
        <article
          :for={plan <- @plan}
          id={"#{@id}-plan-#{plan.id}"}
          aria-labelledby={"#{@id}-plan-#{plan.id}-name"}
          data-highlighted={to_string(Map.get(plan, :highlighted, false))}
          class="pricing-plan"
        >
          <span :if={Map.get(plan, :ribbon)} class="pricing-ribbon">{plan.ribbon}</span>
          <h3 id={"#{@id}-plan-#{plan.id}-name"} class="text-base font-semibold">{plan.name}</h3>
          <p class="mt-1 min-h-9 text-[13px] text-muted">{Map.get(plan, :tagline)}</p>
          <div class="mt-3 flex items-baseline gap-1">
            <span
              :if={Map.get(plan, :price)}
              class="text-[30px] leading-9 font-semibold tracking-[-0.02em]"
            >
              {plan.price}
            </span>
            <span :if={Map.get(plan, :price)} class="text-[13px] text-muted">
              {Map.get(plan, :period)}
            </span>
            <span
              :if={Map.get(plan, :custom)}
              class="text-[22px] leading-9 font-semibold tracking-[-0.02em]"
            >
              {plan.custom}
            </span>
          </div>
          <p class="mt-0.5 min-h-4 text-xs text-muted">{Map.get(plan, :note)}</p>
          <ul class="m-0 mt-3.5 flex list-none flex-col gap-2 p-0 text-[13px] text-ink-2">
            <li :for={feature <- Map.get(plan, :features, [])} class="flex items-start gap-2">
              <span class="mt-px flex shrink-0 text-tag-ok-text" aria-hidden="true">
                {render_slot(@check) || "✓"}
              </span>
              {feature}
            </li>
          </ul>
          <button
            type="button"
            class="pricing-cta"
            data-highlighted={to_string(Map.get(plan, :highlighted, false))}
            phx-click={@event}
            phx-value-plan={plan.id}
            phx-target={@target}
          >
            {plan.cta}
          </button>
        </article>
      </div>
      <p :if={@footnote != []} class="mt-3 text-xs text-muted">{render_slot(@footnote)}</p>
    </div>
    """
  end
end
