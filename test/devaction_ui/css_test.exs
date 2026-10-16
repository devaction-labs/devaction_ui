defmodule DevactionUI.CssTest do
  use ExUnit.Case, async: true

  @css Path.expand("../../assets/css/devaction_ui.css", __DIR__)

  test "every brace of the stylesheet is closed" do
    css = File.read!(@css)
    count = fn char -> css |> String.graphemes() |> Enum.count(&(&1 == char)) end

    assert count.("{") == count.("}")
  end
end
