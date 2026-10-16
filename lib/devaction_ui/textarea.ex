defmodule DevactionUI.Textarea do
  @moduledoc """
  A text area as the canvas draws it: it grows with its text (`field-sizing: content`, up to 12 lines), has an
  optional footer for actions (attach, mention, improve with the AI) and a counter that turns red near the
  limit. The label and the help text are the caller's; this is the field.

  `rows` is the least it shows, and `aria-invalid` sits on the `<textarea>` only: the frame reads it for the error
  ring. With a `maxlength` the counter is part of the field's description (`aria-describedby`, joined to one the
  caller gives) and is announced politely once it is near the limit.
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
  attr :rest, :global, include: ~w(placeholder disabled readonly required minlength form wrap)
  slot :footer, doc: "actions under the text, at the start; the counter sits at the end"

  def textarea(assigns) do
    assigns =
      assigns
      |> assign(:count, String.length(assigns.value || ""))
      |> assign(:describedby, describedby(assigns.rest[:"aria-describedby"], assigns))
      |> assign(:rest, Map.delete(assigns.rest, :"aria-describedby"))

    ~H"""
    <div id={"#{@id}-box"} class={["textarea", @class]}>
      <textarea
        id={@id}
        name={@name}
        rows={@rows}
        maxlength={@maxlength}
        aria-invalid={@invalid && "true"}
        aria-describedby={@describedby}
        style={"--rows: #{@rows}"}
        {@rest}
      >{@value}</textarea>
      <div :if={@footer != [] or @maxlength} class="textarea-footer">
        {render_slot(@footer)}
        <span
          :if={@maxlength}
          id={"#{@id}-count"}
          aria-live={(near_limit?(@count, @maxlength) && "polite") || "off"}
          data-over={to_string(near_limit?(@count, @maxlength))}
          class="textarea-count"
        >
          {@count}/{@maxlength}
        </span>
      </div>
    </div>
    """
  end

  defp describedby(given, %{maxlength: nil}), do: given
  defp describedby(nil, assigns), do: "#{assigns.id}-count"
  defp describedby(given, assigns), do: "#{given} #{assigns.id}-count"

  @doc "Whether `count` characters are within 10% of `max`."
  @spec near_limit?(non_neg_integer(), pos_integer()) :: boolean()
  def near_limit?(count, max), do: count >= max * @near

  attr :label, :string, required: true
  attr :variant, :atom, values: [:plain, :ai], default: :plain, doc: "`:ai` is what the AI offers"
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
        "inline-flex h-[34px] min-w-[34px] items-center justify-center gap-1.5 text-[13px] outline-none focus-visible:ring-4 focus-visible:ring-ink/10",
        footer_look(@variant),
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  defp footer_look(:plain), do: "rounded-lg px-2 text-ink-2 hover:bg-wrap"

  defp footer_look(:ai),
    do:
      "rounded-[9px] border border-tag-warn-line bg-tag-warn-bg px-2.5 font-medium text-tag-warn-text hover:bg-tag-warn-line/40"
end
