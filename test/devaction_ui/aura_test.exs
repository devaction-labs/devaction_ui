defmodule DevactionUI.AuraTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.{Aura, ProgressToast}

  defp doc(html), do: LazyHTML.from_fragment(html)
  defp has?(html, selector), do: html |> doc() |> LazyHTML.query(selector) |> Enum.count() > 0

  describe "Aura" do
    test "wraps its content and takes its color from the tone" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Aura.aura id="a" tone={:learning}>
          <p id="inside">x</p>
        </Aura.aura>
        """)

      assert has?(html, "#a.text-learning #inside")
    end

    test "each variant moves, and the glow has no ring" do
      assigns = %{}

      for {variant, klass} <- [
            spin: "animate-aura-spin",
            dual: "animate-aura-spin-slow",
            glow: "animate-aura-glow"
          ] do
        assigns = Map.put(assigns, :variant, variant)

        html =
          rendered_to_string(~H"""
          <Aura.aura id="a" variant={@variant}>x</Aura.aura>
          """)

        assert has?(html, "#a.#{klass}"), "#{variant}"
      end

      glow =
        rendered_to_string(~H"""
        <Aura.aura id="a" variant={:glow}>x</Aura.aura>
        """)

      refute has?(glow, "#a.p-px, #a.p-\\[1\\.5px\\]")
    end

    test "the shape rounds the ring and the content, and the size is the ring width" do
      assigns = %{}

      for {shape, ring, inner} <- [
            {:card, "rounded-[15.5px]", "\\[\\&\\>\\*\\]\\:rounded-\\[14px\\]"},
            {:pill, "rounded-full", "\\[\\&\\>\\*\\]\\:rounded-full"},
            {:circle, "rounded-full", "\\[\\&\\>\\*\\]\\:rounded-full"}
          ] do
        assigns = Map.put(assigns, :shape, shape)

        html =
          rendered_to_string(~H"""
          <Aura.aura id="a" shape={@shape} aria-busy="true">x</Aura.aura>
          """)

        assert html =~ ring, "#{shape}"
        assert has?(html, "#a.#{inner}[aria-busy=true]"), "#{shape}"
      end

      md =
        rendered_to_string(~H"""
        <Aura.aura id="a" size={:md}>x</Aura.aura>
        """)

      assert has?(md, "#a.p-0\\.5")
    end

    test "the fast speed is the chip's 1.4 s, for the ring and for the dual one" do
      assigns = %{}

      for variant <- [:spin, :dual] do
        assigns = Map.put(assigns, :variant, variant)

        html =
          rendered_to_string(~H"""
          <Aura.aura id="a" variant={@variant} speed={:fast}>x</Aura.aura>
          """)

        assert has?(html, "#a.animate-aura-spin-fast"), "#{variant}"
      end
    end

    test "no colour is fixed: the ring follows the tone and the trail the line token, in both themes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Aura.aura id="a" variant={:dual} tone={:ai}>x</Aura.aura>
        <Aura.aura id="b" variant={:spin} tone={:risk}>x</Aura.aura>
        """)

      assert html =~ "var(--line)"
      assert html =~ "currentColor"
      refute html =~ ~r/#[0-9A-Fa-f]{3,6}[^\w]/
      assert has?(html, "#a.text-ai")
      assert has?(html, "#b.text-missing")
    end

    test "all of it stops under reduced motion" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Aura.aura id="a">x</Aura.aura>
        """)

      assert has?(html, "#a.motion-reduce\\:animate-none")
    end
  end

  describe "ProgressToast" do
    defp toast(attrs) do
      assigns = Map.merge(%{id: "t", state: :running, progress: 40}, Map.new(attrs))

      rendered_to_string(~H"""
      <ProgressToast.progress_toast
        id={@id}
        state={@state}
        progress={@progress}
        title="Reviewing"
        on_dismiss="dismiss"
        dismiss_label="Close"
      >
        Reading the diff
      </ProgressToast.progress_toast>
      """)
    end

    test "a running job fills as far as it got, inside an aura" do
      html = toast(progress: 42)

      assert has?(html, ".text-ai #t[data-state=running][phx-hook='DevactionUI.ProgressToast']")
      assert has?(html, "#t [role=progressbar][aria-valuenow='42'][style='width: 42%']")
      assert has?(html, "#t [data-dismiss][phx-click=dismiss][phx-value-id=t]")
    end

    test "progress stays between 0 and 100" do
      assert has?(toast(progress: 180), "#t [role=progressbar][aria-valuenow='100']")
      assert has?(toast(progress: -5), "#t [role=progressbar][aria-valuenow='0']")
    end

    test "done and error carry no aura, and only the error is an alert" do
      done = toast(state: :done, progress: 100)
      refute has?(done, ".text-ai")
      assert has?(done, "#t[data-state=done][role=status]")

      error = toast(state: :error)
      assert has?(error, "#t[data-state=error][role=alert]")
    end
  end
end
