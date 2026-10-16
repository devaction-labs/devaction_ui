defmodule DevactionUI.FormFieldsTest do
  @moduledoc "The fields of the library: the input group, the text area and the boxes and options to pick."
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.{Choice, InputGroup, Textarea}

  describe "InputGroup" do
    test "frames a plain input with the icon, the add-ons and the key cap in their places" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <InputGroup.input_group id="f" name="n" value="v" placeholder="p">
          <:icon>ICON</:icon>
          <:prefix>PRE</:prefix>
          <:suffix>SUF</:suffix>
          <:hint>HINT</:hint>
        </InputGroup.input_group>
        """)

      assert html =~ ~s(class="input-group)
      assert html =~ ~s(<input id="f" name="n" type="text" value="v" placeholder="p")
      assert html =~ ~r/input-addon[^>]*>PRE.*ICON.*<input.*HINT.*input-addon[^>]*>SUF/s
      refute html =~ "aria-invalid"
    end

    test "takes the size, the error and what a native input takes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <InputGroup.input_group id="a" size={:sm} invalid disabled />
        <InputGroup.input_group id="b" size={:lg} readonly />
        <InputGroup.input_group id="c" />
        """)

      assert html =~ "input-sm"
      assert html =~ "input-lg"
      assert html =~ ~s(aria-invalid="true")
      assert html =~ "disabled"
      assert html =~ "readonly"
      refute html =~ ~r/id="c-group"[^>]*input-(sm|lg)/
    end

    test "the action replaces itself with a spinner while it validates" do
      assigns = %{}

      shown =
        rendered_to_string(~H"""
        <InputGroup.input_group id="a">
          <:action>
            <InputGroup.input_action label="Clear" phx-click="clear">X</InputGroup.input_action>
          </:action>
        </InputGroup.input_group>
        """)

      assert shown =~ ~s(aria-label="Clear")
      assert shown =~ ~s(class="input-action)
      assert shown =~ ~s(type="button")
      refute shown =~ "role=\"status\""

      loading =
        rendered_to_string(~H"""
        <InputGroup.input_group id="a" loading loading_label="Checking">
          <:action>
            <InputGroup.input_action label="Clear">X</InputGroup.input_action>
          </:action>
        </InputGroup.input_group>
        """)

      assert loading =~ ~s(role="status")
      assert loading =~ "Checking"
      refute loading =~ ~s(aria-label="Clear")
      refute loading =~ "false"

      assert_raise ArgumentError, ~r/loading_label/, fn ->
        rendered_to_string(~H|<InputGroup.input_group id="a" loading />|)
      end
    end

    test "passes the validation attributes and the description of the error to the input" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <InputGroup.input_group
          id="a"
          pattern="[a-z]+"
          minlength="3"
          form="f"
          list="opts"
          invalid
          aria-describedby="a-error"
        />
        """)

      assert html =~ ~s(pattern="[a-z]+")
      assert html =~ ~s(minlength="3")
      assert html =~ ~s(form="f")
      assert html =~ ~s(list="opts")
      assert html =~ ~s(aria-describedby="a-error")
    end

    test "an invalid and disabled field says both, a readonly one is plain readonly" do
      assigns = %{}
      html = rendered_to_string(~H|<InputGroup.input_group id="a" invalid disabled readonly />|)
      assert html =~ ~s(aria-invalid="true")
      assert html =~ "disabled"
      assert html =~ "readonly"
    end

    test "add-ons are boxed unless loose, and mono when asked" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <InputGroup.input_group id="a">
          <:prefix mono>R$</:prefix>
          <:suffix loose>.devaction.app</:suffix>
          <:suffix>por marco</:suffix>
        </InputGroup.input_group>
        """)

      assert html =~ ~r/class="input-addon font-mono[^"]*">R\$/
      assert html =~ ~r/class="input-note[^"]*">\.devaction\.app/
      assert html =~ ~r/class="input-addon[^"]*">por marco/
    end

    test "the action keeps the phx-click given in rest" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<InputGroup.input_action label="Copy" phx-click="copy" phx-value-id="1">
  X
</InputGroup.input_action>|
        )

      assert html =~ ~s(phx-click="copy")
      assert html =~ ~s(phx-value-id="1")
    end
  end

  describe "Textarea" do
    test "carries the text, the rows and the maxlength" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<Textarea.textarea id="t" name="n" value="hello" rows={5} maxlength={500} />|
        )

      assert html =~ ~s(<textarea id="t" name="n" rows="5" maxlength="500")
      assert html =~ ">hello</textarea>"
      assert html =~ "5/500"
      assert html =~ ~s(data-over="false")
    end

    test "the counter turns near the limit and not before" do
      assert Textarea.near_limit?(450, 500)
      refute Textarea.near_limit?(449, 500)

      assigns = %{}

      assert rendered_to_string(
               ~H|<Textarea.textarea id="t" value={String.duplicate("x", 470)} maxlength={500} />|
             ) =~
               ~s(data-over="true")
    end

    test "has no footer without actions or a limit, and a footer with them" do
      assigns = %{}

      refute rendered_to_string(~H|<Textarea.textarea id="t" />|) =~ "textarea-footer"

      html =
        rendered_to_string(~H"""
        <Textarea.textarea id="t">
          <:footer>
            <Textarea.footer_button label="Attach" phx-click="x">A</Textarea.footer_button>
          </:footer>
        </Textarea.textarea>
        """)

      assert html =~ "textarea-footer"
      assert html =~ ~s(aria-label="Attach")
      refute html =~ "textarea-count"
    end

    test "the error is on the textarea only, for the frame to draw the ring" do
      assigns = %{}
      html = rendered_to_string(~H|<Textarea.textarea id="t" invalid disabled />|)

      assert [_] = Regex.scan(~r/aria-invalid="true"/, html)
      assert html =~ ~r/<textarea[^>]*aria-invalid="true"/
      refute html =~ ~r/<div[^>]*aria-invalid/
      assert html =~ "disabled"
    end

    test "rows is the least height" do
      assigns = %{}
      assert rendered_to_string(~H|<Textarea.textarea id="t" rows={2} />|) =~ "--rows: 2"
    end

    test "the counter describes the field and joins the description the caller gives" do
      assigns = %{}

      html = rendered_to_string(~H|<Textarea.textarea id="t" maxlength={10} />|)
      assert html =~ ~s(aria-describedby="t-count")
      assert html =~ ~s(aria-live="off")

      html =
        rendered_to_string(
          ~H|<Textarea.textarea id="t" maxlength={10} value="123456789" aria-describedby="t-help" />|
        )

      assert html =~ ~s(aria-describedby="t-help t-count")
      assert html =~ ~s(aria-live="polite")
      assert [_] = Regex.scan(~r/aria-describedby/, html)

      refute rendered_to_string(~H|<Textarea.textarea id="t" />|) =~ "aria-describedby"
    end

    test "takes minlength, form and wrap" do
      assigns = %{}

      html =
        rendered_to_string(~H|<Textarea.textarea id="t" minlength="5" form="f" wrap="soft" />|)

      assert html =~ ~s(minlength="5")
      assert html =~ ~s(form="f")
      assert html =~ ~s(wrap="soft")
    end

    test "a footer button is 34px, with an AI look and what the caller gives in rest" do
      assigns = %{}

      plain =
        rendered_to_string(
          ~H|<Textarea.footer_button label="Attach" phx-click="attach">A</Textarea.footer_button>|
        )

      ai =
        rendered_to_string(
          ~H|<Textarea.footer_button label="Improve" variant={:ai}>I</Textarea.footer_button>|
        )

      assert plain =~ "h-[34px]"
      assert plain =~ ~s(phx-click="attach")
      assert ai =~ "tag-warn-bg"
    end
  end

  describe "Choice" do
    test "the state of select all follows how many are ticked" do
      assert Choice.select_all_state(3, 0) == :none
      assert Choice.select_all_state(3, 2) == :some
      assert Choice.select_all_state(3, 3) == :all
    end

    test "a checkbox is a real input, with a partial state that is not checked" do
      assigns = %{}

      on =
        rendered_to_string(
          ~H|<Choice.checkbox id="c" name="n" checked label="L" description="D" />|
        )

      assert on =~ ~s(type="checkbox")
      assert on =~ "checked"
      refute on =~ "aria-checked"
      assert on =~ "choice-desc"

      partial = rendered_to_string(~H|<Choice.checkbox id="c" checked partial label="L" />|)
      assert partial =~ ~s(data-partial="true")
      assert partial =~ ~s(phx-hook="DevactionUI.Indeterminate")
      refute partial =~ "aria-checked"
      refute partial =~ ~r/<input[^>]* checked/

      bare = rendered_to_string(~H|<Choice.checkbox id="c" />|)
      refute bare =~ "aria-checked"
      refute bare =~ "choice-desc"
    end

    test "a disabled box reaches the input and the label is medium weight" do
      assigns = %{}

      html =
        rendered_to_string(~H|<Choice.checkbox id="c" label="L" disabled form="f" />|)

      assert html =~ ~r/<input[^>]* disabled/
      assert html =~ ~s(form="f")
      assert html =~ "font-medium"
    end

    test "a radio shares its name and shows its description" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Choice.radio id="r1" name="m" value="a" label="A" description="First" checked />
        <Choice.radio id="r2" name="m" value="b" label="B" />
        """)

      assert html =~ ~s(type="radio")
      assert length(Regex.scan(~r/name="m"/, html)) == 2
      assert html =~ "First"
      assert html =~ ~s(class="radio")
    end

    test "a choice card is a radio or a checkbox, with an icon when given one" do
      assigns = %{}

      radio =
        rendered_to_string(~H"""
        <Choice.choice_card id="c" name="p" value="v" label="L" description="D" checked>
          <:icon>ICON</:icon>
        </Choice.choice_card>
        """)

      assert radio =~ "choice-card"
      assert radio =~ ~s(type="radio")
      assert radio =~ "ICON"

      box =
        rendered_to_string(
          ~H|<Choice.choice_card id="c" name="p" value="v" type="checkbox" label="L" />|
        )

      assert box =~ ~s(type="checkbox")
      assert box =~ ~s(class="checkbox")
    end

    test "a choice card is a row by default and a stack on request" do
      assigns = %{}

      row = rendered_to_string(~H|<Choice.choice_card id="c" name="p" value="v" label="L" />|)
      assert row =~ "items-start"
      refute row =~ "flex-col items-start"
      refute row =~ "order-first"

      stack =
        rendered_to_string(
          ~H|<Choice.choice_card id="c" name="p" value="v" label="L" layout={:stack} />|
        )

      assert stack =~ "flex-col items-start"
      assert stack =~ "order-first"
    end
  end
end
