defmodule DevactionUI.FieldTest do
  @moduledoc "The field: label, required, optional, hint, errors, counter and the ids it hands to the input."
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.Field

  test "the label points at the input and the input gets the field's aria" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Field.field :let={field} id="name" label="Project name" required hint="Shown in the portal">
        <input id={field.id} {field.aria} />
      </Field.field>
      """)

    assert html =~ ~s(<label for="name">Project name</label>)
    assert html =~ ~s(aria-required="true")
    assert html =~ ~s(aria-describedby="name-hint")
    assert html =~ ~s(id="name-hint")
    refute html =~ "aria-invalid"
    assert html =~ ~s(aria-hidden="true" class="ml-0.5 text-tag-risk-text">*)
  end

  test "an error is announced, invalidates the input and joins the description" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Field.field :let={field} id="slug" label="Slug" hint="Lowercase" error={["Too short", "Taken"]}>
        <input id={field.id} {field.aria} />
        <:error_icon><svg data-icon /></:error_icon>
      </Field.field>
      """)

    assert html =~ ~s(aria-invalid="true")
    assert html =~ ~s(aria-describedby="slug-hint slug-error")
    assert html =~ ~s(id="slug-error" role="alert")
    assert html =~ "Too short"
    assert html =~ "Taken"
    assert html =~ "data-icon"
  end

  test "an empty error is no error" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Field.field :let={field} id="a" label="A" error={[]}>
        <input id={field.id} {field.aria} />
      </Field.field>
      """)

    refute html =~ "role=\"alert\""
    refute html =~ "aria-describedby"
  end

  test "the optional text shows only on a field that is not required" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Field.field :let={field} id="a" label="Notes" optional="optional">
        <input id={field.id} />
      </Field.field>
      """)

    assert html =~ "optional"
    refute html =~ "*"

    required =
      rendered_to_string(~H"""
      <Field.field :let={field} id="a" label="Notes" required optional="optional">
        <input id={field.id} />
      </Field.field>
      """)

    refute required =~ ">optional<"
  end

  test "the counter reads count / max and warms up near the limit" do
    assigns = %{}

    far =
      rendered_to_string(~H"""
      <Field.field :let={f} id="a" label="A" count={20} max={200}><input id={f.id} /></Field.field>
      """)

    near =
      rendered_to_string(~H"""
      <Field.field :let={f} id="a" label="A" count={182} max={200}><input id={f.id} /></Field.field>
      """)

    over =
      rendered_to_string(~H"""
      <Field.field :let={f} id="a" label="A" count={201} max={200}><input id={f.id} /></Field.field>
      """)

    bare =
      rendered_to_string(~H"""
      <Field.field :let={f} id="a" label="A" count={7}><input id={f.id} /></Field.field>
      """)

    assert far =~ "20 / 200"
    assert far =~ "text-muted"
    assert near =~ "182 / 200"
    assert near =~ "text-tag-warn-text"
    assert over =~ "text-tag-risk-text"
    assert bare =~ ~r/>\s*7\s*</
  end
end
