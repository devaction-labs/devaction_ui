defmodule DevactionUI.ToastGroup do
  @moduledoc """
  Notices that pile up without covering the screen: while there is more than one they sit as a stack of
  layers with a count, and a click (or the button) opens them into a list with "Collapse" and "Clear".
  Each toast closes by itself after `duration` milliseconds (0 keeps it), pausing while the pointer or the
  focus is in the group or the list is open. Closing one, or clearing all, is sent to the LiveView
  (`on_dismiss`, `on_clear`), which is the source of truth: it removes the toast from what it renders.

  The caller places the group (`class="fixed right-4 bottom-4 w-[380px]"`). The newest toast is the first
  in the slot. A toast is `:dark` (the inverted one), `:light` or `:risk` (announced as an alert).
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  attr :id, :string, required: true
  attr :label, :string, required: true, doc: "the region's name, for assistive technology"

  attr :on_dismiss, :string,
    required: true,
    doc: "event sent with `phx-value-id` when a toast closes"

  attr :on_clear, :string, required: true, doc: "event sent when all are cleared"
  attr :expand_label, :string, required: true
  attr :collapse_label, :string, required: true
  attr :clear_label, :string, required: true
  attr :dismiss_label, :string, required: true, doc: "for the × of each toast"
  attr :count_label, :string, required: true, doc: "with `__COUNT__`, e.g. `__COUNT__ notices`"
  attr :class, :any, default: nil

  slot :toast, required: true do
    attr :id, :string, required: true
    attr :kind, :atom
    attr :title, :string, required: true
    attr :duration, :integer
    attr :action_label, :string
    attr :action_event, :string
  end

  attr :rest, :global

  def toast_group(assigns) do
    ~H"""
    <section
      id={@id}
      phx-hook="DevactionUI.ToastGroup"
      role="region"
      aria-label={@label}
      data-expanded="false"
      phx-mounted={JS.ignore_attributes(["data-expanded"])}
      data-on-dismiss={@on_dismiss}
      data-on-clear={@on_clear}
      data-count-label={@count_label}
      class={["relative flex flex-col gap-2", @class]}
      {@rest}
    >
      <div
        data-bar
        hidden
        class="flex items-center justify-between rounded-xl bg-wrap px-3 py-2 text-[13px]"
      >
        <span data-count class="font-mono text-xs text-muted" />
        <span class="flex gap-1">
          <button type="button" data-collapse class={bar_button()}>{@collapse_label}</button>
          <button type="button" data-clear class={bar_button()}>{@clear_label}</button>
        </span>
      </div>
      <div
        :for={{toast, index} <- Enum.with_index(@toast)}
        id={toast.id}
        data-toast
        data-duration={Map.get(toast, :duration, 5000)}
        role={role(Map.get(toast, :kind))}
        class={[
          "flex items-start gap-3 rounded-[14px] px-4 py-3.5 text-sm shadow-[0_12px_30px_rgba(24,24,27,0.25)] transition-all duration-200 motion-reduce:transition-none",
          kind_class(Map.get(toast, :kind, :dark))
        ]}
        data-index={index}
      >
        <div class="flex min-w-0 flex-1 flex-col gap-1">
          <p class="m-0 font-medium">{toast.title}</p>
          <div :if={toast.inner_block} class="opacity-80">{render_slot(toast)}</div>
        </div>
        <button
          :if={Map.get(toast, :action_label)}
          type="button"
          phx-click={Map.get(toast, :action_event)}
          phx-value-id={toast.id}
          class="shrink-0 rounded-lg bg-white/15 px-2.5 py-1 text-[13px] outline-none hover:bg-white/25 focus-visible:ring-2 focus-visible:ring-white/50"
        >
          {toast.action_label}
        </button>
        <button
          type="button"
          data-dismiss
          aria-label={@dismiss_label}
          class="shrink-0 rounded-md px-1.5 text-lg leading-none opacity-70 outline-none hover:opacity-100 focus-visible:ring-2 focus-visible:ring-current"
        >
          <span aria-hidden="true">×</span>
        </button>
      </div>
      <button
        type="button"
        data-expand
        hidden
        class="rounded-lg px-2 py-1 text-center text-[13px] text-muted outline-none hover:text-ink focus-visible:ring-2 focus-visible:ring-ink/20"
      >
        {@expand_label}
      </button>
    </section>
    """
  end

  defp bar_button,
    do:
      "rounded-md px-2 py-1 text-[13px] text-ink-2 outline-none hover:bg-line focus-visible:ring-2 focus-visible:ring-ink/20"

  defp role(:risk), do: "alert"
  defp role(_kind), do: "status"

  defp kind_class(:dark), do: "bg-ink text-on-primary"
  defp kind_class(:light), do: "border border-line bg-card text-ink"
  defp kind_class(:risk), do: "border border-tag-risk-line bg-tag-risk-bg text-tag-risk-text"
end
