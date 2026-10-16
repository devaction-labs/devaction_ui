defmodule DevactionUI.InputGroup do
  @moduledoc """
  A text field with what the canvas puts around it: an icon at the start, an action at the end (show the
  password, clear, copy) and add-ons on either side (`R$`, `https://`, `.devaction.app`). The frame carries
  the focus ring, the error and the disabled look, so the field inside stays a plain `<input>`.

  The icon, the action and the add-ons are slots: the library knows no icon set. The error is whatever the
  caller says with `invalid`, and `loading` swaps the end for a spinner (and then `loading_label` is required).
  An add-on is boxed (a tinted block with a line) unless it says `loose` (plain muted text, as `.devaction.app`),
  and `mono` sets it in the monospace of an amount or a code.

  The field carries no error message of its own: render it under the group with an `id` and point the field at
  it with `aria-describedby`, which goes to the `<input>` through `rest`:

      <InputGroup.input_group id="slug" invalid aria-describedby="slug-error" />
      <p id="slug-error">Already taken</p>

  The look comes from the `.input-group*` classes of `devaction_ui.css`, which the app must import. The focus and
  error rings (8% of the ink in light, 10% in dark), the error fill and the disabled fill are the custom
  properties `--ring-field`, `--ring-field-error`, `--fill-field-error` and `--fill-field-off`, which an app can
  override on the group. A `readonly` field is drawn as the canvas draws a secret to copy: plain fill, monospace.
  """
  use Phoenix.Component

  import DevactionUI.Spinner

  attr :id, :string, required: true
  attr :name, :string, default: nil
  attr :value, :any, default: nil
  attr :type, :string, default: "text"
  attr :size, :atom, values: [:sm, :md, :lg], default: :md, doc: "36, 44 or 52 px high"
  attr :invalid, :boolean, default: false
  attr :loading, :boolean, default: false, doc: "swaps the action for a spinner"

  attr :loading_label, :string,
    default: nil,
    doc: "what is happening, read by screen readers; required when `loading`"

  attr :class, :any, default: nil

  attr :rest, :global,
    include:
      ~w(placeholder disabled readonly maxlength minlength inputmode autocomplete required min max step pattern form list)

  slot :icon, doc: "drawn before the text, muted"
  slot :action, doc: "a button at the end: show the password, clear, copy"

  slot :prefix, doc: "an add-on glued to the start: `R$`, `https://`" do
    attr :loose, :boolean
    attr :mono, :boolean
  end

  slot :suffix, doc: "an add-on glued to the end: `por marco`, `.devaction.app`" do
    attr :loose, :boolean
    attr :mono, :boolean
  end

  slot :hint, doc: "a small key cap or text inside the field, before the action"

  def input_group(%{loading: true, loading_label: nil}),
    do: raise(ArgumentError, "input_group/1 needs a loading_label while it is loading")

  def input_group(assigns) do
    ~H"""
    <span id={"#{@id}-group"} class={["input-group", size_class(@size), @class]}>
      <span :for={prefix <- @prefix} class={addon_class(prefix)}>{render_slot(prefix)}</span>
      <span :if={@icon != []} class="input-icon [&>*]:size-full">{render_slot(@icon)}</span>
      <input
        id={@id}
        name={@name}
        type={@type}
        value={@value}
        aria-invalid={@invalid && "true"}
        {@rest}
      />
      <span :if={@hint != []} class="shrink-0">{render_slot(@hint)}</span>
      <.spinner :if={@loading} label={@loading_label} class="size-[18px] shrink-0 border-2" />
      <span :if={!@loading and @action != []} class="contents">{render_slot(@action)}</span>
      <span :for={suffix <- @suffix} class={addon_class(suffix)}>{render_slot(suffix)}</span>
    </span>
    """
  end

  attr :label, :string, required: true, doc: "what pressing it does, read by screen readers"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true, doc: "the icon"

  @doc "The button at the end of an `input_group/1`: show the password, clear the field, copy the value."
  def input_action(assigns) do
    ~H"""
    <button type="button" aria-label={@label} class={["input-action", @class]} {@rest}>
      {render_slot(@inner_block)}
    </button>
    """
  end

  defp addon_class(slot) do
    [
      (slot[:loose] && "input-note") || "input-addon",
      slot[:mono] && "font-mono text-[13px]"
    ]
  end

  defp size_class(:sm), do: "input-sm"
  defp size_class(:md), do: nil
  defp size_class(:lg), do: "input-lg"
end
