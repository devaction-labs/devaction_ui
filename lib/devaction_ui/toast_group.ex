defmodule DevactionUI.ToastGroup do
  @moduledoc """
  A pile of toasts that opens into a list when you point at it: notices pushed from the server that never cover
  the screen. Put one `toast_group/1` in the layout and push toasts to it from any LiveView with `put_toast/4`,
  `update_toast/3`, `dismiss_toast/2` and `clear_toasts/1`.

  A new toast enters from below and pushes the others behind the pile. Closed, only the front one shows and up
  to two peek behind it, smaller and without text. With the pointer over it, or the focus inside, the pile opens
  into a list with a 12px gap that does not close it. The timers pause while it is open and while the tab is
  hidden, and go on from where they stopped. `Alt+T` moves the focus to the pile, `Esc` closes the focused toast
  and a drag sideways (past 80px) dismisses it. A `:risk` toast is announced at once (`role="alert"`), the rest
  politely (`role="status"`) inside a region with `aria-live="polite"`. A `:loading` toast never leaves by
  itself: `update_toast/3` turns it into `:ok` or `:risk` with the same id.

  Variants: `:default`, `:ok`, `:warn`, `:risk`, `:info`, `:ai` and `:loading` (a spinning icon). An action is
  `action: %{label: "Undo", event: "undo", value: %{id: 9}}`: the button sends `event` with `value` back to the
  LiveView (or to `target`) and closes the toast.

  The library has no language: every text (title, description, action label) comes from the caller, and the
  close button takes its name from `dismiss_label`. The icons are drawn here as defaults and replaced by the
  `:icon` slot (it receives the variant) and the `:close_icon` slot. The list itself belongs to the browser
  (`phx-update="ignore"`), so a re-render never disturbs a pile that is open. From the page, without the server:
  `window.dispatchEvent(new CustomEvent("dui:toast", {detail: {title: "Copied"}}))`.

      <DevactionUI.ToastGroup.toast_group flash={@flash} label="Notifications (Alt+T)" dismiss_label="Close" />

      socket |> put_toast(:ok, "Review published", description: "PR #214")
      socket |> put_toast(:loading, "Building report", id: "report")
      socket |> update_toast("report", variant: :ok, title: "Report ready")
  """
  use Phoenix.Component

  alias Phoenix.LiveView
  alias Phoenix.LiveView.JS

  @variants ~w(default ok warn risk info ai loading)a
  @icon_variants ~w(ok warn risk info ai loading)a
  @positions ~w(bottom-right bottom-left bottom-center top-right top-left top-center)

  @type variant :: :default | :ok | :warn | :risk | :info | :ai | :loading
  @type action :: %{
          required(:label) => String.t(),
          required(:event) => String.t(),
          optional(:value) => map()
        }

  @paths %{
    ok: "M5 13l4 4L19 7",
    warn:
      "M12 9v4m0 4h.01M10.3 3.9L1.8 18a2 2 0 001.7 3h17a2 2 0 001.7-3L13.7 3.9a2 2 0 00-3.4 0z",
    risk: "M12 8v5m0 3h.01M12 3a9 9 0 100 18 9 9 0 000-18z",
    info: "M12 11v5m0-8h.01M12 3a9 9 0 100 18 9 9 0 000-18z",
    ai: "M12 3l1.8 4.7L18.5 9.5l-4.7 1.8L12 16l-1.8-4.7L5.5 9.5l4.7-1.8L12 3z",
    loading: "M12 3a9 9 0 109 9",
    close: "M6 6l12 12M18 6L6 18"
  }

  attr :id, :string, default: "toasts"

  attr :flash, :map,
    default: %{},
    doc: "the flash of the socket: `info` shows as an `:ok` toast and `error` as a `:risk` one"

  attr :position, :string, default: "bottom-right", values: @positions

  attr :visible, :integer,
    default: 3,
    doc: "how many show in the closed pile: the front one and the ones peeking behind it"

  attr :duration, :integer,
    default: 4000,
    doc: "milliseconds before a toast closes by itself; `0` keeps them until they are closed"

  attr :label, :string,
    required: true,
    doc: "the region's name for assistive technology, such as `Notifications (Alt+T)`"

  attr :dismiss_label, :string, required: true, doc: "the name of the close button of each toast"

  attr :target, :any,
    default: nil,
    doc: "the `@myself` (or selector) that receives the events of the toast actions"

  attr :inline, :boolean,
    default: false,
    doc: "lay the group out in the flow (relative) instead of fixed to the viewport"

  attr :hotkey, :boolean,
    default: true,
    doc:
      "whether `Alt+T` moves the focus here; turn it off in all but one group when a page has several"

  attr :class, :any, default: nil
  attr :rest, :global

  slot :icon,
    doc:
      "replaces the icon of each variant (`:let={variant}`: `:ok`, `:warn`, `:risk`, `:info`, `:ai`, `:loading`)"

  slot :close_icon, doc: "replaces the × of the close button"

  @doc "The group of toasts: one per layout, filled by `put_toast/4` and its siblings."
  @spec toast_group(map()) :: Phoenix.LiveView.Rendered.t()
  def toast_group(assigns) do
    assigns =
      assigns
      |> assign(:initial, Jason.encode!(flash_toasts(assigns.flash)))
      |> assign(:icon_variants, @icon_variants)

    ~H"""
    <section
      id={@id}
      class={["toast-group", @class]}
      role="region"
      aria-label={@label}
      aria-live="polite"
      aria-relevant="additions text"
      tabindex="-1"
      phx-hook="DevactionUI.ToastGroup"
      phx-mounted={JS.ignore_attributes(["data-expanded"])}
      phx-target={@target}
      data-position={@position}
      data-inline={@inline}
      data-hotkey={to_string(@hotkey)}
      data-visible={@visible}
      data-duration={@duration}
      data-dismiss-label={@dismiss_label}
      data-initial={@initial}
      {@rest}
    >
      <ol id={"#{@id}-list"} class="toast-list" data-toasts phx-update="ignore"></ol>
      <template :for={variant <- @icon_variants} data-icon={variant}>
        <.mark name={variant} slot={@icon} variant={variant} />
      </template>
      <template data-icon="close">
        <.mark name={:close} slot={@close_icon} variant={nil} />
      </template>
    </section>
    """
  end

  attr :name, :atom, required: true
  attr :slot, :list, required: true
  attr :variant, :atom, default: nil

  defp mark(%{slot: []} = assigns), do: glyph(assigns)

  defp mark(assigns) do
    ~H"""
    {render_slot(@slot, @variant)}
    """
  end

  attr :name, :atom, required: true

  defp glyph(assigns) do
    assigns = assign(assigns, :path, Map.fetch!(@paths, assigns.name))

    ~H"""
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="1.8"
      stroke-linecap="round"
      stroke-linejoin="round"
      aria-hidden="true"
    >
      <path d={@path} />
    </svg>
    """
  end

  defp flash_toasts(flash) do
    [info: :ok, error: :risk]
    |> Enum.flat_map(fn {key, variant} ->
      flash |> Phoenix.Flash.get(key) |> flash_toast(key, variant)
    end)
  end

  defp flash_toast(nil, _key, _variant), do: []

  defp flash_toast(message, key, variant),
    do: [%{id: "flash-#{key}", title: message, variant: variant}]

  @doc """
  Pushes a toast to the group of the page. `opts`: `:id` (to update or dismiss it later), `:description`,
  `:duration` (milliseconds, `0` keeps it until it is closed; `:loading` ignores it), `:action`
  (`%{label: "Undo", event: "undo", value: %{id: 9}}`) and `:group`.

  LiveView delivers server events to every hook of the page, so a page with more than one group names the
  one it means with `group: "id-of-the-group"`; without it every group shows the toast.
  """
  @spec put_toast(Phoenix.LiveView.Socket.t(), variant(), String.t(), keyword()) ::
          Phoenix.LiveView.Socket.t()
  def put_toast(socket, variant, title, opts \\ []) when variant in @variants do
    payload = opts |> Map.new() |> Map.merge(%{variant: variant, title: title})
    LiveView.push_event(socket, "toast", compact(payload))
  end

  @doc """
  Changes the toast with `id` in place: any of `:variant`, `:title`, `:description`, `:duration` and `:action`
  (and `:group`, see `put_toast/4`). Changing the variant or the duration restarts its timer, so a `:loading`
  toast turned `:ok` closes after the group's duration.
  """
  @spec update_toast(Phoenix.LiveView.Socket.t(), String.t(), keyword() | map()) ::
          Phoenix.LiveView.Socket.t()
  def update_toast(socket, id, patch) do
    payload = patch |> Map.new() |> Map.put(:id, id)
    LiveView.push_event(socket, "toast:update", compact(payload))
  end

  @doc "Closes the toast with `id`. `opts`: `:group`, see `put_toast/4`."
  @spec dismiss_toast(Phoenix.LiveView.Socket.t(), String.t(), keyword()) ::
          Phoenix.LiveView.Socket.t()
  def dismiss_toast(socket, id, opts \\ []),
    do: LiveView.push_event(socket, "toast:dismiss", compact(Map.put(Map.new(opts), :id, id)))

  @doc "Closes every toast, `:loading` ones included. `opts`: `:group`, see `put_toast/4`."
  @spec clear_toasts(Phoenix.LiveView.Socket.t(), keyword()) :: Phoenix.LiveView.Socket.t()
  def clear_toasts(socket, opts \\ []),
    do: LiveView.push_event(socket, "toast:clear", compact(Map.new(opts)))

  defp compact(payload),
    do: payload |> Enum.reject(fn {_key, value} -> is_nil(value) end) |> Map.new()
end
