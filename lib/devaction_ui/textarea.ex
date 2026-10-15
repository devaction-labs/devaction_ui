defmodule DevactionUI.Textarea do
  @moduledoc """
  A text area as the canvas draws it: it grows with its text (`field-sizing: content`, up to 12 lines), has an
  optional footer for actions (attach, mention, improve with the AI) and a counter that turns red near the
  limit. The label and the help text are the caller's; this is the field.
  """
  use Phoenix.Component

  @near 0.9

  attr :id, :string, required: true
  attr :name, :string, default: nil
  attr :value, :string, default: nil
  attr :rows, :integer, default: 3

  attr :maxlength, :integer,
    default: nil,
    doc: "shows the counter and turns it red near the limit"

  attr :invalid, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(placeholder disabled readonly required)
  slot :footer, doc: "actions under the text, at the start; the counter sits at the end"

  def textarea(assigns) do
    assigns = assign(assigns, :count, String.length(assigns.value || ""))

    ~H"""
    <div
      id={"#{@id}-box"}
      aria-invalid={@invalid && "true"}
      class={[
        "textarea",
        @invalid && "border-missing",
        @rest[:disabled] && "border-dashed bg-wrap text-muted",
        @class
      ]}
    >
      <textarea
        id={@id}
        name={@name}
        rows={@rows}
        maxlength={@maxlength}
        aria-invalid={@invalid && "true"}
        {@rest}
      >{@value}</textarea>
      <div :if={@footer != [] or @maxlength} class="textarea-footer">
        {render_slot(@footer)}
        <span
          :if={@maxlength}
          id={"#{@id}-count"}
          data-over={to_string(near_limit?(@count, @maxlength))}
          class="textarea-count"
        >
          {@count}/{@maxlength}
        </span>
      </div>
    </div>
    """
  end

  @doc "Whether `count` characters are within 10% of `max`."
  @spec near_limit?(non_neg_integer(), pos_integer()) :: boolean()
  def near_limit?(count, max), do: count >= max * @near

  attr :label, :string, required: true
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc "A small button of the footer of a `textarea/1`, with an icon and an optional text."
  def footer_button(assigns) do
    ~H"""
    <button
      type="button"
      aria-label={@label}
      class={[
        "inline-flex h-8 items-center gap-1.5 rounded-lg px-2 text-[13px] text-ink-2 hover:bg-wrap",
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end
end
