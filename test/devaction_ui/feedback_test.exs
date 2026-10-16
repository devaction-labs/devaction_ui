defmodule DevactionUI.FeedbackTest do
  @moduledoc "The tones and the feedback components: alert, badge, tag, callout, progress, spinner, skeleton, empty state."
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.{
    Alert,
    Badge,
    Callout,
    EmptyState,
    Progress,
    ProgressToast,
    Skeleton,
    Spinner,
    Tag,
    Tone
  }

  @tones [:risk, :warn, :ok, :info, :neutral, :indigo, :emerald]

  describe "Tone" do
    test "every tone has a strong text from its own token" do
      for tone <- @tones, do: assert(Tone.strong(tone) == "text-tag-#{tone}-strong")
    end

    test "kinds outside the union are not a tone" do
      assert_raise FunctionClauseError, fn -> apply(Tone, :from_kind, [:nope]) end
    end
  end

  describe "Alert" do
    for kind <- [:ok, :ai, :info, :warn, :risk, :neutral] do
      test "#{kind} renders in the strong text of its tone" do
        assigns = %{kind: unquote(kind)}
        html = rendered_to_string(~H|<Alert.alert kind={@kind} title="T">Body</Alert.alert>|)
        tone = Tone.from_kind(unquote(kind))

        assert html =~ Tone.strong(tone)
        assert html =~ Tone.surface(tone)
        assert html =~ "leading-[1.45]"
      end
    end

    test "the body is optional" do
      assigns = %{}
      refute rendered_to_string(~H|<Alert.alert title="T" />|) =~ "<div>"
    end
  end

  describe "Badge" do
    test "the count is semibold with 7px of padding, and the dot pulses on its own keyframes" do
      assigns = %{}
      html = rendered_to_string(~H|<Badge.count value={3} />|)
      assert html =~ "px-[7px]"
      assert html =~ "font-semibold"

      dot = rendered_to_string(~H|<Badge.dot pulse />|)
      assert dot =~ "animate-pulse-dot"
      refute dot =~ "animate-pulse "
    end
  end

  describe "Tag" do
    test "the extra small size is the 10px tag" do
      assigns = %{}
      html = rendered_to_string(~H|<Tag.tag size={:xs}>4</Tag.tag>|)
      assert html =~ "px-[7px] py-[3px] text-[10px]"
    end

    for variant <- @tones do
      test "#{variant} on a plain surface keeps its border and text and takes the card's background" do
        assigns = %{variant: unquote(variant)}
        html = rendered_to_string(~H|<Tag.tag variant={@variant} surface={:plain}>x</Tag.tag>|)

        assert html =~
                 "border-tag-#{unquote(variant)}-line bg-card text-tag-#{unquote(variant)}-text"
      end
    end
  end

  describe "Callout" do
    test "the role follows the kind, and an explicit role wins" do
      for {kind, role} <- [
            risk: "alert",
            warn: "alert",
            warning: "alert",
            note: "status",
            ai: "status",
            ok: "status"
          ] do
        assigns = %{kind: kind}

        assert rendered_to_string(~H|<Callout.callout kind={@kind}>x</Callout.callout>|) =~
                 ~s(role="#{role}")
      end

      assigns = %{}

      assert rendered_to_string(
               ~H|<Callout.callout kind={:risk} role="status">x</Callout.callout>|
             ) =~ ~s(role="status")
    end

    test "is 14px round, spaced by 10px, with the strong text of its tone" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Callout.callout kind={:ok} title="T">
          x<:actions>A</:actions>
        </Callout.callout>
        """)

      assert html =~ "rounded-[14px]"
      assert html =~ "gap-2.5"
      assert html =~ Tone.strong(:ok)
      refute html =~ "pt-1"
    end
  end

  describe "Progress" do
    test "the value label is the text of the value, read as aria-valuetext" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<Progress.progress label="Steps" value={60} value_label="3 of 5" show_value />|
        )

      assert html =~ ~s(aria-valuetext="3 of 5")
      assert html =~ ">3 of 5<"
      refute html =~ ~r/>\s*60%\s*</
    end

    test "without a value label the value shows as a percentage" do
      assigns = %{}
      html = rendered_to_string(~H|<Progress.progress label="Steps" value={60} show_value />|)
      assert html =~ ">60%<"
      refute html =~ "aria-valuetext"
    end

    test "the size sets the thickness of a bar and of a segmented one" do
      assigns = %{}
      assert rendered_to_string(~H|<Progress.progress label="L" />|) =~ "h-1.5"
      assert rendered_to_string(~H|<Progress.progress label="L" size={:lg} />|) =~ "h-2"
      assert rendered_to_string(~H|<Progress.progress label="L" variant={:segmented} />|) =~ "h-2"

      assert rendered_to_string(
               ~H|<Progress.progress label="L" variant={:segmented} size={:md} />|
             ) =~ "h-1.5"
    end

    test "the segmented one has five pieces by default" do
      assigns = %{}

      html =
        rendered_to_string(~H|<Progress.progress label="L" variant={:segmented} value={40} />|)

      assert length(Regex.scan(~r/data-filled=/, html)) == 5
    end

    test "parts draw one bar in chunks, and their sum is the value" do
      assigns = %{parts: [%{value: 40, tone: :ok}, %{value: 20, tone: :warn}]}
      html = rendered_to_string(~H|<Progress.progress label="L" parts={@parts} />|)

      assert html =~ ~s(aria-valuenow="60")
      assert html =~ "width: 40%"
      assert html =~ "width: 20%"
      assert html =~ Tone.fill(:ok)
      assert html =~ Tone.fill(:warn)
    end
  end

  describe "ProgressToast" do
    defp toast(assigns) do
      ~H"""
      <ProgressToast.progress_toast
        id="t"
        state={@state}
        progress={100}
        title="Review"
        on_dismiss="dismiss"
        dismiss_label="Close"
        percent_label={assigns[:percent_label]}
      >
        <:icon :let={state}>icon-{state}</:icon>
        <:action><button>Try again</button></:action>
        Detail
      </ProgressToast.progress_toast>
      """
    end

    test "done takes its tone from the done state and shows no retry" do
      html = rendered_to_string(toast(%{state: :done}))

      assert html =~ ~s(data-state="done")
      assert html =~ ~s(role="status")
      assert html =~ "border-tag-ok-line"
      assert html =~ "icon-done"
      assert html =~ "shadow-toast-progress"
      refute html =~ "Try again"
    end

    test "error is an alert and offers its action" do
      html = rendered_to_string(toast(%{state: :error}))

      assert html =~ ~s(data-state="error")
      assert html =~ ~s(role="alert")
      assert html =~ "border-tag-risk-line"
      assert html =~ "icon-error"
      assert html =~ "Try again"
    end

    test "the title and the percentage are semibold and the percentage text can be given" do
      html = rendered_to_string(toast(%{state: :done, percent_label: "done"}))

      assert html =~ ~r/font-semibold">Review</
      assert html =~ ~r/font-medium text-tag-ok-text">\s*done\s*</
      refute html =~ ~r/>\s*100%\s*</
    end
  end

  describe "Spinner" do
    test "turns in 0.8 s, in two sizes and in the tone of the arc" do
      assigns = %{}
      html = rendered_to_string(~H|<Spinner.spinner label="L" />|)
      assert html =~ "animate-spin-fast"
      assert html =~ "size-[22px]"
      assert html =~ "border-t-ink"

      small = rendered_to_string(~H|<Spinner.spinner label="L" size={:sm} tone={:warn} />|)
      assert small =~ "size-4"
      assert small =~ "border-t-ai"
    end
  end

  describe "Skeleton" do
    test "the shapes follow the canvas" do
      assigns = %{}

      assert rendered_to_string(~H|<Skeleton.skeleton shape={:block} />|) =~
               "h-10 w-full rounded-[10px]"

      assert rendered_to_string(~H|<Skeleton.skeleton shape={:circle} />|) =~ "size-9"
    end

    test "can be still" do
      assigns = %{}
      html = rendered_to_string(~H|<Skeleton.skeleton animate={false} />|)
      refute html =~ "animate-shimmer"
      assert html =~ "bg-line-soft"
    end

    test "a group is one busy status with a name" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Skeleton.skeleton_group label="Loading"><Skeleton.skeleton /></Skeleton.skeleton_group>
        """)

      assert html =~ ~s(role="status")
      assert html =~ ~s(aria-busy="true")
      assert html =~ ~s(aria-label="Loading")
    end
  end

  describe "EmptyState" do
    test "the title is a heading of the level asked" do
      for level <- [2, 3, 6], variant <- [:page, :dashed] do
        assigns = %{level: level, variant: variant}

        assert rendered_to_string(
                 ~H|<EmptyState.empty_state variant={@variant} heading_level={@level} title="T" />|
               ) =~ ~r/<h#{level}[ >]/
      end

      assigns = %{}
      assert rendered_to_string(~H|<EmptyState.empty_state title="T" />|) =~ "<h2"
    end

    test "the page icon takes the tone and the dashed border its token" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <EmptyState.empty_state variant={:page} tone={:warn} title="T">
          <:icon>I</:icon>
        </EmptyState.empty_state>
        """)

      assert html =~ Tone.surface(:warn)
      assert html =~ "tracking-[-0.01em]"

      assert rendered_to_string(~H|<EmptyState.empty_state title="T" />|) =~ "border-line-dashed"
    end

    test "the inline ok and risk are a row with the action on the right" do
      for tone <- [:ok, :risk] do
        assigns = %{tone: tone}

        html =
          rendered_to_string(~H"""
          <EmptyState.empty_state variant={:inline} tone={@tone} title="Failed" text="Why">
            <:icon>I</:icon>
            <:action>RETRY</:action>
          </EmptyState.empty_state>
          """)

        assert html =~ Tone.surface(tone)
        assert html =~ Tone.strong(tone)
        assert html =~ "items-center gap-3"
        assert html =~ "RETRY"
        assert html =~ "aria-live"
      end
    end

    test "the inline neutral is the dashed box and announces itself" do
      assigns = %{}
      html = rendered_to_string(~H|<EmptyState.empty_state variant={:inline} title="Nothing" />|)
      assert html =~ "empty-inline"
      assert html =~ ~s(aria-live="polite")
    end
  end
end
