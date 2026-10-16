defmodule DevactionUI.Field do
  @moduledoc """
  The label, the hint, the error and the counter around any input, wired to it for assistive technology. The
  input is whatever the caller puts in the slot: an `InputGroup`, a `Textarea`, a select, a plain `<input>`.

  The slot is `:let={field}` and `field` carries what to hand to the input: `field.id` (the label points at it),
  `field.invalid` and `field.required` (booleans) and `field.aria`, a map of `aria-describedby` (the hint and the
  error, when there are any), `aria-required` and `aria-invalid`, to splat on a plain input:

      <Field.field :let={field} id="slug" label="Slug" required error={@error}>
        <input id={field.id} name="slug" {field.aria} />
      </Field.field>

  A component that sets `aria-invalid` itself (`InputGroup`) takes `invalid={field.invalid}` and the other two
  by name: `aria-describedby={field.aria[:"aria-describedby"]}`.

  The label shows a red `*` when `required` (hidden from assistive technology, which hears `aria-required`) and
  the `optional` text, in the language of the app, when the field is not. The hint is a quiet line under the
  input; the error replaces nothing and is announced (`role="alert"`) with the icon of the `error_icon` slot in
  front. `count` and `max` draw the counter (`182 / 200`), amber from nine tenths of `max` and red past it.
  The library knows no language: every word is an attribute.
  """
  use Phoenix.Component

  attr :id, :string,
    required: true,
    doc: "the id of the input; the label, hint and error derive theirs"

  attr :label, :string, required: true, doc: "the text of the label"
  attr :required, :boolean, default: false, doc: "a red `*` after the label and `aria-required`"

  attr :optional, :string,
    default: nil,
    doc: "the muted word after the label of a field that is not required, such as `optional`"

  attr :hint, :string, default: nil, doc: "a quiet line under the input"

  attr :error, :any,
    default: nil,
    doc: "a message, or a list of them (a changeset's `errors_on`); empty means no error"

  attr :count, :integer, default: nil, doc: "the length so far, for the counter"
  attr :max, :integer, default: nil, doc: "the limit, shown after the count"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true, doc: "the input, with `:let={field}`"
  slot :error_icon, doc: "the icon in front of each error message"

  @doc "A labelled input with its hint, its error and its counter."
  @spec field(map()) :: Phoenix.LiveView.Rendered.t()
  def field(assigns) do
    errors = errors(assigns.error)
    describedby = describedby(assigns.id, assigns.hint, errors)

    assigns =
      assign(assigns,
        errors: errors,
        describedby: describedby,
        field: field_map(assigns, describedby, errors != [])
      )

    ~H"""
    <div class={["flex flex-col gap-1.5", @class]} {@rest}>
      <div class="flex items-baseline text-sm font-medium text-ink">
        <label for={@id}>{@label}</label>
        <span :if={@required} aria-hidden="true" class="ml-0.5 text-tag-risk-text">*</span>
        <span :if={@optional && !@required} class="ml-1.5 font-normal text-muted">{@optional}</span>
        <span
          :if={@count}
          data-counter
          class={["ml-auto font-mono text-xs", counter_class(@count, @max)]}
        >
          {counter(@count, @max)}
        </span>
      </div>
      {render_slot(@inner_block, @field)}
      <p :if={@hint} id={"#{@id}-hint"} class="m-0 text-[13px] text-muted">{@hint}</p>
      <div :if={@errors != []} id={"#{@id}-error"} role="alert" class="flex flex-col gap-1">
        <p
          :for={message <- @errors}
          class="m-0 flex items-center gap-1.5 text-[13px] text-tag-risk-text"
        >
          <span :if={@error_icon != []} aria-hidden="true" class="size-3.5 shrink-0 [&>*]:size-full">
            {render_slot(@error_icon)}
          </span>
          {message}
        </p>
      </div>
    </div>
    """
  end

  defp field_map(assigns, describedby, invalid) do
    %{
      id: assigns.id,
      invalid: invalid,
      required: assigns.required,
      aria: %{
        "aria-describedby": describedby,
        "aria-required": assigns.required && "true",
        "aria-invalid": invalid && "true"
      }
    }
  end

  defp errors(error), do: error |> List.wrap() |> Enum.reject(&(&1 in [nil, ""]))

  defp describedby(id, hint, errors) do
    [hint && "#{id}-hint", errors != [] && "#{id}-error"]
    |> Enum.filter(&is_binary/1)
    |> join()
  end

  defp join([]), do: nil
  defp join(ids), do: Enum.join(ids, " ")

  defp counter(count, nil), do: to_string(count)
  defp counter(count, max), do: "#{count} / #{max}"

  defp counter_class(_count, nil), do: "text-muted"
  defp counter_class(count, max) when count > max, do: "text-tag-risk-text"
  defp counter_class(count, max) when count * 10 >= max * 9, do: "text-tag-warn-text"
  defp counter_class(_count, _max), do: "text-muted"
end
