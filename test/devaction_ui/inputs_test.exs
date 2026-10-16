defmodule DevactionUI.InputsTest do
  @moduledoc "The number field, the sliders, the timer and the signature field."
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.{NumberInput, SignatureField, Slider, Timer}

  doctest DevactionUI.NumberInput

  describe "NumberInput" do
    test "the arithmetic keeps the value inside its limits" do
      assert NumberInput.step(2, 1, 1, 5) == 3
      assert NumberInput.step(5, 1, 1, 5) == 5
      assert NumberInput.step(1, -1, 1, 5) == 1
      assert NumberInput.step(3, -10, nil, nil) == -7
      assert NumberInput.clamp(9, nil, 5) == 5
      assert NumberInput.clamp(-3, 0, nil) == 0
    end

    defp number(value) do
      assigns = %{value: value}

      rendered_to_string(~H"""
      <NumberInput.number_input
        id="n"
        name="seats"
        value={@value}
        label="Seats"
        min={1}
        max={5}
        step={2}
        event="step"
        decrease_label="Fewer"
        increase_label="More"
      >
        <:minus_icon>-</:minus_icon>
        <:plus_icon>+</:plus_icon>
      </NumberInput.number_input>
      """)
    end

    test "is a spinbutton that says its value and limits, with a button each way" do
      html = number(3)

      assert html =~ ~s(role="spinbutton")
      assert html =~ ~s(aria-valuenow="3")
      assert html =~ ~s(aria-valuemin="1")
      assert html =~ ~s(aria-valuemax="5")
      assert html =~ ~s(aria-label="Fewer")
      assert html =~ ~s(aria-label="More")
      assert html =~ ~s(phx-value-step="-2")
      assert html =~ ~s(phx-value-step="2")
      assert html =~ "number-input"
      refute html =~ ~r/ disabled[ >]/
    end

    test "the buttons give out at the limits" do
      assert number(1) =~ ~r/id="n-minus"[^>]* disabled[ >]/s
      refute number(1) =~ ~r/id="n-plus"[^>]* disabled[ >]/s
      assert number(5) =~ ~r/id="n-plus"[^>]* disabled[ >]/s
    end

    test "a disabled field disables everything" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <NumberInput.number_input
          id="n"
          name="x"
          value={1}
          label="L"
          event="e"
          decrease_label="a"
          increase_label="b"
          disabled
        >
          <:minus_icon>-</:minus_icon>
          <:plus_icon>+</:plus_icon>
        </NumberInput.number_input>
        """)

      assert length(Regex.scan(~r/ disabled[ >]/, html)) >= 3
      assert html =~ "opacity-60"
    end

    test "the unit is shown and read with the value, and the help describes the field" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <NumberInput.number_input
          id="n"
          name="x"
          value={8}
          label="L"
          unit="h"
          event="e"
          decrease_label="a"
          increase_label="b"
        >
          <:minus_icon>-</:minus_icon>
          <:plus_icon>+</:plus_icon>
          <:help>Between 1 and 12</:help>
        </NumberInput.number_input>
        """)

      assert html =~ ~s(aria-valuetext="8 h")
      assert html =~ ~s(aria-describedby="n-help")
      assert html =~ ~s(id="n-help")
      assert html =~ "Between 1 and 12"
    end

    test "without unit, help and limits those attributes are left out" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <NumberInput.number_input
          id="n"
          name="x"
          value={1}
          label="L"
          event="e"
          decrease_label="a"
          increase_label="b"
        >
          <:minus_icon>-</:minus_icon>
          <:plus_icon>+</:plus_icon>
        </NumberInput.number_input>
        """)

      refute html =~ "aria-valuetext"
      refute html =~ "aria-valuemin"
      refute html =~ "aria-valuemax"
      refute html =~ "aria-describedby"
      refute html =~ ~s(id="n-help")
    end

    test "hands the hook the event, the step and the limits" do
      html = number(3)
      assert html =~ ~s(phx-hook="DevactionUI.NumberInput")
      assert html =~ ~s(data-event="step")
      assert html =~ ~s(data-step="2")
      assert html =~ ~s(data-min="1")
      assert html =~ ~s(data-max="5")
      assert html =~ ~s(data-precision="0")
      assert html =~ ~s(data-decimal=".")
    end

    defp decimal_field(extra) do
      assigns = %{extra: extra}

      rendered_to_string(~H"""
      <NumberInput.number_input
        id="n"
        name="rate"
        value={@extra[:value] || 0.5}
        label="Rate"
        step={@extra[:step] || 0.25}
        min={@extra[:min]}
        max={@extra[:max]}
        precision={@extra[:precision]}
        decimal={@extra[:decimal] || "."}
        unit={@extra[:unit]}
        event="e"
        decrease_label="a"
        increase_label="b"
      >
        <:minus_icon>-</:minus_icon>
        <:plus_icon>+</:plus_icon>
      </NumberInput.number_input>
      """)
    end

    test "a fractional step is sent exactly and the field shows the decimals of the step" do
      html = decimal_field(%{})
      assert html =~ ~s(phx-value-step="-0.25")
      assert html =~ ~s(phx-value-step="0.25")
      assert html =~ ~s(data-step="0.25")
      assert html =~ ~s(data-precision="2")
      assert html =~ ~s(value="0.50")
      assert html =~ ~s(aria-valuenow="0.50")
      assert html =~ ~s(inputmode="decimal")
    end

    test "precision overrides the derived one, and the decimal separator is shown but never sent" do
      html = decimal_field(%{precision: 1, decimal: ",", unit: "%", step: "0.5", value: "2.5"})
      assert html =~ ~s(value="2,5")
      assert html =~ ~s(aria-valuenow="2.5")
      assert html =~ ~s(aria-valuetext="2,5 %")
      assert html =~ ~s(data-decimal=",")
      assert html =~ ~s(phx-value-step="0.5")
    end

    test "the value may be text, and a whole step keeps the numeric keypad" do
      html = decimal_field(%{value: "3", step: 1})
      assert html =~ ~s(value="3")
      assert html =~ ~s(inputmode="numeric")
      assert html =~ ~s(phx-value-step="-1")
    end

    test "the buttons give out at fractional limits" do
      html = decimal_field(%{value: 0.1, min: 0.1, max: "0.35"})
      assert html =~ ~r/id="n-minus"[^>]* disabled[ >]/s
      refute html =~ ~r/id="n-plus"[^>]* disabled[ >]/s
      assert html =~ ~s(aria-valuemin="0.1")
      assert html =~ ~s(aria-valuemax="0.35")
      assert decimal_field(%{value: 0.35, max: 0.35}) =~ ~r/id="n-plus"[^>]* disabled[ >]/s
    end

    test "a unit_mark draws the unit while the unit stays the text read out" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <NumberInput.number_input
          id="n"
          name="x"
          value={2}
          label="Area"
          unit="m2"
          event="e"
          decrease_label="a"
          increase_label="b"
        >
          <:minus_icon>-</:minus_icon>
          <:plus_icon>+</:plus_icon>
          <:unit_mark>m<sup>2</sup></:unit_mark>
        </NumberInput.number_input>
        """)

      assert html =~ "<sup>2</sup>"
      assert html =~ ~s(aria-valuetext="2 m2")
    end

    test "the arithmetic is exact with decimals, in numbers and in text" do
      assert NumberInput.step(0.1, 0.2, nil, nil) == 0.3
      assert NumberInput.step("0.1", "0.2", nil, nil) == 0.3
      assert NumberInput.step(1.15, 0.05, nil, 1.2) == 1.2
      assert NumberInput.step(0.3, -0.1, 0, 1) == 0.2
      assert NumberInput.step(2.5, -2.5, nil, nil) === 0
      assert NumberInput.step(1, "0,5", nil, nil) == 1.5
      assert NumberInput.step(0.9, 0.25, 0, "1") == 1
      assert NumberInput.clamp("12.5", 0, "10.25") == 10.25
      assert NumberInput.clamp(1.5, "2", nil) == 2
    end

    test "the sum of whole numbers stays an integer" do
      assert NumberInput.step(2, 3, 1, 9) === 5
      assert NumberInput.clamp(7, 1, 5) === 5
    end

    test "text that is not a number raises" do
      assert_raise ArgumentError, fn -> NumberInput.step("abc", 1, nil, nil) end
    end

    test "parse reads a dot or a comma and rejects the rest" do
      assert NumberInput.parse("3") == {:ok, 3}
      assert NumberInput.parse("-2,5") == {:ok, -2.5}
      assert NumberInput.parse(" 0.25 ") == {:ok, 0.25}
      assert NumberInput.parse("1e2") == {:ok, 100}
      assert NumberInput.parse("") == :error
      assert NumberInput.parse("1.2.3") == :error
      assert NumberInput.parse("abc") == :error
      assert NumberInput.parse(nil) == :error
    end

    test "format pads and rounds half away from zero" do
      assert NumberInput.format(3, 2) == "3.00"
      assert NumberInput.format(0.05, 2) == "0.05"
      assert NumberInput.format("1.005", 2) == "1.01"
      assert NumberInput.format("-1.005", 2, ",") == "-1,01"
      assert NumberInput.format(2.5, 0) == "3"
      assert NumberInput.format(-0.004, 2) == "0.00"
      assert NumberInput.format(1.0e-5, 6) == "0.000010"
    end

    test "the limits reach the hook as plain text, without the precision" do
      assert decimal_field(%{min: 0, max: 5}) =~ ~s(data-min="0")
    end
  end

  describe "Slider" do
    test "a slider is a native range input with its value beside it" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<Slider.slider id="s" name="h" label="Hours" value={12} max={40} format={&"#{&1} h"} />|
        )

      assert html =~ ~s(type="range")
      assert html =~ ~s(min="0")
      assert html =~ ~s(max="40")
      assert html =~ ~s(value="12")
      assert html =~ ~s(<label for="s">Hours</label>)
      assert html =~ "12 h"
      assert html =~ ~s(class="range)
      assert html =~ "--p: 30.0%"
    end

    test "the marks sit under the track and are not read out twice" do
      assigns = %{}

      html =
        rendered_to_string(~H|<Slider.slider
  id="s"
  name="h"
  label="Rigor"
  value={2}
  min={1}
  max={5}
  ticks={["Bugs", "Default", "All"]}
/>|)

      assert html =~ ~s(aria-hidden="true")
      assert html =~ "Bugs"
      assert html =~ "All"
    end

    test "the marks fall in equal columns and the nearest one is stressed" do
      assigns = %{}

      html =
        rendered_to_string(~H|<Slider.slider
  id="s"
  name="h"
  label="Rigor"
  value={3}
  min={1}
  max={5}
  ticks={["Bugs", "Default", "All"]}
/>|)

      assert html =~ "grid-template-columns: repeat(3, minmax(0, 1fr))"
      assert html =~ ~r/data-active="true"[^>]*>\s*Default/
      assert length(Regex.scan(~r/data-active="true"/, html)) == 1
      assert html =~ "text-left"
      assert html =~ "text-right"
      assert Slider.active_tick(0.0, 3) == 0
      assert Slider.active_tick(100.0, 3) == 2
      assert Slider.active_tick(30.0, 1) == 0
    end

    test "the value can be a float, read aloud as text, and follows the thumb when it has a template" do
      assigns = %{}

      html =
        rendered_to_string(~H|<Slider.slider
  id="s"
  name="h"
  label="Cover"
  value={0.5}
  min={0.0}
  max={2.0}
  step={0.1}
  value_text="Half"
  format_text="%{value} x"
/>|)

      assert html =~ ~s(step="0.1")
      assert html =~ ~s(aria-valuetext="Half")
      assert html =~ "0.5 x"
      assert html =~ ~s(data-format-text="%{value} x")
      assert html =~ "--p: 25.0%"
      assert html =~ "text-ink-2"
    end

    test "the percent is where the value sits between the ends" do
      assert Slider.percent(50, 0, 100) == 50.0
      assert Slider.percent(75, 50, 100) == 50.0
      assert Slider.percent(5, 5, 5) == 0.0
    end

    test "a range slider has two inputs on one track and the filled part between them" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Slider.range_slider
          id="r"
          name_low="a"
          name_high="b"
          label_low="From"
          label_high="To"
          low={20}
          high={70}
        />
        """)

      assert length(Regex.scan(~r/type="range"/, html)) == 2
      assert html =~ ~s(aria-label="From")
      assert html =~ ~s(aria-label="To")
      assert html =~ "left: 20.0%; width: 50.0%"
      assert html =~ "20 – 70"
      assert html =~ ~s(phx-hook="DevactionUI.RangePair")
      assert html =~ "data-fill"
      refute html =~ "range-pair"
    end

    test "a range slider takes floats and a text template for its values" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Slider.range_slider
          id="r"
          name_low="a"
          name_high="b"
          label_low="From"
          label_high="To"
          low={0.5}
          high={1.5}
          min={0.0}
          max={2.0}
          step={0.5}
          format_text="%{value} h"
        />
        """)

      assert html =~ "left: 25.0%; width: 50.0%"
      assert html =~ "0.5 h – 1.5 h"
      assert html =~ ~s(data-format-text="%{value} h")
    end

    test "the pair is put in order and inside the limits" do
      assert Slider.range(0, 100, {70, 20}) == {20, 70}
      assert Slider.range(0, 100, {-5, 120}) == {0, 100}
      assert Slider.range(10, 20, {15, 15}) == {15, 15}
    end
  end

  describe "Timer" do
    test "the seconds counted, with the base and the time since the start" do
      assert Timer.elapsed(60, nil, 1000) == 60
      assert Timer.elapsed(60, 1000, 1030) == 90
      assert Timer.elapsed(60, 1000, 990) == 60
      assert Timer.format(0) == "00:00:00"
      assert Timer.format(3725) == "01:02:05"
    end

    defp timer(base, started_at) do
      assigns = %{base: base, started_at: started_at}

      rendered_to_string(~H"""
      <Timer.timer
        id="t"
        base={@base}
        started_at={@started_at}
        now={2000}
        label="Time on DIA-142"
        toggle_event="toggle"
        log_event="log"
        start_label="Start"
        pause_label="Pause"
        log_label="Log"
      >
        <:start_icon>S</:start_icon>
        <:pause_icon>P</:pause_icon>
      </Timer.timer>
      """)
    end

    test "paused: shows the base, offers to start and cannot log nothing" do
      html = timer(0, nil)

      assert html =~ ~s(phx-hook="DevactionUI.Timer")
      assert html =~ ~s(data-base="0")
      assert html =~ ~s(data-running="false")
      assert html =~ "00:00:00"
      assert html =~ "Start"
      refute html =~ "aria-pressed"
      assert html =~ ~r/id="t-log"[^>]* disabled[ >]/s
    end

    test "running: counts from when it started and offers to pause" do
      html = timer(60, 1900)

      assert html =~ ~s(data-started-at="1900")
      assert html =~ ~s(data-now="2000")
      assert html =~ "00:02:40"
      assert html =~ "Pause"
      refute html =~ "aria-pressed"
      assert html =~ "bg-ink"
      refute html =~ ~r/id="t-log"[^>]* disabled[ >]/s
    end

    test "the buttons are round, named for assistive technology, and the task is written out" do
      html = timer(0, nil)

      assert html =~ ~s(aria-label="Start")
      assert html =~ ~s(aria-label="Log")
      assert html =~ "rounded-full"
      assert html =~ "bg-ok-fg"
      refute html =~ "#15803D"
      assert html =~ "Time on DIA-142"
    end

    test "the caption follows the state when the caller gives its words" do
      assigns = %{}

      render = fn started_at ->
        assigns = %{started_at: started_at}

        rendered_to_string(~H"""
        <Timer.timer
          id="t"
          base={0}
          started_at={@started_at}
          now={10}
          label="Task"
          toggle_event="toggle"
          log_event="log"
          start_label="Start"
          pause_label="Pause"
          log_label="Log"
          running_text="Running"
          paused_text="Paused"
        />
        """)
      end

      assert render.(nil) =~ "Paused"
      refute render.(nil) =~ "Running"
      assert render.(5) =~ "Running"
    end
  end

  describe "SignatureField" do
    test "only path commands and numbers are a safe stroke" do
      assert SignatureField.safe_path?("M1 2 L3.5 4 L5 6")
      refute SignatureField.safe_path?("<script>")
      refute SignatureField.safe_path?("M1 2 Z")
      refute SignatureField.safe_path?(String.duplicate("M1 2 ", 5_000))
      refute SignatureField.safe_path?(nil)
    end

    test "the SVG is the drawing and nothing for an unsafe stroke" do
      svg = SignatureField.to_svg("M1 2 L3 4")
      assert svg =~ ~s(viewBox="0 0 360 170")
      assert svg =~ ~s(d="M1 2 L3 4")
      assert svg =~ ~s(stroke="#18181B" stroke-width="2.2")
      assert SignatureField.to_svg("<bad>") == nil
    end

    test "the SVG takes the colour of the caller, as a hex or currentColor and nothing else" do
      assert SignatureField.to_svg("M1 2 L3 4", "#FFFFFF") =~ ~s(stroke="#FFFFFF")
      assert SignatureField.to_svg("M1 2 L3 4", "currentColor") =~ ~s(stroke="currentColor")
      assert SignatureField.to_svg("M1 2 L3 4", ~s(red" onload="x)) == nil
    end

    defp field(mode) do
      assigns = %{mode: mode}

      rendered_to_string(~H"""
      <SignatureField.signature_field
        id="sig"
        name="signature"
        mode={@mode}
        typed="Maria"
        label="Sign"
        mode_event="mode"
        draw_label="Draw"
        type_label="Type"
        clear_label="Clear"
        hint="Use the mouse"
      />
      """)
    end

    test "drawing: a pad with the hook, a clear button and the fields for the form" do
      html = field(:draw)

      assert html =~ ~s(phx-hook="DevactionUI.Signature")
      assert html =~ "data-clear"
      assert html =~ ~s(name="signature[path]")
      assert html =~ ~s(name="signature[method]" value="draw")
      assert html =~ ~s(aria-pressed="true")
      assert html =~ "Use the mouse"
      assert html =~ ~s(<line)
      assert html =~ ~s(stroke-width="2.2")
      refute html =~ ~s(name="signature[typed]")
      refute html =~ ~s(role="img")
      assert html =~ ~s(aria-hidden="true")
    end

    test "the pad stays mounted, only hidden, when the mode is typing" do
      draw = field(:draw)
      type = field(:type)

      refute draw =~ ~r/<div[^>]* hidden[^>]*>\s*<div id="sig-pad"/

      assert type =~
               ~r/<div[^>]* hidden[^>]*>\s*<div id="sig-pad"[^>]*phx-hook="DevactionUI.Signature"/s

      assert type =~ ~s(name="signature[path]")
    end

    test "the pad has a name, a status, a clear icon, an error and a disabled state when asked for" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <SignatureField.signature_field
          id="sig"
          name="signature"
          label="Sign"
          mode_event="mode"
          draw_label="Draw"
          type_label="Type"
          clear_label="Clear"
          pad_label="Signature area"
          empty_label="Empty"
          ready_label="Ready"
          error="Sign here"
          disabled
        >
          <:clear_icon>ERASER</:clear_icon>
        </SignatureField.signature_field>
        """)

      assert html =~ ~s(role="img")
      assert html =~ ~s(aria-label="Signature area")
      assert html =~ "ERASER"
      assert html =~ ~s(data-empty="Empty")
      assert html =~ ~s(data-ready="Ready")
      assert html =~ ~s(role="alert")
      assert html =~ "Sign here"
      assert html =~ "pointer-events-none"
      assert html =~ ~r/<button[^>]* disabled/
    end

    test "typing: the name field and its look, with no pad" do
      html = field(:type)

      assert html =~ ~s(name="signature[typed]")
      assert html =~ ~s(value="Maria")
      assert html =~ "signature-typed"
      assert html =~ ~s(name="signature[method]" value="type")
      assert html =~ "h-[110px]"
    end
  end
end
