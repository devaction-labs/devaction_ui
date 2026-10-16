defmodule DevactionUI.CopyField do
  @moduledoc """
  A read-only value in monospace with a Copy button, for what a person must take elsewhere: a webhook secret,
  an API key, an invite link, a repository URL. An eye button shows or hides the value (masked with bullets,
  the first and last characters kept so the person can tell which one it is), and the Copy button says
  `copied_label` for a moment after it writes to the clipboard.

  The server owns what is shown: `revealed` and the `on_toggle` event (a string or a `%JS{}`, sent to `target`
  when there is one) flip it. The clipboard needs the browser, so the `DevactionUI.CopyField` hook (the same
  one as the code block's copy button, which needs an `id`) writes the `data-copy-value` of the field. The
  full value is therefore in the page even while it is masked: mask what a person is not allowed to see by
  not sending it, not by `revealed`. The button stays hidden where the browser cannot write to the clipboard
  (it needs https); the value is still selectable.

  The icons are slots and every word is an attribute: the library knows no icon set and no language.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  attr :id, :string, required: true, doc: "the field's id; the input is `<id>-value`"
  attr :label, :string, required: true, doc: "the text of the label above the value"
  attr :value, :string, required: true, doc: "the full value, the one that is copied"
  attr :copy_label, :string, required: true, doc: "the text of the Copy button"
  attr :copied_label, :string, required: true, doc: "said for a moment after the copy"
  attr :hint, :string, default: nil, doc: "a quiet line under the field"
  attr :revealed, :boolean, default: true, doc: "shows the whole value instead of the masked one"

  attr :on_toggle, :any,
    default: nil,
    doc:
      "the event (a string or a `%JS{}`) of the eye button; without it there is no eye and no mask"

  attr :show_label, :string,
    default: nil,
    doc: "what the eye says while masked; needed with `on_toggle`"

  attr :hide_label, :string,
    default: nil,
    doc: "what the eye says while shown; needed with `on_toggle`"

  attr :target, :any, default: nil, doc: "the LiveComponent (`@myself`) that receives `on_toggle`"

  attr :mask_prefix, :integer,
    default: 0,
    doc: "how many characters at the start stay visible while masked (`whsec_` is 6)"

  attr :mask_suffix, :integer,
    default: 4,
    doc: "how many characters at the end stay visible while masked"

  attr :class, :any, default: nil
  attr :rest, :global
  slot :copy_icon, doc: "the icon before the Copy text"
  slot :copied_icon, doc: "the icon before the copied text"
  slot :show_icon, doc: "the eye that shows the value"
  slot :hide_icon, doc: "the crossed eye that hides it"

  @doc "A read-only monospace value with a show/hide eye and a Copy button."
  @spec field(map()) :: Phoenix.LiveView.Rendered.t()
  def field(%{on_toggle: toggle, show_label: nil}) when not is_nil(toggle),
    do: raise(ArgumentError, "copy_field: `on_toggle` needs `show_label` and `hide_label`")

  def field(%{on_toggle: toggle, hide_label: nil}) when not is_nil(toggle),
    do: raise(ArgumentError, "copy_field: `on_toggle` needs `show_label` and `hide_label`")

  def field(assigns) do
    assigns = assign(assigns, :shown, shown(assigns))

    ~H"""
    <div
      id={@id}
      phx-hook="DevactionUI.CopyField"
      data-copy-value={@value}
      class={["flex flex-col gap-1.5", @class]}
      {@rest}
    >
      <label for={"#{@id}-value"} class="text-sm font-medium text-ink">{@label}</label>
      <div class="flex h-10 overflow-hidden rounded-[10px] border border-line focus-within:ring-4 focus-within:ring-ink/10">
        <input
          id={"#{@id}-value"}
          type="text"
          readonly
          value={@shown}
          aria-describedby={@hint && "#{@id}-hint"}
          class="min-w-0 flex-1 truncate bg-(--copy-field-fill) px-3 font-mono text-[13px] text-ink-2 outline-none"
        />
        <button
          :if={@on_toggle}
          type="button"
          aria-label={(@revealed && @hide_label) || @show_label}
          phx-click={@on_toggle}
          phx-target={@target}
          class="grid w-10 shrink-0 place-items-center border-l border-line bg-card text-ink-2 outline-none hover:bg-wrap focus-visible:ring-2 focus-visible:ring-ink/20 focus-visible:ring-inset"
        >
          <span aria-hidden="true" class="size-4 [&>*]:size-full">
            {(@revealed && render_slot(@hide_icon)) || render_slot(@show_icon)}
          </span>
        </button>
        <button
          type="button"
          hidden
          data-code-copy
          data-copied-label={@copied_label}
          phx-mounted={JS.ignore_attributes(["hidden", "data-copied"])}
          class="group flex shrink-0 items-center gap-1.5 border-l border-line bg-card px-3 text-[13px] font-medium text-ink outline-none hover:bg-wrap focus-visible:ring-2 focus-visible:ring-ink/20 focus-visible:ring-inset data-[copied]:bg-tag-ok-bg data-[copied]:text-tag-ok-text"
        >
          <span aria-hidden="true" class="size-3.5 group-data-[copied]:hidden [&>*]:size-full">
            {render_slot(@copy_icon)}
          </span>
          <span
            aria-hidden="true"
            class="hidden size-3.5 group-data-[copied]:block [&>*]:size-full"
          >
            {render_slot(@copied_icon)}
          </span>
          <span class="group-data-[copied]:hidden">{@copy_label}</span>
          <span class="hidden group-data-[copied]:inline" aria-hidden="true">{@copied_label}</span>
        </button>
      </div>
      <span data-code-status role="status" class="sr-only"></span>
      <p :if={@hint} id={"#{@id}-hint"} class="m-0 text-xs text-muted">{@hint}</p>
    </div>
    """
  end

  defp shown(%{revealed: true, value: value}), do: value
  defp shown(%{on_toggle: nil, value: value}), do: value
  defp shown(%{value: value} = assigns), do: mask(value, assigns.mask_prefix, assigns.mask_suffix)

  defp mask(value, prefix, suffix) do
    hidden = max(String.length(value) - prefix - suffix, 0)

    String.slice(value, 0, prefix) <>
      String.duplicate("•", hidden) <> String.slice(value, String.length(value) - suffix, suffix)
  end
end
