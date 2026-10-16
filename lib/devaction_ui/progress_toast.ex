defmodule DevactionUI.ProgressToast do
  @moduledoc """
  A notice for a job that takes a while: it fills as the job advances (`progress`, 0 to 100), with a ring of
  light while it runs. When the LiveView sets `state` to `:done` it waits a moment (1.6 s, paused while the
  pointer or the focus is on it), leaves, and tells the LiveView (`on_dismiss`, with `phx-value-id`) to drop
  it. An `:error` never leaves by itself: the person reads it, tries again through the `action` slot, or
  closes it. The `icon` slot receives the state, so the mark can be a spinner while it runs, a check when it
  is done and a warning when it fails.

  `variant` is the look: `:fill` (the default) tints the card with the progress, with a 34 px tile for the
  icon; `:bar` is the dark card with a 3 px bar along its base, for an upload with a cancel in the `action`
  slot (shown while it runs or fails); `:steps` is the batch in stages, a count (`3/5`) over `steps` segments.
  The ring of light (`aura`) is on while a `:fill` or `:bar` one runs; `aura={false}` turns it off.

  The LiveView is the source of truth: it holds the job's progress (from an Oban job's PubSub, say) and
  renders this with the current `state` and `progress`.
  """
  use Phoenix.Component

  alias DevactionUI.{Aura, Progress}

  attr :id, :string, required: true
  attr :state, :atom, values: [:running, :done, :error], default: :running
  attr :variant, :atom, values: [:fill, :bar, :steps], default: :fill
  attr :progress, :integer, default: 0, doc: "0 to 100"
  attr :steps, :integer, default: 5, doc: "`:steps`: how many stages the batch has"
  attr :aura, :boolean, default: true, doc: "the ring of light while it runs"
  attr :title, :string, required: true

  attr :percent_label, :string,
    default: nil,
    doc:
      "the text of the percentage on the right (the count of `:steps`); without it, the progress and a percent sign, or `3/5`"

  attr :on_dismiss, :string, required: true, doc: "event sent with `phx-value-id` when it leaves"
  attr :dismiss_label, :string, required: true, doc: "for the × button"
  attr :target, :any, default: nil, doc: "the `@myself` of a LiveComponent that holds the toast"
  attr :class, :any, default: nil
  attr :rest, :global

  slot :icon, doc: "drawn before the title; receives the state (`:let={state}`)"
  slot :close_icon, doc: "replaces the typographic × of the dismiss button"
  slot :inner_block, doc: "a line under the title: the step, or what went wrong"
  slot :action, doc: "the button that tries again (`:fill`, when it failed) or cancels (`:bar`)"

  @doc "A progress notice that fills, runs a bar along its base, or counts stages."
  @spec progress_toast(map()) :: Phoenix.LiveView.Rendered.t()
  def progress_toast(assigns) do
    assigns = assign(assigns, :progress, clamp(assigns.progress))
    assigns = assign(assigns, :ring, ring?(assigns.state, assigns.variant, assigns.aura))

    ~H"""
    <Aura.aura :if={@ring} tone={:ai} class={@class}>
      <.card
        id={@id}
        state={@state}
        variant={@variant}
        steps={@steps}
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
      :if={!@ring}
      id={@id}
      state={@state}
      variant={@variant}
      steps={@steps}
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
  attr :variant, :atom, required: true
  attr :steps, :integer, required: true
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

  defp card(%{variant: :fill} = assigns) do
    ~H"""
    <.frame id={@id} state={@state} variant={@variant} on_dismiss={@on_dismiss} class={@class} {@rest}>
      <div class="flex items-center gap-3 px-4 py-3.5">
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
        <span
          :if={@icon != []}
          class={[
            "relative flex size-[34px] shrink-0 items-center justify-center rounded-[10px]",
            tile(@state)
          ]}
        >
          {render_slot(@icon, @state)}
        </span>
        <.lines title={@title} detail={@detail} detail_class="text-ink-2" />
        <span class={["relative shrink-0 font-mono text-[13px] font-medium", tint(@state)]}>
          {@percent_label || "#{@progress}%"}
        </span>
        <span :if={@state == :error and @action != []} class="relative shrink-0">
          {render_slot(@action)}
        </span>
        <.dismiss
          id={@id}
          on_dismiss={@on_dismiss}
          target={@target}
          label={@dismiss_label}
          close_icon={@close_icon}
          class="relative text-muted hover:text-ink focus-visible:ring-ink/20"
        />
      </div>
    </.frame>
    """
  end

  defp card(%{variant: :bar} = assigns) do
    ~H"""
    <.frame id={@id} state={@state} variant={@variant} on_dismiss={@on_dismiss} class={@class} {@rest}>
      <div class="flex items-center gap-3 px-4 pt-3.5 pb-4">
        <span :if={@icon != []} class="shrink-0">{render_slot(@icon, @state)}</span>
        <.lines title={@title} detail={@detail} detail_class="text-on-primary/70" />
        <span :if={@state != :done and @action != []} class="shrink-0 [&_button]:text-on-primary [&_button:hover]:bg-on-primary/10">
          {render_slot(@action)}
        </span>
        <.dismiss
          id={@id}
          on_dismiss={@on_dismiss}
          target={@target}
          label={@dismiss_label}
          close_icon={@close_icon}
          class="text-on-primary/70 hover:text-on-primary focus-visible:ring-on-primary/40"
        />
        <span class="absolute inset-x-0 bottom-0 h-[3px] bg-on-primary/15">
          <span
            role="progressbar"
            aria-label={@title}
            aria-valuemin="0"
            aria-valuemax="100"
            aria-valuenow={@progress}
            style={"width: #{@progress}%"}
            class={[
              "block h-[3px] transition-[width] duration-150 ease-linear motion-reduce:transition-none",
              bar(@state)
            ]}
          />
        </span>
      </div>
    </.frame>
    """
  end

  defp card(%{variant: :steps} = assigns) do
    assigns = assign(assigns, :done, div(assigns.progress * assigns.steps, 100))

    ~H"""
    <.frame id={@id} state={@state} variant={@variant} on_dismiss={@on_dismiss} class={@class} {@rest}>
      <div class="flex flex-col gap-2.5 px-4 py-3.5">
        <span class="flex items-center justify-between gap-3">
          <span class="font-semibold">{@title}</span>
          <span class="flex items-center gap-2">
            <span class="font-mono text-ink-2">{@percent_label || "#{@done}/#{@steps}"}</span>
            <.dismiss
              id={@id}
              on_dismiss={@on_dismiss}
              target={@target}
              label={@dismiss_label}
              close_icon={@close_icon}
              class="text-muted hover:text-ink focus-visible:ring-ink/20"
            />
          </span>
        </span>
        <Progress.progress
          label={@title}
          variant={:segmented}
          size={:md}
          gap={:sm}
          segments={@steps}
          value={@progress}
          tone={steps_tone(@state)}
        />
        <span :if={@detail != []} class="text-xs text-muted">{render_slot(@detail)}</span>
        <span :if={@state == :error and @action != []}>{render_slot(@action)}</span>
      </div>
    </.frame>
    """
  end

  attr :id, :string, required: true
  attr :state, :atom, required: true
  attr :variant, :atom, required: true
  attr :on_dismiss, :string, required: true
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  defp frame(assigns) do
    ~H"""
    <div
      id={@id}
      phx-hook="DevactionUI.ProgressToast"
      role={role(@state)}
      data-state={@state}
      data-on-dismiss={@on_dismiss}
      class={[
        "relative overflow-hidden rounded-[14px] border text-sm data-[leaving]:animate-toast-out motion-reduce:data-[leaving]:animate-none",
        frame_class(@variant, @state),
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :title, :string, required: true
  attr :detail, :list, required: true
  attr :detail_class, :string, required: true

  defp lines(assigns) do
    ~H"""
    <div class="relative flex min-w-0 flex-1 flex-col gap-0.5">
      <p class="m-0 font-semibold">{@title}</p>
      <p :if={@detail != []} class={["m-0", @detail_class]}>{render_slot(@detail)}</p>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :on_dismiss, :string, required: true
  attr :target, :any, default: nil
  attr :label, :string, required: true
  attr :close_icon, :list, default: []
  attr :class, :string, required: true

  defp dismiss(assigns) do
    ~H"""
    <button
      type="button"
      data-dismiss
      phx-click={@on_dismiss}
      phx-target={@target}
      phx-value-id={@id}
      aria-label={@label}
      class={[
        "shrink-0 rounded-md px-1.5 text-lg leading-none outline-none focus-visible:ring-2",
        @class
      ]}
    >
      <span aria-hidden="true">{render_slot(@close_icon) || "×"}</span>
    </button>
    """
  end

  defp clamp(progress), do: progress |> max(0) |> min(100)

  defp ring?(:running, variant, aura), do: aura and variant != :steps
  defp ring?(_state, _variant, _aura), do: false

  defp frame_class(:fill, state), do: ["bg-card text-ink shadow-toast-progress", border(state)]

  defp frame_class(:bar, _state),
    do: "border-transparent bg-ink text-on-primary shadow-toast-dark"

  defp frame_class(:steps, _state), do: "border-line bg-card text-ink shadow-toast-progress"

  defp border(:running), do: "border-tag-warn-line"
  defp border(:done), do: "border-tag-ok-line"
  defp border(:error), do: "border-tag-risk-line"

  defp fill(:running), do: "bg-ai/15"
  defp fill(:done), do: "bg-tag-ok-text/12"
  defp fill(:error), do: "bg-missing/10"

  defp tile(:running), do: "bg-tag-warn-bg text-tag-warn-text"
  defp tile(:done), do: "bg-tag-ok-bg text-tag-ok-text"
  defp tile(:error), do: "bg-tag-risk-bg text-tag-risk-text"

  defp tint(:running), do: "text-tag-warn-text"
  defp tint(:done), do: "text-tag-ok-text"
  defp tint(:error), do: "text-tag-risk-text"

  defp bar(:running), do: "bg-ai"
  defp bar(:done), do: "bg-dot-ok"
  defp bar(:error), do: "bg-missing"

  defp steps_tone(:running), do: :warn
  defp steps_tone(:done), do: :ok
  defp steps_tone(:error), do: :risk

  defp role(:error), do: "alert"
  defp role(_state), do: "status"
end
