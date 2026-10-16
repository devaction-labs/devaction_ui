defmodule DevactionUI.DescriptionListTest do
  @moduledoc "The description list: a real dl with a dt and a dd per row, links, tones and layouts."
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.DescriptionList

  test "each item is a term and a value inside a dl" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <DescriptionList.list>
        <:item label="Client">Baptist Church</:item>
        <:item label="Model">Milestones</:item>
      </DescriptionList.list>
      """)

    assert html =~ "<dl"
    assert length(Regex.scan(~r/<dt /, html)) == 2
    assert length(Regex.scan(~r/<dd /, html)) == 2
    assert html =~ "Client"
    assert html =~ "Baptist Church"
    assert html =~ "border-b border-line-soft"
    assert html =~ "--term-width: 120px"
  end

  test "an item with href is a link, with a tone it is colored, with mono it is monospace" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <DescriptionList.list term_width="8rem">
        <:item label="Repo" href="/repos/sge" mono>sge-api</:item>
        <:item label="Status" tone={:ok}>Active</:item>
      </DescriptionList.list>
      """)

    assert html =~ ~s(<a href="/repos/sge")
    assert html =~ "font-mono"
    assert html =~ "text-tag-ok-text"
    assert html =~ "--term-width: 8rem"
  end

  test "stacked puts the term over the value and divided can be turned off" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <DescriptionList.list layout={:stacked} divided={false} class="w-64">
        <:item label="Owner">Fernando</:item>
      </DescriptionList.list>
      """)

    assert html =~ "flex flex-col"
    refute html =~ "border-b"
    refute html =~ "--term-width"
    assert html =~ "w-64"
  end
end
