defmodule DevactionUI.Spinner do
  @moduledoc "A spinning ring for work in progress. The label is read by screen readers and never drawn."
  use Phoenix.Component

  attr :label, :string, required: true, doc: "what is happening, for assistive technology"
  attr :class, :any, default: nil
  attr :rest, :global

  def spinner(assigns) do
    ~H"""
    <span
      role="status"
      class={[
        "inline-block size-[22px] animate-spin rounded-full border-[3px] border-line border-t-ink motion-reduce:animate-none",
        @class
      ]}
      {@rest}
    >
      <span class="sr-only">{@label}</span>
    </span>
    """
  end
end
