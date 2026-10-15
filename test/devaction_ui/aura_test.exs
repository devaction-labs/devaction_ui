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
