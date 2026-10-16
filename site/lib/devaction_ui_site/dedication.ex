defmodule DevactionUISite.Dedication do
  @moduledoc "The line at the foot of the site: a dedication with a soft glow that passes between the letters."
  use Phoenix.Component

  attr :class, :any, default: nil

  def dedication(assigns) do
    ~H"""
    <p class={["m-0", @class]}>
      <span class="site-aura">All honor and glory to the Lord Jesus.</span>
    </p>
    """
  end
end
