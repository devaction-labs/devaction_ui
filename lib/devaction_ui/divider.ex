defmodule DevactionUI.Divider do
  @moduledoc """
  A thin line, or a line with a short word in the middle (the "OR" between a social button and a form). The word is
  in mono capitals and is given by the caller. A divider with a word is a `separator` for assistive technology, and
  the word is read out.
  """
  use Phoenix.Component

  attr :label, :string, default: nil, doc: "the word in the middle"
  attr :class, :any, default: nil
  attr :rest, :global

  def divider(%{label: nil} = assigns) do
    ~H"""
    <hr class={["m-0 h-px border-0 bg-line", @class]} {@rest} />
    """
  end

  def divider(assigns) do
    ~H"""
    <div
      role="separator"
      class={[
        "flex items-center gap-3.5 font-mono text-[11px] tracking-[0.1em] text-muted-2 uppercase",
        @class
      ]}
      {@rest}
    >
      <span class="h-px flex-1 bg-line" aria-hidden="true"></span>{@label}<span
        class="h-px flex-1 bg-line"
        aria-hidden="true"
      ></span>
    </div>
    """
  end
end
