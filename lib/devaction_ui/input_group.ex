defmodule DevactionUI.InputGroup do
  @moduledoc """
  A text field with what the canvas puts around it: an icon at the start, an action at the end (show the
  password, clear, copy) and add-ons on either side (`R$`, `https://`, `.devaction.app`). The frame carries
  the focus ring, the error and the disabled look, so the field inside stays a plain `<input>`.

  The icon, the action and the add-ons are slots: the library knows no icon set. The error is whatever the
  caller says with `invalid`, and `loading` swaps the end for a spinner (and then `loading_label` is required).
  An add-on is boxed (a tinted block with a line) unless it says `loose` (plain muted text, as `.devaction.app`),
  and `mono` sets it in the monospace of an amount or a code.

  With `field={@form[:title]}` the id, the name, the value and the error state come from the form (see
  `DevactionUI.FormField`); what is given by hand wins.

  The field carries no error message of its own: render it under the group with an `id` and point the field at
  it with `aria-describedby`, which goes to the `<input>` through `rest`:

      <InputGroup.input_group id="slug" invalid aria-describedby="slug-error" />
      <p id="slug-error">Already taken</p>

  The look comes from the `.input-group*` classes of `devaction_ui.css`, which the app must import. The focus and
  error rings (8% of the ink in light, 10% in dark), the error fill and the disabled fill are the custom
  properties `--ring-field`, `--ring-field-error`, `--fill-field-error` and `--fill-field-off`, which an app can
  override on the group. A `readonly` field is drawn as the canvas draws a secret to copy: plain fill, monospace.

  `floating_label` puts the label inside the frame, where the placeholder would be, and lifts it when the field
  has the focus or a value: onto the border (`floating={:border}`, the default) or to the top of a 56px field
  (`floating={:inside}`). It is a real `<label for>`, so it names the field; any `placeholder` is dropped, since
  the label stands in its place.

  `busy_label` is for a field that asks the server as you type (a search with `phx-change` or `phx-keyup`): a
  spinner takes the place of the action while LiveView is waiting for the answer, by the `phx-change-loading`
  and `phx-keyup-loading` classes it sets, with no assign to keep. `loading` is the same spinner held by the
  caller. `valid` draws the frame of a value that was checked and passed (an address that is free).
  """
  use Phoenix.Component

  import DevactionUI.Spinner

  alias DevactionUI.FormField

  attr :id, :string, default: nil, doc: "required unless a `field` gives it"

  attr :field, Phoenix.HTML.FormField,
    default: nil,
    doc: "a form field (`@form[:title]`): gives the `id`, the `name`, the value and the errors"

  attr :name, :string, default: nil
  attr :value, :any, default: nil
  attr :type, :string, default: "text"
  attr :size, :atom, values: [:sm, :md, :lg], default: :md, doc: "36, 44 or 52 px high"
  attr :invalid, :boolean, default: false
  attr :valid, :boolean, default: false, doc: "the frame of a value that was checked and passed"

  attr :floating_label, :string,
    default: nil,
    doc: "a label in the place of the placeholder that lifts on focus or with a value"

  attr :floating, :atom,
    values: [:border, :inside],
    default: :border,
    doc: "where the floating label goes: onto the border, or to the top of a 56px field"

  attr :busy_label, :string,
    default: nil,
    doc:
      "shows a spinner while LiveView waits for this field's `phx-change` or `phx-keyup`, read by screen readers"

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
    assigns =
      assigns
      |> FormField.put(value: :text)
      |> FormField.require!([:id], "input_group/1")

    assigns =
      assigns
      |> assign(:invalid, assigns.invalid or assigns.field_errors != [])
      |> assign(:rest, floating_rest(assigns.rest, assigns.floating_label))

    ~H"""
    <span
      id={"#{@id}-group"}
      class={[
        "input-group",
        size_class(@size),
        @floating_label && floating_class(@floating),
        @valid && "input-valid",
        @class
      ]}
    >
      <span :for={prefix <- @prefix} class={addon_class(prefix)}>{render_slot(prefix)}</span>
      <span :if={@icon != []} class="input-icon [&>*]:size-full">{render_slot(@icon)}</span>
      <span :if={@floating_label} class="input-float">
        <.control id={@id} name={@name} type={@type} value={@value} invalid={@invalid} rest={@rest} />
        <label for={@id} class="input-float-label">{@floating_label}</label>
      </span>
      <.control
        :if={!@floating_label}
        id={@id}
        name={@name}
        type={@type}
        value={@value}
        invalid={@invalid}
        rest={@rest}
      />
      <span :if={@hint != []} class="shrink-0">{render_slot(@hint)}</span>
      <.spinner :if={@loading} label={@loading_label} class="size-[18px] shrink-0 border-2" />
      <span :if={@busy_label && !@loading} class="input-busy">
        <.spinner label={@busy_label} class="size-[18px] border-2" />
      </span>
      <span :if={!@loading and @action != []} class="input-actions">{render_slot(@action)}</span>
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

  defp control(assigns) do
    ~H"""
    <input
      id={@id}
      name={@name}
      type={@type}
      value={@value}
      aria-invalid={@invalid && "true"}
      {@rest}
    />
    """
  end

  defp floating_rest(rest, nil), do: rest
  defp floating_rest(rest, _label), do: Map.put(rest, :placeholder, " ")

  defp floating_class(:border), do: "input-floating"
  defp floating_class(:inside), do: "input-floating input-floating-inside"

  defp size_class(:sm), do: "input-sm"
  defp size_class(:md), do: nil
  defp size_class(:lg), do: "input-lg"
end
