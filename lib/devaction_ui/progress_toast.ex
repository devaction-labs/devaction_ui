defmodule DevactionUI.ProgressToast do
  @moduledoc """
  A notice for a job that takes a while: it fills as the job advances (`progress`, 0 to 100), with a ring of
  light while it runs. When the LiveView sets `state` to `:done` it waits a moment (1.6 s, paused while the
  pointer or the focus is on it), leaves, and tells the LiveView (`on_dismiss`, with `phx-value-id`) to drop
  it. An `:error` never leaves by itself: the person reads it, tries again through the `action` slot, or
  closes it. The `icon` slot receives the state, so the mark can be a spinner while it runs, a check when it
  is done and a warning when it fails.

  The LiveView is the source of truth: it holds the job's progress (from an Oban job's PubSub, say) and
  renders this with the current `state` and `progress`.
  """
  use Phoenix.Component

  alias DevactionUI.Aura

  attr :id, :string, required: true
  attr :state, :atom, values: [:running, :done, :error], default: :running
  attr :progress, :integer, default: 0, doc: "0 to 100"
  attr :title, :string, required: true

  attr :percent_label, :string,
    default: nil,
    doc: "the text of the percentage on the right; without it, the progress and a percent sign"

  attr :on_dismiss, :string, required: true, doc: "event sent with `phx-value-id` when it leaves"
  attr :dismiss_label, :string, required: true, doc: "for the × button"
  attr :target, :any, default: nil, doc: "the `@myself` of a LiveComponent that holds the toast"
  attr :class, :any, default: nil
  attr :rest, :global

  slot :icon, doc: "drawn before the title; receives the state (`:let={state}`)"
  slot :close_icon, doc: "replaces the typographic × of the dismiss button"
  slot :inner_block, doc: "a line under the title: the step, or what went wrong"
  slot :action, doc: "shown when it failed: the button that tries again"

  def progress_toast(assigns) do
    assigns = assign(assigns, :progress, clamp(assigns.progress))

    ~H"""
    <Aura.aura :if={@state == :running} tone={:ai} class={@class}>
      <.card
        id={@id}
        state={@state}
        progress={@progress}
        title={@title}
        percent_label={@percent_label}
        on_dismiss={@on_dismiss}
        dismiss_label={@dismiss_label}
        target={@target}
        {@rest}
      >
        <:icon :let={state} :if={@icon != []}>{render_slot(@icon, state)}</:icon>
        <:action :if={@action != []}>{render_slot(@action)}</:action>
        <:close_icon :if={@close_icon != []}>{render_slot(@close_icon)}</:close_icon>
        <:detail :if={@inner_block != []}>{render_slot(@inner_block)}</:detail>
      </.card>
    </Aura.aura>
    <.card
      :if={@state != :running}
      id={@id}
      state={@state}
      progress={@progress}
      title={@title}
      percent_label={@percent_label}
      on_dismiss={@on_dismiss}
      dismiss_label={@dismiss_label}
      target={@target}
      class={@class}
      {@rest}
    >
      <:icon :let={state} :if={@icon != []}>{render_slot(@icon, state)}</:icon>
      <:action :if={@action != []}>{render_slot(@action)}</:action>
      <:close_icon :if={@close_icon != []}>{render_slot(@close_icon)}</:close_icon>
      <:detail :if={@inner_block != []}>{render_slot(@inner_block)}</:detail>
    </.card>
    """
  end

  attr :id, :string, required: true
  attr :state, :atom, required: true
  attr :progress, :integer, required: true
  attr :title, :string, required: true
  attr :percent_label, :string, default: nil
  attr :on_dismiss, :string, required: true
  attr :dismiss_label, :string, required: true
  attr :target, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :icon
  slot :close_icon
  slot :detail
  slot :action

  defp card(assigns) do
    ~H"""
    <div
      id={@id}
      phx-hook="DevactionUI.ProgressToast"
      role={role(@state)}
      data-state={@state}
      data-on-dismiss={@on_dismiss}
      class={[
        "relative flex items-start gap-3 overflow-hidden rounded-[14px] border bg-card px-4 py-3.5 text-sm text-ink shadow-toast-progress data-[leaving]:animate-toast-out motion-reduce:data-[leaving]:animate-none",
        border(@state),
        @class
      ]}
      {@rest}
    >
      <div
        role="progressbar"
        aria-label={@title}
        aria-valuemin="0"
        aria-valuemax="100"
        aria-valuenow={@progress}
        style={"width: #{@progress}%"}
        class={[
          "pointer-events-none absolute inset-y-0 left-0 transition-[width] duration-150 ease-linear motion-reduce:transition-none",
          fill(@state)
        ]}
      />
      <span :if={@icon != []} class="relative shrink-0">{render_slot(@icon, @state)}</span>
      <div class="relative flex min-w-0 flex-1 flex-col gap-0.5">
        <p class="m-0 font-semibold">{@title}</p>
        <p :if={@detail != []} class="m-0 text-[13px] text-muted">{render_slot(@detail)}</p>
      </div>
      <span class="relative shrink-0 font-mono text-xs font-semibold text-muted">
        {@percent_label || "#{@progress}%"}
      </span>
      <span :if={@state == :error and @action != []} class="relative shrink-0">
        {render_slot(@action)}
      </span>
      <button
        type="button"
        data-dismiss
        phx-click={@on_dismiss}
        phx-target={@target}
        phx-value-id={@id}
        aria-label={@dismiss_label}
        class="relative shrink-0 rounded-md px-1.5 text-lg leading-none text-muted outline-none hover:text-ink focus-visible:ring-2 focus-visible:ring-ink/20"
      >
        <span aria-hidden="true">{render_slot(@close_icon) || "×"}</span>
      </button>
    </div>
    """
  end

  defp clamp(progress), do: progress |> max(0) |> min(100)

  defp border(:running), do: "border-tag-warn-line"
  defp border(:done), do: "border-tag-ok-line"
  defp border(:error), do: "border-tag-risk-line"

  defp fill(:running), do: "bg-ai/15"
  defp fill(:done), do: "bg-tag-ok-text/12"
  defp fill(:error), do: "bg-missing/10"

  defp role(:error), do: "alert"
  defp role(_state), do: "status"
end
