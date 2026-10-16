defmodule DevactionUI.InteractiveTest do
  @moduledoc "The markup of the components that have a hook or rely on `<details>`. How they behave in a browser (keys, filtering, focus) is checked by hand with `/dev/ui`; here is what the server renders."
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.{Accordion, Combobox, Pillbox, Tabs, Tooltip}

  describe "Tabs" do
    defp tabs(assigns) do
      ~H"""
      <Tabs.tabs id="t" label="PRs" variant={@variant}>
        <:tab id="a" label="A" count="4">first</:tab>
        <:tab id="b" label="B" selected={@second}>second</:tab>
      </Tabs.tabs>
      """
    end

    test "the first tab is selected and the others wait, tied to their panels" do
      assigns = %{}
      html = rendered_to_string(~H|<.tabs variant={:boxed} second={false} />|)
      assert html =~ ~s(role="tablist")
      assert html =~ ~s(aria-label="PRs")
      assert html =~ ~s(id="t-tab-a")
      assert html =~ ~s(aria-controls="t-panel-a")
      assert html =~ ~s(aria-labelledby="t-tab-b")
      [selected] = Regex.scan(~r/aria-selected="true"/, html)
      assert length([selected]) == 1
      assert html =~ ~s(tabindex="-1")
      assert html =~ ~r/id="t-panel-b"[^>]*hidden|hidden[^>]*id="t-panel-b"/s
    end

    test "a tab marked selected wins, and a count is shown" do
      assigns = %{}
      html = rendered_to_string(~H|<.tabs variant={:line} second={true} />|)

      assert html =~
               ~r/id="t-tab-b"[^>]*aria-selected="true"|aria-selected="true"[^>]*id="t-tab-b"/s

      assert html =~ "border-b-2"
      assert html =~ ~r/>\s*4\s*</
    end

    test "carries the hook" do
      assigns = %{}
      html = rendered_to_string(~H|<.tabs variant={:boxed} second={false} />|)
      assert html =~ "phx-hook"
    end
  end

  describe "Accordion" do
    test "is made of details that share a name, so one open closes the rest" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Accordion.accordion id="acc">
          <:item title="One" open>first</:item>
          <:item title="Two" count="2">second</:item>
        </Accordion.accordion>
        """)

      assert length(Regex.scan(~r/<details/, html)) == 2
      assert length(Regex.scan(~r/name="acc"/, html)) == 2
      assert html =~ "<summary"
      assert html =~ "One" and html =~ "Two"
      assert length(Regex.scan(~r/<details[^>]*\sopen[\s>]/, html)) == 1
    end

    test "not exclusive means no shared name; flush has no outer border" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Accordion.accordion id="acc" exclusive={false} variant={:flush}>
          <:item title="One">first</:item>
        </Accordion.accordion>
        """)

      refute html =~ ~s(name="acc")
      refute html =~ "rounded-xl border"
      assert html =~ "border-b border-line-soft"
    end
  end

  test "Tooltip is tied to its trigger by the hook and says it with role tooltip" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Tooltip.tooltip id="tip" text="Opens GitHub"><a href="/x">GH</a></Tooltip.tooltip>
      """)

    assert html =~ ~s(phx-hook="DevactionUI.Tooltip")
    assert html =~ ~s(data-tip="tip-tip")
    refute html =~ "aria-describedby"
    assert html =~ ~s(role="tooltip")
    assert html =~ "Opens GitHub"
    assert html =~ "group-focus-within/tip:opacity-100"
  end

  describe "Pillbox" do
    test "sends each pill as name[] and ships a template for new ones" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Pillbox.pillbox id="pb" name="labels" values={["a", "b"]} label="Labels" remove_label="Remove" />
        """)

      assert length(Regex.scan(~r/name="labels\[\]"/, html)) == 3
      assert html =~ ~s(value="a")
      assert html =~ "<template"
      assert html =~ ~s(phx-update="ignore")
      assert html =~ ~s(aria-label="Remove")
      assert html =~ ~s(aria-label="Labels")
      assert html =~ "border border-line bg-wrap"
      assert html =~ "min-w-[90px]"
    end

    test "names each × by its pill and keeps the pattern for the new ones" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Pillbox.pillbox
          id="pb"
          name="labels"
          values={["a", "b"]}
          label="Labels"
          remove_label="Remove %{label}"
          added_label="%{label} added"
        />
        """)

      assert html =~ ~s(aria-label="Remove a")
      assert html =~ ~s(aria-label="Remove b")
      assert html =~ ~s(data-remove-label="Remove %{label}")
      assert html =~ ~s(data-added-label="%{label} added")
      assert html =~ ~s(role="status")
    end

    test "the field's own attributes and disabled reach the input and the pills" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Pillbox.pillbox
          id="pb"
          name="labels"
          values={["a"]}
          label="Labels"
          remove_label="Remove"
          disabled
          input_rest={%{"aria-describedby" => "pb-error", "aria-invalid" => "true"}}
        />
        """)

      assert html =~ ~r/<input[^>]*type="text"[^>]*aria-describedby="pb-error"/s
      assert html =~ ~s(aria-invalid="true")
      assert length(Regex.scan(~r/<(input|button)[^>]* disabled/, html)) >= 3
    end
  end

  describe "Combobox" do
    defp options, do: [%{value: "a", label: "Alpha", hint: "x"}, %{value: "b", label: "Beta"}]

    test "shows the chosen option, lists the options and keeps the value in a hidden input" do
      assigns = %{options: options()}

      html =
        rendered_to_string(~H"""
        <Combobox.combobox
          id="cb"
          name="project"
          options={@options}
          value="b"
          label="Project"
          placeholder="Choose"
          search_placeholder="Search"
          empty="None"
        />
        """)

      assert html =~ ~s(name="project")
      assert html =~ ~s(value="b")
      assert html =~ ~r/data-current[^>]*>\s*Beta\s*</
      assert length(Regex.scan(~r/role="option"/, html)) == 2
      assert html =~ ~s(aria-selected="true")
      assert html =~ ~s(role="combobox")
      assert html =~ ~s(aria-haspopup="listbox")
      assert html =~ "None"
      assert html =~ "x"
    end

    defp render_combobox(attrs) do
      assigns = %{options: options(), attrs: attrs}

      rendered_to_string(~H"""
      <Combobox.combobox
        id="cb"
        name="p"
        options={@options}
        label="Project"
        placeholder="Choose"
        search_placeholder="Search"
        empty="None"
        {@attrs}
      >
        <:chevron_icon>V</:chevron_icon>
        <:search_icon>S</:search_icon>
        <:clear_icon>X</:clear_icon>
        <:option_marker :let={option}>M-{option.value}</:option_marker>
      </Combobox.combobox>
      """)
    end

    test "the button is named by the label and the chosen text, so the choice is read" do
      html = render_combobox(value: "b")

      assert html =~ ~s(aria-labelledby="cb-label cb-current")
      assert html =~ ~s(id="cb-current")
      assert html =~ ~r/id="cb-label"[^>]*>\s*Project\s*</
      refute html =~ ~r/data-trigger[^>]*aria-label=/
    end

    test "the icons are slots, the open button has its ring and the marker gets the option" do
      html = render_combobox([])

      assert html =~ ~r/>\s*V\s*</
      assert html =~ ~r/>\s*S\s*</
      refute html =~ "⌄"
      assert html =~ "M-a"
      assert html =~ "aria-expanded:border-ink"
      assert html =~ "aria-expanded:ring-4"
      assert html =~ "hover:bg-wrap"
      assert html =~ "shadow-pop"
      assert html =~ "h-11"
      assert html =~ ~s(data-placeholder="Choose")
    end

    test "the label is hidden unless show_label draws it above the field, tied to the button" do
      hidden = render_combobox([])
      assert hidden =~ ~r/<label id="cb-label" for="cb-trigger" class="sr-only"/
      assert hidden =~ ~s(id="cb-trigger")

      shown = render_combobox(show_label: true)

      assert shown =~
               ~r/<label id="cb-label" for="cb-trigger" class="mb-1.5 block text-\[13px\] font-medium/

      refute shown =~ ~r/id="cb-label"[^>]*sr-only/
    end

    test "the help sits under the field and is read with it, together with the error" do
      plain = render_combobox([])
      refute plain =~ "cb-help"
      refute plain =~ "aria-describedby"

      help = render_combobox(help: "Where the PR is merged")
      assert help =~ ~s(aria-describedby="cb-help")
      assert help =~ ~r/id="cb-help"[^>]*>Where the PR is merged</

      both = render_combobox(help: "Where", error: "Pick one")
      assert both =~ ~s(aria-describedby="cb-help cb-error")
    end

    test "the clear button stays on the field, not on the label above it" do
      html = render_combobox(show_label: true, clear_label: "Clear", value: "a")
      assert html =~ ~r/<div class="relative">\s*<button[^>]*data-trigger/
      assert html =~ ~r/data-trigger.*data-clear/s
    end

    test "the list is not frozen: the options follow the patch" do
      refute render_combobox([]) =~ "phx-update"
    end

    test "disabled, required and error states" do
      html = render_combobox(disabled: true, required: true, error: "Pick one")

      assert html =~ ~r/data-trigger[^>]*disabled/
      assert html =~ ~s(aria-required="true")
      assert html =~ ~s(aria-invalid="true")
      assert html =~ ~s(aria-describedby="cb-error")
      assert html =~ ~r/id="cb-error"[^>]*role="alert"[^>]*>\s*Pick one/
      assert html =~ "border-risk-fg"
      assert html =~ ~r/<input type="hidden"[^>]*disabled/

      plain = render_combobox([])
      refute plain =~ "aria-invalid"
      refute plain =~ "cb-error"
    end

    test "a clear button only with a name, hidden while nothing is chosen" do
      refute render_combobox([]) =~ "data-clear"

      empty = render_combobox(clear_label: "Clear")
      assert empty =~ ~r/data-clear[^>]*aria-label="Clear"[^>]*hidden|hidden[^>]*data-clear/

      chosen = render_combobox(clear_label: "Clear", value: "a")
      assert chosen =~ "data-clear"
      refute chosen =~ ~r/<button[^>]*data-clear[^>]*\shidden[\s>]/
    end

    test "with no value it shows the placeholder, muted" do
      assigns = %{options: options()}

      html =
        rendered_to_string(~H"""
        <Combobox.combobox
          id="cb"
          name="p"
          options={@options}
          label="Project"
          placeholder="Choose"
          search_placeholder="Search"
          empty="None"
        />
        """)

      assert html =~ ~r/data-current class="text-muted">\s*Choose/
    end
  end
end
