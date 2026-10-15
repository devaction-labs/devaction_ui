defmodule DevactionUISite.ErrorHTML do
  @moduledoc "Plain status pages for the showcase."

  def render(template, _assigns), do: Phoenix.Controller.status_message_from_template(template)
end
