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
      assert html =~ ">4<"
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

  test "Tooltip describes its trigger and says it with role tooltip" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Tooltip.tooltip id="tip" text="Opens GitHub"><a href="/x">GH</a></Tooltip.tooltip>
      """)

    assert html =~ ~s(aria-describedby="tip-tip")
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
