defmodule DevactionUI.SelectTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.Select

  @options [
    {"Team", [%{value: "dev", label: "Developer"}]},
    {"Client", [%{value: "ro", label: "Read only", disabled: true}]}
  ]

  defp render_select(assigns) do
    rendered_to_string(~H"""
    <Select.select
      id="role"
      name="role"
      value="dev"
      options={@options}
      size={@size}
      multiple={@multiple}
    />
    """)
  end

  defp render_select(size, multiple),
    do: render_select(%{options: @options, size: size, multiple: multiple})

  test "the select carries the hook of the styled panel and its size" do
    html = render_select(:lg, false)

    assert html =~ ~s(phx-hook="DevactionUI.Select")
    assert html =~ ~s(data-size="lg")
    assert html =~ ~s(<optgroup label="Team">)
    assert html =~ "disabled"
  end

  test "the native list box of multiple has no hook" do
    refute render_select(:md, true) =~ "phx-hook"
  end

  test "the stylesheet draws the panel with the artboard measures and respects reduced motion" do
    css = File.read!(Path.expand("../../assets/css/devaction_ui.css", __DIR__))

    assert css =~ ".select-panel {"
    assert css =~ "h-[34px]"
    assert css =~ ".select[data-open]"
    assert css =~ ~r/prefers-reduced-motion: reduce\) \{ \.select-panel \{ animation: none/
  end

  test "the hook is registered by the name the component gives" do
    index = File.read!(Path.expand("../../assets/js/devaction_ui/index.js", __DIR__))

    assert index =~ ~s("DevactionUI.Select": Select)
  end
end
