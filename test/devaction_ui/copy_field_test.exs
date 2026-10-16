defmodule DevactionUI.CopyFieldTest do
  @moduledoc "The copy field: the value, the mask, the eye, the hook and the copy button."
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.CopyField

  test "the value is read-only, labelled, and carried for the clipboard hook" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <CopyField.field
        id="secret"
        label="Webhook secret"
        value="whsec_9f3c1e7a2b8d4f60c5e1"
        copy_label="Copy"
        copied_label="Copied"
        hint="Shown once"
      />
      """)

    assert html =~ ~s(phx-hook="DevactionUI.CopyField")
    assert html =~ ~s(data-copy-value="whsec_9f3c1e7a2b8d4f60c5e1")
    assert html =~ ~s(<label for="secret-value")
    assert html =~ ~s(id="secret-value")
    assert html =~ "readonly"
    assert html =~ ~s(value="whsec_9f3c1e7a2b8d4f60c5e1")
    assert html =~ ~s(aria-describedby="secret-hint")
    assert html =~ "Shown once"
    assert html =~ "data-code-copy"
    assert html =~ ~s(data-copied-label="Copied")
    assert html =~ "data-code-status"
    refute html =~ "aria-label"
  end

  test "with an eye event the value is masked until revealed, keeping the ends" do
    assigns = %{}

    masked =
      rendered_to_string(~H"""
      <CopyField.field
        id="s"
        label="L"
        value="whsec_9f3c1e7a2b8d4f60c5e1"
        copy_label="Copy"
        copied_label="Copied"
        revealed={false}
        on_toggle="toggle"
        show_label="Show"
        hide_label="Hide"
        mask_prefix={6}
      />
      """)

    assert masked =~ ~s(value="whsec_••••••••••••••••c5e1")
    assert masked =~ ~s(aria-label="Show")
    assert masked =~ ~s(phx-click="toggle")
    assert masked =~ ~s(data-copy-value="whsec_9f3c1e7a2b8d4f60c5e1")

    shown =
      rendered_to_string(~H"""
      <CopyField.field
        id="s"
        label="L"
        value="whsec_9f3c1e7a2b8d4f60c5e1"
        copy_label="Copy"
        copied_label="Copied"
        revealed
        on_toggle="toggle"
        show_label="Show"
        hide_label="Hide"
        target="#card"
      />
      """)

    assert shown =~ ~s(value="whsec_9f3c1e7a2b8d4f60c5e1")
    assert shown =~ ~s(aria-label="Hide")
    assert shown =~ ~s(phx-target="#card")
  end

  test "without an eye event nothing is masked and there is no eye" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <CopyField.field
        id="s"
        label="L"
        value="abcdef123456"
        copy_label="Copy"
        copied_label="Copied"
        revealed={false}
      />
      """)

    assert html =~ ~s(value="abcdef123456")
    refute html =~ "phx-click"
  end

  test "an eye without its labels is a mistake" do
    assigns = %{}

    assert_raise ArgumentError, ~r/show_label/, fn ->
      rendered_to_string(~H"""
      <CopyField.field
        id="s"
        label="L"
        value="v"
        copy_label="Copy"
        copied_label="Copied"
        on_toggle="t"
      />
      """)
    end
  end

  test "the icons are slots, one for each state" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <CopyField.field id="s" label="L" value="v" copy_label="Copy" copied_label="Copied">
        <:copy_icon><svg data-icon="copy" /></:copy_icon>
        <:copied_icon><svg data-icon="tick" /></:copied_icon>
      </CopyField.field>
      """)

    assert html =~ ~s(data-icon="copy")
    assert html =~ ~s(data-icon="tick")
    assert html =~ "group-data-[copied]:hidden"
  end
end
