defmodule DevactionUI.TagTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.Tag

  for variant <- [:risk, :warn, :ok, :info, :neutral] do
    test "#{variant} takes its colors from its own tokens" do
      assigns = %{variant: unquote(variant)}

      html = rendered_to_string(~H|<Tag.tag variant={@variant} id="t">Em dia</Tag.tag>|)

      assert html =~ "border-tag-#{unquote(variant)}-line"
      assert html =~ "bg-tag-#{unquote(variant)}-bg"
      assert html =~ "text-tag-#{unquote(variant)}-text"
      assert html =~ "font-mono"
      assert html =~ "Em dia"
    end
  end

  test "defaults to neutral and passes extra attributes through" do
    assigns = %{}

    html = rendered_to_string(~H|<Tag.tag data-x="1">Planejado</Tag.tag>|)

    assert html =~ "text-tag-neutral-text"
    assert html =~ ~s(data-x="1")
  end

  test "case: :normal keeps the letters of a value that is code" do
    assigns = %{}

    html = rendered_to_string(~H|<Tag.tag case={:normal}>:risk</Tag.tag>|)

    assert html =~ "normal-case"
    refute html =~ "uppercase"
  end
end
