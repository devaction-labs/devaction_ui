defmodule DevactionUI.FormFieldTest do
  @moduledoc "The fields take a `Phoenix.HTML.FormField`, as the core components do, and the plain select."
  use ExUnit.Case, async: false

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.{
    Choice,
    Combobox,
    DatePicker,
    Field,
    FormField,
    InputGroup,
    Select,
    Switch,
    Textarea
  }

  defp form(params, errors \\ []), do: to_form(params, as: :post, errors: errors)

  describe "FormField" do
    test "shows errors only once the input was used, with the placeholders filled" do
      used = form(%{"title" => ""}, title: {"should be at least %{count} characters", [count: 3]})
      untouched = form(%{}, title: {"can't be blank", []})

      assert FormField.errors(used[:title]) == ["should be at least 3 characters"]
      assert FormField.errors(untouched[:title]) == []
      assert FormField.errors(nil) == []
    end

    test "translates through the function the app sets" do
      Application.put_env(:devaction_ui, :translate_error, fn {msg, _} -> "pt: " <> msg end)
      on_exit(fn -> Application.delete_env(:devaction_ui, :translate_error) end)

      assert FormField.translate({"can't be blank", []}) == "pt: can't be blank"
    end

    test "a value becomes the text of an input" do
      assert FormField.text(~D[2026-10-16]) == "2026-10-16"
      assert FormField.text(42) == "42"
      assert FormField.text(:open) == "open"
      assert FormField.text(nil) == nil
    end
  end

  describe "InputGroup and Textarea" do
    test "take the id, the name, the value and the error state from the field" do
      assigns = %{f: form(%{"title" => "Relatórios"}, title: {"too short", []})}

      html =
        rendered_to_string(~H"""
        <InputGroup.input_group field={@f[:title]} />
        <Textarea.textarea field={@f[:title]} />
        """)

      assert html =~ ~s(<input id="post_title" name="post[title]" type="text" value="Relatórios")
      assert html =~ ~r/<textarea id="post_title" name="post\[title\]"[^>]*aria-invalid="true"/
      assert html =~ ">Relatórios</textarea>"
      assert html =~ ~r/<input id="post_title"[^>]*aria-invalid="true"/
    end

    test "what the caller gives wins over the field, and an untouched field is not invalid" do
      assigns = %{f: form(%{}, title: {"can't be blank", []})}

      html =
        rendered_to_string(~H"""
        <InputGroup.input_group field={@f[:title]} id="custom" value="typed" />
        """)

      assert html =~ ~s(<input id="custom" name="post[title]" type="text" value="typed")
      refute html =~ "aria-invalid"
    end

    test "with neither an id nor a field it says what is missing" do
      assigns = %{}

      assert_raise ArgumentError, ~r/input_group\/1 needs `id`/, fn ->
        rendered_to_string(~H"<InputGroup.input_group />")
      end
    end
  end

  describe "Field" do
    test "labels the field's input and shows the changeset's error after use" do
      assigns = %{f: form(%{"slug" => "SGE API"}, slug: {"has invalid format", []})}

      html =
        rendered_to_string(~H"""
        <Field.field :let={f} field={@f[:slug]} label="Slug">
          <InputGroup.input_group field={@f[:slug]} aria-describedby={f.aria[:"aria-describedby"]} />
        </Field.field>
        """)

      assert html =~ ~s(<label for="post_slug">Slug</label>)
      assert html =~ ~s(id="post_slug-error")
      assert html =~ "has invalid format"
      assert html =~ ~s(aria-describedby="post_slug-error")
    end

    test "an error given by hand wins over the field's" do
      assigns = %{f: form(%{"slug" => "x"}, slug: {"from the changeset", []})}

      html =
        rendered_to_string(~H"""
        <Field.field field={@f[:slug]} label="Slug" error="by hand"><input /></Field.field>
        """)

      assert html =~ "by hand"
      refute html =~ "from the changeset"
    end
  end

  describe "Choice and Switch" do
    test "a boolean checkbox sends false when not ticked and is ticked by the field" do
      assigns = %{f: form(%{"public" => "true"})}

      html =
        rendered_to_string(~H"""
        <Choice.checkbox field={@f[:public]} label="Public" />
        """)

      assert html =~ ~s(<input type="hidden" name="post[public]" value="false")

      assert html =~
               ~r/<input type="checkbox" id="post_public" name="post\[public\]" value="true" checked/
    end

    test "a box of a list field is named with [] and ticked when the list holds its value" do
      assigns = %{f: form(%{"tags" => ["elixir"]})}

      html =
        rendered_to_string(~H"""
        <Choice.checkbox_group field={@f[:tags]} legend="Tags">
          <Choice.checkbox field={@f[:tags]} multiple value="elixir" label="Elixir" />
          <Choice.checkbox field={@f[:tags]} multiple value="php" label="PHP" />
        </Choice.checkbox_group>
        """)

      assert html =~ ~s(<fieldset id="post_tags")
      assert html =~ ~s(<input type="hidden" name="post[tags][]" value="")
      assert html =~ ~r/id="post_tags-elixir" name="post\[tags\]\[\]" value="elixir" checked/
      refute html =~ ~r/id="post_tags-php"[^>]*checked/
    end

    test "radios share the field's name and the one with its value is checked; the group shows the error" do
      assigns = %{f: form(%{"model" => "hours"}, model: {"pick one", []})}

      html =
        rendered_to_string(~H"""
        <Choice.radio_group field={@f[:model]} legend="Model">
          <Choice.radio field={@f[:model]} value="fixed" label="Fixed scope" />
          <Choice.radio field={@f[:model]} value="hours" label="Hours bank" />
        </Choice.radio_group>
        """)

      assert html =~ ~r/id="post_model-hours" name="post\[model\]" value="hours" checked/
      refute html =~ ~r/id="post_model-fixed"[^>]*checked/
      assert html =~ "pick one"
    end

    test "a switch with a field is in the field mode" do
      assigns = %{f: form(%{"notify" => "true"})}

      html =
        rendered_to_string(~H"""
        <Switch.switch field={@f[:notify]} label="Notify" />
        """)

      assert html =~ ~s(id="post_notify")
      assert html =~ ~s(aria-checked="true")

      assert html =~
               ~s(<input type="hidden" id="post_notify-field" name="post[notify]" value="true")
    end
  end

  describe "Combobox and DatePicker" do
    test "the combobox takes the field's name, value and error" do
      assigns = %{f: form(%{"project_id" => "2"}, project_id: {"is invalid", []})}

      html =
        rendered_to_string(~H"""
        <Combobox.combobox
          field={@f[:project_id]}
          label="Project"
          placeholder="Choose"
          search_placeholder="Search"
          empty="None"
          options={[%{value: 1, label: "SGE"}, %{value: 2, label: "Hub"}]}
        />
        """)

      assert html =~ ~s(id="post_project_id")
      assert html =~ ~s(name="post[project_id]")
      assert html =~ "Hub"
      assert html =~ "is invalid"
    end

    test "the date input takes a Date from the field" do
      assigns = %{f: form(%{"due_on" => ~D[2026-10-16]})}

      html =
        rendered_to_string(~H"""
        <DatePicker.date_input
          field={@f[:due_on]}
          label="Due"
          today="2026-10-16"
          calendar_label="Calendar"
          previous_label="Previous"
          next_label="Next"
        />
        """)

      assert html =~ ~s(name="post[due_on]")
      assert html =~ ~s(value="2026-10-16")
      assert html =~ "16/10/2026"
    end
  end

  describe "Select" do
    test "draws the options, the prompt and the choice in the input group frame" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select
          id="status"
          name="status"
          prompt="Choose a status"
          value="open"
          options={[{"Open", "open"}, {"Done", "done"}]}
        />
        """)

      assert html =~ ~s(class="input-group select)
      assert html =~ ~s(<option value="">Choose a status</option>)
      assert html =~ ~s(<option selected value="open">Open</option>)
      assert html =~ ~s(<option value="done">Done</option>)
      assert html =~ "select-chevron"
    end

    test "takes maps with disabled options and groups" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select
          id="role"
          options={[
            {"Team", [%{value: "dev", label: "Dev"}, %{value: "pm", label: "PM", disabled: true}]}
          ]}
        />
        """)

      assert html =~ ~s(<optgroup label="Team">)
      assert html =~ ~s(<option disabled value="pm">PM</option>)
    end

    test "with a field and multiple, the name ends in [] and the list is chosen" do
      assigns = %{f: form(%{"roles" => ["dev", "pm"]}, roles: {"too many", []})}

      html =
        rendered_to_string(~H"""
        <Select.select field={@f[:roles]} multiple options={[{"Dev", "dev"}, {"PM", "pm"}, {"QA", "qa"}]} />
        """)

      assert html =~ ~r/<select id="post_roles" name="post\[roles\]\[\]" multiple/
      assert html =~ ~s(aria-invalid="true")
      assert html =~ ~s(<option selected value="dev">)
      assert html =~ ~s(<option selected value="pm">)
      refute html =~ "select-chevron"
    end
  end
end
