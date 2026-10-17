defmodule DevactionUI.ListboxTest do
  @moduledoc "The listbox: groups, descriptions, search, several choices, create and the form field."
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.Listbox

  @options [
    {"Work",
     [
       %{value: "dev", label: "Development", description: "Code and deploy", keywords: ~w(code)},
       %{value: "ops", label: "Infrastructure"}
     ]},
    %{value: "fin", label: "Finance", disabled: true}
  ]

  test "groups the options, marks the chosen one and puts it on the button" do
    assigns = %{options: @options}

    html =
      rendered_to_string(~H"""
      <Listbox.listbox
        id="cat"
        name="category"
        label="Category"
        placeholder="Choose"
        value="ops"
        options={@options}
      />
      """)

    assert html =~ ~s(phx-hook="DevactionUI.Listbox")
    assert html =~ ~s(role="group")
    assert html =~ "Work"
    assert html =~ ~s(<input type="hidden" name="category" value="ops")
    assert html =~ ~s(id="cat-option-1" role="option" data-value="ops")
    assert html =~ ~s(data-keywords="code")
    assert html =~ "Code and deploy"
    assert html =~ ~s(aria-disabled="true")
    assert html =~ ~r/data-current[^>]*>\s*Infrastructure\s*</
    refute html =~ "data-search"
    assert html =~ ~s(tabindex="-1")
  end

  test "shows the placeholder, muted, when nothing is chosen" do
    assigns = %{options: @options}

    html =
      rendered_to_string(~H"""
      <Listbox.listbox
        id="cat"
        name="category"
        label="Category"
        placeholder="Choose"
        options={@options}
      />
      """)

    assert html =~ ~r/data-current[^>]*text-muted-2[^>]*>\s*Choose\s*</
    assert html =~ ~s(<input type="hidden" name="category" value="")
  end

  test "a multiple listbox sends a list, counts and marks with boxes" do
    assigns = %{options: @options}

    html =
      rendered_to_string(~H"""
      <Listbox.listbox
        id="who"
        name="who"
        label="Who"
        placeholder="Nobody"
        multiple
        indicator={:checkbox}
        count_text="%{count} chosen"
        value={["dev", "ops"]}
        options={@options}
      />
      """)

    assert html =~ ~s(data-multiple="true")
    assert html =~ ~s(aria-multiselectable="true")
    assert html =~ ~s(<input type="hidden" name="who[]" value="" data-sentinel)
    assert html =~ ~s(name="who[]" value="dev")
    assert html =~ ~s(name="who[]" value="ops")
    assert html =~ ~r/data-current[^>]*>\s*2 chosen\s*</
    assert html =~ "listbox-box"
    refute html =~ "listbox-check"
  end

  test "without a count text the labels are joined" do
    assigns = %{options: @options}

    html =
      rendered_to_string(~H"""
      <Listbox.listbox
        id="who"
        name="who"
        label="Who"
        placeholder="Nobody"
        multiple
        value={["dev", "ops"]}
        options={@options}
      />
      """)

    assert html =~ ~r/data-current[^>]*>\s*Development, Infrastructure\s*</
  end

  test "the search, the empty text and the create row" do
    assigns = %{options: @options}

    html =
      rendered_to_string(~H"""
      <Listbox.listbox
        id="cat"
        name="category"
        label="Category"
        placeholder="Choose"
        searchable
        search_placeholder="Search"
        empty="Nothing for %{term}"
        create="Create %{term}"
        on_create="create_category"
        phx-target="#panel"
        clear_label="Clear"
        prefix="Compare to"
        options={@options}
      />
      """)

    assert html =~ ~s(data-search role="combobox")
    assert html =~ ~s(placeholder="Search")
    assert html =~ ~s(data-pattern="Nothing for %{term}")
    assert html =~ ~s(data-pattern="Create %{term}")
    assert html =~ ~s(data-create-event="create_category")
    assert html =~ ~s(data-create-target="#panel")
    refute html =~ ~s(phx-target=)
    assert html =~ ~s(aria-label="Clear")
    assert html =~ "Compare to"
  end

  test "takes the id, the name, the value and the error from a form field" do
    form = to_form(%{"category" => "dev"}, as: :post, errors: [category: {"is invalid", []}])
    assigns = %{form: form, options: @options}

    html =
      rendered_to_string(~H"""
      <Listbox.listbox
        field={@form[:category]}
        label="Category"
        placeholder="Choose"
        options={@options}
      />
      """)

    assert html =~ ~s(id="post_category")
    assert html =~ ~s(name="post[category]" value="dev")
    assert html =~ "listbox-trigger-invalid"
    assert html =~ "is invalid"
  end

  test "a multiple field gets the brackets and the list" do
    assigns = %{form: to_form(%{"who" => ["dev"]}, as: :post), options: @options}

    html =
      rendered_to_string(~H"""
      <Listbox.listbox
        field={@form[:who]}
        label="Who"
        placeholder="Nobody"
        multiple
        options={@options}
      />
      """)

    assert html =~ ~s(name="post[who][]" value="dev")
  end

  test "an error marks the button invalid" do
    assigns = %{options: @options}

    html =
      rendered_to_string(~H"""
      <Listbox.listbox
        id="cat"
        name="category"
        label="Category"
        placeholder="Choose"
        error="Choose one"
        options={@options}
      />
      """)

    assert html =~ "listbox-trigger-invalid"
    assert html =~ ~s(aria-invalid="true")
    assert html =~ ~s(id="cat-error" role="alert")
  end

  test "raises without an id, a name or a field" do
    assert_raise ArgumentError, ~r/listbox\/1 needs `id` and `name`/, fn ->
      assigns = %{}

      rendered_to_string(~H"""
      <Listbox.listbox label="Category" placeholder="Choose" options={[]} />
      """)
    end
  end
end
