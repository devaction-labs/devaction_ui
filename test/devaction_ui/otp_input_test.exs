defmodule DevactionUI.OtpInputTest do
  @moduledoc "The boxes of a one-time code: the boxes, the hidden joined value, the states, the helper and the resend line."
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.OtpInput

  defp render_otp(extra \\ %{}) do
    assigns =
      Map.merge(
        %{
          value: "",
          length: 6,
          separator_after: nil,
          status: :idle,
          helper: nil,
          numeric: true,
          resend: false
        },
        extra
      )

    rendered_to_string(~H"""
    <OtpInput.input
      id="otp"
      name="code"
      label="Verification code"
      box_label="Digit %{n} of %{total}"
      value={@value}
      length={@length}
      separator_after={@separator_after}
      status={@status}
      helper={@helper}
      numeric={@numeric}
    >
      <:resend :if={@resend}>Did not arrive? <b>Resend in 0:24</b></:resend>
    </OtpInput.input>
    """)
  end

  defp boxes(html), do: Regex.scan(~r/<input[^>]*data-otp-box[^>]*>/, html) |> List.flatten()

  test "six boxes by default, each named, with the one-time-code autocomplete and a numeric keyboard" do
    html = render_otp()

    assert length(boxes(html)) == 6
    assert html =~ ~s(phx-hook="DevactionUI.OtpInput")
    assert html =~ ~s(role="group")
    assert html =~ ~s(aria-label="Verification code")
    assert html =~ ~s(aria-label="Digit 1 of 6")
    assert html =~ ~s(aria-label="Digit 6 of 6")
    assert Enum.all?(boxes(html), &(&1 =~ ~s(autocomplete="one-time-code")))
    assert Enum.all?(boxes(html), &(&1 =~ ~s(inputmode="numeric")))
    assert Enum.all?(boxes(html), &(&1 =~ ~s(pattern="[0-9]*")))
  end

  test "the length is up to the caller" do
    assert length(boxes(render_otp(%{length: 4}))) == 4
    assert render_otp(%{length: 4}) =~ ~s(aria-label="Digit 4 of 4")
  end

  test "the value fills the boxes from the start and goes joined into one hidden input" do
    html = render_otp(%{value: "482"})
    [first, second, third, fourth | _] = boxes(html)

    assert first =~ ~s(value="4")
    assert second =~ ~s(value="8")
    assert third =~ ~s(value="2")
    assert fourth =~ ~s(value="")
    assert html =~ ~r/<input[^>]*type="hidden"[^>]*name="code"[^>]*value="482"/
    refute Enum.any?(boxes(html), &(&1 =~ "name="))
  end

  test "a separator sits after the number of boxes asked for, and the caller can draw it" do
    html = render_otp(%{separator_after: 3})

    assert html =~ ~r/aria-hidden="true"[^>]*>\s*–/
    assert length(Regex.scan(~r/text-muted-2/, html)) == 1
    refute render_otp() =~ "text-muted-2"
  end

  test "letters are taken when the code is not numeric" do
    html = render_otp(%{numeric: false})

    assert html =~ ~s(data-numeric="false")
    assert html =~ ~s(inputmode="text")
    refute html =~ "pattern="
  end

  test "an error marks the boxes invalid and announces the helper as an alert" do
    html = render_otp(%{status: :error, helper: "Wrong code. 2 tries left."})

    assert html =~ ~s(data-status="error")
    assert Enum.all?(boxes(html), &(&1 =~ ~s(aria-invalid="true")))
    assert html =~ "text-tag-risk-text"
    assert html =~ ~r/<p[^>]*role="alert"[^>]*>\s*Wrong code/
    assert Enum.all?(boxes(html), &(&1 =~ ~s(aria-describedby="otp-helper")))
  end

  test "a right code turns the boxes green and the helper is a status" do
    html = render_otp(%{status: :ok, helper: "Verified"})

    assert html =~ "border-ok-fg"
    assert html =~ ~r/<p[^>]*role="status"/
    refute html =~ "aria-invalid"
  end

  test "an idle box has a quiet border that gets stronger when filled and takes the ink when focused" do
    html = render_otp()

    assert html =~ "border-line"
    assert html =~ "not-placeholder-shown:border-muted-2"
    assert html =~ "focus:border-ink"
    assert html =~ "focus:ring-ink/10"
    assert html =~ "motion-reduce:transition-none"
  end

  test "the resend line is the caller's slot and the helper is optional" do
    html = render_otp(%{resend: true, helper: "2 digits to go"})

    assert html =~ "Did not arrive?"
    assert html =~ "Resend in 0:24"
    assert html =~ "2 digits to go"
    refute render_otp() =~ "<p"
    refute render_otp() =~ "Resend"
  end

  test "no hex colours: the states are tokens" do
    refute render_otp(%{status: :error}) =~ ~r/#[0-9A-Fa-f]{6}/
    assert File.read!("assets/css/devaction_ui.css") =~ "--field-error-fill: light-dark("
  end
end
