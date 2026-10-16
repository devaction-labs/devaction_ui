defmodule DevactionUI.Separator do
  @moduledoc """
  A hairline that separates, in three forms: the plain line (`separator/1`), the line with a short text in the
  middle, such as the one between a social sign-in and a form (`separator/1` with `label`), and an inline row of
  small facts divided by vertical bars (`inline/1`). Any of them can stand upright with `orientation: :vertical`.

  A plain line is a `separator` for assistive technology. The text of a labelled one is its accessible name, so
  it is read once; the lines on each side are decoration. The bars of `inline/1` are decoration too: the facts
  stay one after the other. Pass `decorative` when the line only adorns and no reader needs to know it is there.

  The library knows no language: the text is the caller's.
  """
  use Phoenix.Component

  attr :orientation, :atom, values: [:horizontal, :vertical], default: :horizontal

  attr :label, :string,
    default: nil,
    doc: "the text in the middle of a horizontal line, such as `or continue with`"

  attr :decorative, :boolean,
    default: false,
    doc: "hidden from assistive technology, for a line that only adorns"

  attr :class, :any, default: nil
  attr :rest, :global

  @doc "A hairline, plain or with a text in the middle, horizontal or vertical."
  @spec separator(map()) :: Phoenix.LiveView.Rendered.t()
  def separator(%{label: label, orientation: :horizontal} = assigns) when is_binary(label) do
    ~H"""
    <div
      role={role(@decorative)}
      aria-label={!@decorative && @label}
      class={["flex items-center gap-2.5 text-[13px] text-muted", @class]}
      {@rest}
    >
      <span class="h-px flex-1 bg-line" aria-hidden="true"></span>
      <span aria-hidden="true">{@label}</span>
      <span class="h-px flex-1 bg-line" aria-hidden="true"></span>
    </div>
    """
  end

  def separator(assigns) do
    ~H"""
    <div
      role={role(@decorative)}
      aria-orientation={!@decorative && @orientation == :vertical && "vertical"}
      class={[line_class(@orientation), @class]}
      {@rest}
    >
    </div>
    """
  end

  attr :class, :any, default: nil
  attr :rest, :global
  slot :item, required: true, doc: "one fact; a bar is drawn between two items"

  @doc "A row of small facts divided by vertical bars."
  @spec inline(map()) :: Phoenix.LiveView.Rendered.t()
  def inline(assigns) do
    ~H"""
    <div class={["flex flex-wrap items-center gap-2.5 text-[13px] text-ink-2", @class]} {@rest}>
      <%= for {item, index} <- Enum.with_index(@item) do %>
        <span :if={index > 0} aria-hidden="true" class="h-3.5 w-px bg-done-cell"></span>
        <span>{render_slot(item)}</span>
      <% end %>
    </div>
    """
  end

  defp role(true), do: "none"
  defp role(false), do: "separator"

  defp line_class(:horizontal), do: "h-px w-full bg-line"
  defp line_class(:vertical), do: "w-px self-stretch bg-line"
end
