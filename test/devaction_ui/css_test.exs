defmodule DevactionUI.CssTest do
  use ExUnit.Case, async: true

  @css Path.expand("../../assets/css/devaction_ui.css", __DIR__)

  test "every brace of the stylesheet is closed" do
    css = File.read!(@css)
    count = fn char -> css |> String.graphemes() |> Enum.count(&(&1 == char)) end

    assert count.("{") == count.("}")
  end

  test "a disabled option does not dash the frame of the select" do
    css = File.read!(@css)

    assert css =~ "has-[:disabled:not(option,optgroup)]:border-dashed"

    refute css =~
             "has-disabled:border-dashed has-disabled:bg-(--fill-field-off) has-disabled:text-muted; }\n  .input-group"
  end
end
