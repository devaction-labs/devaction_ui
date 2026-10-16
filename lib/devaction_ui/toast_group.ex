defmodule DevactionUI.ToastGroup do
  @moduledoc """
  Notices that pile up without covering the screen: as soon as there is more than one, the newest shows alone
  with up to two layers peeking out above it, a little narrower each. Pointing at the pile (or focusing it)
  opens it by itself into a panel with the `heading` and the count, "Collapse" and "Clear", where each notice
  is a white card with its dot, and it closes a moment after the pointer leaves; a click (or a tap) keeps it
  open until "Collapse".
  Each toast closes by itself after `duration` milliseconds (0 keeps it), pausing while the pointer or the
  focus is in the group or the list is open. Closing one, or clearing all, is sent to the LiveView
  (`on_dismiss`, `on_clear`), which is the source of truth: it removes the toast from what it renders.

  Escape closes an open list, or the toast the focus is on. The region is `aria-live="polite"`; a `:risk`
  toast is announced as an alert.

  The caller places the group (`class="fixed right-4 bottom-4 w-[380px]"`). The newest toast is the first
  in the slot. A toast is `:dark` (the inverted one), `:light` or `:risk` (announced as an alert).
  """
  use Phoenix.Component

  alias DevactionUI.Tone
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

  attr :heading, :string,
    default: nil,
    doc: "the title of the open panel, before the count (`AI review`)"

  attr :class, :any, default: nil

  slot :toast, required: true do
    attr :id, :string, required: true
    attr :kind, :atom, values: [:dark, :light, :risk]
    attr :dot, :atom, values: [:ok, :warn, :risk, :info, :neutral, :indigo, :emerald]
    attr :title, :string, required: true
    attr :duration, :integer
    attr :action_label, :string
    attr :action_event, :string
    attr :action_target, :any, doc: "the `@myself` that receives `action_event`"
    attr :action_navigate, :string, doc: "a path the action goes to, instead of sending an event"
  end

  attr :rest, :global
  slot :close_icon, doc: "replaces the typographic × that dismisses a toast"

  slot :icon,
    doc:
      "drawn before the title of each toast; receives its kind (`:let={kind}`), so each can have its own"

  @doc "The group of notices: a stack while collapsed, a panel of cards when opened."
  @spec toast_group(map()) :: Phoenix.LiveView.Rendered.t()
  def toast_group(assigns) do
    assigns = assign(assigns, count: length(assigns.toast))

    ~H"""
    <section
      id={@id}
      phx-hook="DevactionUI.ToastGroup"
      role="region"
      aria-label={@label}
      aria-live="polite"
      data-expanded="false"
      data-stacked={to_string(@count > 1)}
      phx-mounted={JS.ignore_attributes(["data-expanded", "data-stacked"])}
      data-on-dismiss={@on_dismiss}
      data-on-clear={@on_clear}
      data-count-label={@count_label}
      data-heading={@heading}
      class={[
        "group relative flex flex-col gap-2 data-[stacked=true]:cursor-pointer data-[stacked=true]:pt-4 data-[expanded=true]:rounded-2xl data-[expanded=true]:bg-wrap data-[expanded=true]:p-3",
        @class
      ]}
      {@rest}
    >
      <span
        data-layer="2"
        hidden={@count < 3}
        aria-hidden="true"
        class="pointer-events-none absolute inset-x-7 top-0 bottom-0 rounded-[14px] bg-toast-layer-2 group-data-[stacked=false]:hidden"
      />
      <span
        data-layer="1"
        hidden={@count < 2}
        aria-hidden="true"
        class="pointer-events-none absolute inset-x-3.5 top-2 bottom-0 rounded-[14px] bg-toast-layer-1 group-data-[stacked=false]:hidden"
      />
      <div data-bar hidden class="flex items-center justify-between text-[13px]">
        <span data-count class="font-semibold" />
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
          "flex items-start gap-3 rounded-[14px] px-4 py-3.5 text-sm group-data-[stacked=true]:relative group-data-[stacked=true]:z-20 group-data-[stacked=true]:data-[behind]:hidden",
          kind_class(Map.get(toast, :kind, :dark))
        ]}
        data-index={index}
        data-behind={index > 0}
      >
        <span :if={@icon != []} class="shrink-0" aria-hidden="true">
          {render_slot(@icon, Map.get(toast, :kind, :dark))}
        </span>
        <span
          :if={Map.get(toast, :dot)}
          aria-hidden="true"
          class={[
            "mt-[5px] size-2.5 shrink-0 rounded-full group-data-[expanded=true]:size-2",
            Tone.dot(Map.get(toast, :dot))
          ]}
        />
        <div class="flex min-w-0 flex-1 flex-col gap-1">
          <p class="m-0 font-semibold">{toast.title}</p>
          <div :if={toast.inner_block} class={line_class(Map.get(toast, :kind, :dark))}>
            {render_slot(toast)}
          </div>
        </div>
        <.action :if={Map.get(toast, :action_label)} toast={toast} />
        <button
          type="button"
          data-dismiss
          aria-label={@dismiss_label}
          class="shrink-0 rounded-md px-1.5 text-lg leading-none opacity-70 outline-none hover:opacity-100 focus-visible:ring-2 focus-visible:ring-current"
        >
          <span aria-hidden="true">{render_slot(@close_icon) || "×"}</span>
        </button>
      </div>
      <button
        type="button"
        data-expand
        hidden
        class="sr-only"
      >
        {@expand_label}
      </button>
    </section>
    """
  end

  attr :toast, :map, required: true

  defp action(%{toast: %{action_navigate: path}} = assigns) when is_binary(path) do
    ~H"""
    <.link navigate={@toast.action_navigate} class={action_class(Map.get(@toast, :kind, :dark))}>
      {@toast.action_label}
    </.link>
    """
  end

  defp action(assigns) do
    ~H"""
    <button
      type="button"
      phx-click={Map.get(@toast, :action_event)}
      phx-target={Map.get(@toast, :action_target)}
      phx-value-id={@toast.id}
      class={action_class(Map.get(@toast, :kind, :dark))}
    >
      {@toast.action_label}
    </button>
    """
  end

  defp action_class(:dark),
    do:
      "inline-flex h-[30px] shrink-0 items-center rounded-lg bg-on-primary/15 px-2 text-xs outline-none hover:bg-on-primary/25 focus-visible:ring-2 focus-visible:ring-on-primary/50"

  defp action_class(_kind),
    do:
      "shrink-0 rounded-md px-1 text-[13px] font-medium underline-offset-2 outline-none hover:underline focus-visible:ring-2 focus-visible:ring-current"

  defp bar_button,
    do:
      "rounded-md px-2 py-1 text-[13px] text-ink-2 outline-none hover:bg-line focus-visible:ring-2 focus-visible:ring-ink/20"

  defp role(:risk), do: "alert"
  defp role(_kind), do: "status"

  defp kind_class(:dark),
    do: ["bg-ink text-on-primary shadow-toast-dark", expanded_card()]

  defp kind_class(:light),
    do: ["border border-line bg-card text-ink shadow-toast-light", expanded_card()]

  defp kind_class(:risk), do: "border border-tag-risk-line bg-tag-risk-bg text-tag-risk-text"

  defp expanded_card,
    do:
      "group-data-[expanded=true]:rounded-xl group-data-[expanded=true]:border group-data-[expanded=true]:border-line group-data-[expanded=true]:bg-card group-data-[expanded=true]:px-3 group-data-[expanded=true]:py-2.5 group-data-[expanded=true]:text-[13px] group-data-[expanded=true]:text-ink group-data-[expanded=true]:shadow-none"

  defp line_class(:dark), do: "text-on-primary/70 group-data-[expanded=true]:text-muted"
  defp line_class(:light), do: "text-muted"
  defp line_class(:risk), do: "opacity-80"
end
