defmodule DevactionUI.FeedbackTonesTest do
  @moduledoc "The tints and series of Tone, and the second wave of the feedback components."
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
    ToastGroup,
    Tone
  }

  @tones [:risk, :warn, :ok, :info, :neutral]
  @tints [:indigo, :emerald]
  @series [:chart_1, :chart_2, :chart_3, :chart_4]

  describe "Tone, the tints and the series" do
    test "indigo and emerald have the whole set from their own tokens" do
      for tone <- @tints do
        assert Tone.from_kind(tone) == tone
        assert Tone.surface(tone) == "border-tag-#{tone}-line bg-tag-#{tone}-bg"
        assert Tone.text(tone) == "text-tag-#{tone}-text"
        assert Tone.strong(tone) == "text-tag-#{tone}-strong"
        assert Tone.bg(tone) == "bg-tag-#{tone}-bg"
        assert Tone.fill(tone) == "bg-tag-#{tone}-text"
        assert Tone.dot(tone) == "bg-dot-#{tone}"
      end
    end

    test "the dot is its own shade, apart from the fill of a bar" do
      for tone <- @tones ++ @tints do
        assert Tone.dot(tone) =~ "bg-dot-"
        refute Tone.dot(tone) == Tone.fill(tone)
      end

      assert Tone.dot(:ok) == "bg-dot-ok"
      assert Tone.fill(:ok) == "bg-tag-ok-text"
    end

    for tone <- @series, n = tone |> to_string() |> String.last() do
      test "#{tone} is drawn from the series color #{n}" do
        tone = unquote(tone)
        assert Tone.from_kind(tone) == tone
        assert Tone.text(tone) == "text-chart-#{unquote(n)}"
        assert Tone.strong(tone) == "text-chart-#{unquote(n)}"
        assert Tone.fill(tone) == "bg-chart-#{unquote(n)}"
        assert Tone.dot(tone) == "bg-chart-#{unquote(n)}"
        assert Tone.bg(tone) == "bg-chart-#{unquote(n)}/10"
        assert Tone.surface(tone) == "border-chart-#{unquote(n)}/30 bg-chart-#{unquote(n)}/10"
      end
    end

    test "every token they name is defined in the stylesheet" do
      css = File.read!(Path.expand("../../assets/css/devaction_ui.css", __DIR__))

      tokens =
        ~w(tag-indigo-line tag-indigo-bg tag-indigo-text tag-indigo-strong tag-emerald-line
           tag-emerald-bg tag-emerald-text tag-emerald-strong dot-ok dot-warn dot-risk dot-info
           dot-indigo dot-emerald dot-neutral shimmer chart-1 chart-2 chart-3 chart-4
           toast-layer-1 toast-layer-2)

      for token <- tokens do
        assert css =~ "--#{token}: light-dark("
        assert css =~ "--color-#{token}: var(--#{token});"
      end
    end

    test "the alert and the callout take a tint and a series kind" do
      for kind <- @tints ++ @series do
        assigns = %{kind: kind}

        assert rendered_to_string(~H|<Callout.callout kind={@kind}>x</Callout.callout>|) =~
                 Tone.surface(kind)
      end

      assigns = %{}

      assert rendered_to_string(~H|<Alert.alert kind={:indigo} title="T" />|) =~
               Tone.strong(:indigo)
    end
  end

  describe "Tag sizes and surfaces" do
    test "the four sizes are the paddings of the canvas" do
      for {size, classes} <- [
            xs: "px-[7px] py-[3px] text-[10px]",
            sm: "px-[7px] py-0.5 text-[11px]",
            md: "px-2 py-[3px] text-[11px]",
            lg: "px-[9px] py-1 text-xs"
          ] do
        assigns = %{size: size}
        assert rendered_to_string(~H|<Tag.tag size={@size}>x</Tag.tag>|) =~ classes
      end

      assigns = %{}
      assert rendered_to_string(~H|<Tag.tag>x</Tag.tag>|) =~ "px-2 py-[3px]"
    end

    for variant <- @tones ++ @tints do
      test "#{variant} soft is borderless on the grey with the text of its variant" do
        assigns = %{variant: unquote(variant)}
        html = rendered_to_string(~H|<Tag.tag variant={@variant} surface={:soft}>x</Tag.tag>|)

        assert html =~ "bg-tag-neutral-bg"
        assert html =~ "text-tag-#{unquote(variant)}-text"
        refute html =~ ~r/\bborder\b/
        refute html =~ "-line"
      end

      test "#{variant} flat is borderless in its own tint" do
        assigns = %{variant: unquote(variant)}
        html = rendered_to_string(~H|<Tag.tag variant={@variant} surface={:flat}>x</Tag.tag>|)

        assert html =~ "bg-tag-#{unquote(variant)}-bg text-tag-#{unquote(variant)}-text"
        refute html =~ ~r/\bborder\b/
      end

      test "#{variant} plain keeps its own border on the card" do
        assigns = %{variant: unquote(variant)}
        html = rendered_to_string(~H|<Tag.tag variant={@variant} surface={:plain}>x</Tag.tag>|)

        assert html =~
                 "border border-tag-#{unquote(variant)}-line bg-card text-tag-#{unquote(variant)}-text"
      end
    end

    test "the tinted one keeps its border" do
      assigns = %{}
      assert rendered_to_string(~H|<Tag.tag>x</Tag.tag>|) =~ ~r/\bborder\b/
    end
  end

  describe "Badge dot and chip" do
    for tone <- @tones ++ @tints do
      test "the #{tone} dot is drawn in its dot shade" do
        assigns = %{tone: unquote(tone)}
        assert rendered_to_string(~H|<Badge.dot tone={@tone} />|) =~ Tone.dot(unquote(tone))
      end
    end

    test "the dot without a label is decoration and with one is an image" do
      assigns = %{}
      assert rendered_to_string(~H|<Badge.dot />|) =~ ~s(aria-hidden="true")
      html = rendered_to_string(~H|<Badge.dot label="Connected" />|)
      assert html =~ ~s(role="img")
      assert html =~ ~s(aria-label="Connected")
    end

    test "the chip is a pill with a small avatar of initials and a name" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<Badge.chip initials="CA" class="extra" id="c">Carlos Andre</Badge.chip>|
        )

      assert html =~ "rounded-full bg-tag-neutral-bg"
      assert html =~ "pl-1 text-[13px]"
      assert html =~ "size-[22px]"
      assert html =~ Tone.bg(:indigo)
      assert html =~ Tone.text(:indigo)
      assert html =~ ~r/>\s*CA\s*</
      assert html =~ "Carlos Andre"
      assert html =~ "extra"
      assert html =~ ~s(id="c")
    end

    test "the chip takes another tint and an avatar from the caller" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Badge.chip tone={:emerald} initials="X">
          <:avatar><img src="/a.png" alt="" /></:avatar>
          Name
        </Badge.chip>
        """)

      assert html =~ Tone.bg(:emerald)
      assert html =~ ~s(src="/a.png")
      refute html =~ ~r/>\s*X\s*</
    end
  end

  describe "Callout icon and density" do
    defp icon_callout(assigns) do
      ~H"""
      <Callout.callout title={@title} icon_layout={@layout} compact={@compact}>
        <:icon><i class="the-icon" /></:icon>
        Body
      </Callout.callout>
      """
    end

    test "inline puts the 16px icon on the line of the title" do
      html = rendered_to_string(icon_callout(%{title: "T", layout: :inline, compact: false}))

      assert html =~ ~r/gap-2 font-semibold">\s*<span class="flex size-4/
      assert html =~ "flex-col gap-2.5"
      refute html =~ "size-8"
      assert html =~ "the-icon"
    end

    test "inline without a title puts the icon beside the body" do
      html = rendered_to_string(icon_callout(%{title: nil, layout: :inline, compact: false}))

      assert html =~ "mt-0.5 flex size-4"
      refute html =~ "font-semibold"
    end

    test "box is the 32px tile at the left of everything" do
      html = rendered_to_string(icon_callout(%{title: "T", layout: :box, compact: false}))

      assert html =~ "size-8"
      refute html =~ "size-4"
      refute html =~ "flex-col gap-2.5 rounded"
    end

    test "compact is tighter and smaller" do
      html = rendered_to_string(icon_callout(%{title: "T", layout: :inline, compact: true}))
      assert html =~ "p-3 text-[13px]"
      refute html =~ "p-[18px]"

      regular = rendered_to_string(icon_callout(%{title: "T", layout: :inline, compact: false}))
      assert regular =~ "p-[18px] text-sm"
    end

    test "without an icon neither layout draws one" do
      assigns = %{}
      html = rendered_to_string(~H|<Callout.callout title="T">x</Callout.callout>|)
      refute html =~ "size-4"
      refute html =~ "size-8"
    end
  end

  describe "Progress segments" do
    defp states(html), do: ~r/data-state="(\w+)"/ |> Regex.scan(html) |> Enum.map(&List.last/1)

    test "the current piece is drawn in its own tone, the ones before are done, the rest wait" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<Progress.progress label="L" variant={:segmented} current={3} tone={:neutral} />|
        )

      assert states(html) == ~w(done done current todo todo)
      assert html =~ Tone.fill(:warn)
      assert html =~ ~s(aria-valuenow="40")
    end

    test "the current tone can be changed" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<Progress.progress label="L" variant={:segmented} current={1} current_tone={:info} />|
        )

      assert states(html) == ~w(current todo todo todo todo)
      assert html =~ Tone.fill(:info)
    end

    test "each done piece can have its own tone" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Progress.progress
          label="L"
          variant={:segmented}
          value={60}
          segment_tones={[:ok, :risk]}
          tone={:neutral}
        />
        """)

      assert states(html) == ~w(done done done todo todo)
      [first, second, third] = Regex.scan(~r/data-state="done" class="([^"]*)"/, html)
      assert List.last(first) =~ Tone.fill(:ok)
      assert List.last(second) =~ Tone.fill(:risk)
      assert List.last(third) =~ Tone.fill(:neutral)
    end

    test "without a current piece the value fills them as before" do
      assigns = %{}

      html =
        rendered_to_string(~H|<Progress.progress label="L" variant={:segmented} value={40} />|)

      assert states(html) == ~w(done done todo todo todo)
    end

    test "the gap is 6px or 4px" do
      assigns = %{}

      assert rendered_to_string(~H|<Progress.progress label="L" variant={:segmented} />|) =~
               "gap-1.5"

      small =
        rendered_to_string(~H|<Progress.progress label="L" variant={:segmented} gap={:sm} />|)

      assert small =~ "gap-1"
      refute small =~ "gap-1.5"
    end
  end

  describe "ProgressToast variants" do
    defp variant_toast(assigns) do
      ~H"""
      <ProgressToast.progress_toast
        id="t"
        variant={@variant}
        state={@state}
        progress={@progress}
        aura={Map.get(assigns, :aura, true)}
        title="Upload"
        on_dismiss="dismiss"
        dismiss_label="Close"
      >
        <:icon :let={state}>icon-{state}</:icon>
        <:action><button>Cancel</button></:action>
        Detail
      </ProgressToast.progress_toast>
      """
    end

    test "fill draws the 34px tile for the icon in the tone of the state" do
      html = rendered_to_string(variant_toast(%{variant: :fill, state: :running, progress: 40}))

      assert html =~ "size-[34px]"
      assert html =~ "rounded-[10px] bg-tag-warn-bg text-tag-warn-text"
      assert html =~ "40%"
      assert html =~ "text-ink-2"
    end

    test "bar is the dark card with a 3px bar along its base and the action while it runs" do
      html = rendered_to_string(variant_toast(%{variant: :bar, state: :running, progress: 40}))

      assert html =~ "bg-ink text-on-primary"
      assert html =~ "h-[3px]"
      assert html =~ "width: 40%"
      assert html =~ "bg-ai"
      assert html =~ "Cancel"
      assert html =~ ~s(aria-valuenow="40")
    end

    test "bar drops the action once it is done and turns green" do
      html = rendered_to_string(variant_toast(%{variant: :bar, state: :done, progress: 100}))

      refute html =~ "Cancel"
      assert html =~ "bg-dot-ok"
    end

    test "steps counts the stages over segmented pieces" do
      html = rendered_to_string(variant_toast(%{variant: :steps, state: :running, progress: 60}))

      assert html =~ "3/5"
      assert html =~ ~s(role="progressbar")
      assert length(Regex.scan(~r/data-filled=/, html)) == 5
      assert length(Regex.scan(~r/data-filled="true"/, html)) == 3
    end

    test "the ring of light is on while it runs, and aura false turns it off" do
      running = rendered_to_string(variant_toast(%{variant: :fill, state: :running, progress: 1}))
      assert running =~ "aura"

      still =
        rendered_to_string(
          variant_toast(%{variant: :fill, state: :running, progress: 1, aura: false})
        )

      refute still =~ "aura"

      done = variant_toast(%{variant: :fill, state: :done, progress: 1})
      refute rendered_to_string(done) =~ "aura"

      steps = variant_toast(%{variant: :steps, state: :running, progress: 1})
      refute rendered_to_string(steps) =~ "aura"
    end

    test "the progress is clamped" do
      over = variant_toast(%{variant: :bar, state: :running, progress: 250})
      assert rendered_to_string(over) =~ "width: 100%"

      under = variant_toast(%{variant: :bar, state: :running, progress: -4})
      assert rendered_to_string(under) =~ "width: 0%"
    end

    test "a done one carries its state for the hook to leave, an error one is an alert" do
      done = rendered_to_string(variant_toast(%{variant: :fill, state: :done, progress: 100}))
      assert done =~ ~s(data-state="done")
      assert done =~ ~s(phx-hook="DevactionUI.ProgressToast")

      error = rendered_to_string(variant_toast(%{variant: :steps, state: :error, progress: 40}))
      assert error =~ ~s(role="alert")
      assert error =~ ~s(data-state="error")
    end
  end

  describe "ToastGroup stack and panel" do
    defp stack(assigns) do
      ~H"""
      <ToastGroup.toast_group
        id="tg"
        label="Notices"
        heading={Map.get(assigns, :heading)}
        on_dismiss="dismiss"
        on_clear="clear"
        expand_label="Show all"
        collapse_label="Collapse"
        clear_label="Clear"
        dismiss_label="Close"
        count_label="__COUNT__ notices"
      >
        <:toast id="a" title="First" dot={:warn}>Line</:toast>
        <:toast id="b" kind={:light} title="Second" dot={:ok} />
      </ToastGroup.toast_group>
      """
    end

    test "the pile is the toasts themselves, each placed by its position behind the front one" do
      html = rendered_to_string(stack(%{}))

      assert html =~ ~s(style="--i: 0")
      assert html =~ ~s(style="--i: 1")
      assert html =~ "calc(var(--i)*-10px)"
      assert html =~ "[z-index:calc(10-var(--i))]"
      refute html =~ "data-layer"
      refute html =~ "bg-toast-layer"
    end

    test "only the front toast is not behind, and the ones past the third are not drawn" do
      html = rendered_to_string(stack(%{}))

      assert length(Regex.scan(~r/ data-behind(?=[ >])/, html)) == 1
      refute html =~ "data-deep"
    end

    test "there is no count badge: the pile itself says there is more than one" do
      html = rendered_to_string(stack(%{}))
      refute html =~ "data-stack-count"
    end

    test "the button that opens the pile takes no room, so the layers end at the front toast" do
      html = rendered_to_string(stack(%{}))
      assert html =~ ~r/<button[^>]*data-expand[^>]*class="sr-only"/s
    end

    test "a toast can carry its dot, 10px and 8px when opened" do
      html = rendered_to_string(stack(%{}))

      assert html =~ "size-2.5"
      assert html =~ "group-data-[expanded=true]:size-2"
      assert html =~ Tone.dot(:warn)
      assert html =~ Tone.dot(:ok)
    end

    test "the heading goes to the hook for the panel's title" do
      assert rendered_to_string(stack(%{heading: "AI review"})) =~ ~s(data-heading="AI review")
      refute rendered_to_string(stack(%{})) =~ "data-heading"
    end

    test "the opened group is a panel and each toast a white card" do
      html = rendered_to_string(stack(%{}))

      assert html =~ "data-[expanded=true]:bg-wrap"
      assert html =~ "data-[expanded=true]:rounded-2xl"
      assert html =~ "group-data-[expanded=true]:bg-card"
      assert html =~ "group-data-[expanded=true]:rounded-xl"
    end

    test "the second line of a dark toast is the soft white" do
      assert rendered_to_string(stack(%{})) =~ "text-on-primary/70"
    end
  end

  describe "Spinner dots" do
    test "three dots pulse one after the other and are named once" do
      assigns = %{}
      html = rendered_to_string(~H|<Spinner.dots label="Writing" id="d" />|)

      assert length(Regex.scan(~r/animate-pulse-dot-fast/, html)) == 3
      assert html =~ "[animation-delay:0.2s]"
      assert html =~ "[animation-delay:0.4s]"
      assert html =~ "size-[7px]"
      assert html =~ ~s(role="status")
      assert html =~ ~r/sr-only">Writing</
      assert html =~ ~s(id="d")
    end

    test "they stand still under reduced motion and take a tone" do
      assigns = %{}
      html = rendered_to_string(~H|<Spinner.dots label="L" tone={:warn} />|)

      assert length(Regex.scan(~r/motion-reduce:animate-none/, html)) == 3
      assert html =~ "bg-ai"
    end
  end

  describe "Skeleton lines and shimmer" do
    test "a line is 14, 12 or 10px high" do
      for {size, height} <- [md: "h-3.5", sm: "h-3", xs: "h-2.5"] do
        assigns = %{size: size}
        assert rendered_to_string(~H|<Skeleton.skeleton size={@size} />|) =~ "#{height} w-full"
      end

      assigns = %{}
      assert rendered_to_string(~H|<Skeleton.skeleton />|) =~ "h-3.5 w-full rounded-md"
    end

    test "the size is only for lines" do
      assigns = %{}
      html = rendered_to_string(~H|<Skeleton.skeleton shape={:circle} size={:xs} />|)
      assert html =~ "size-9"
      refute html =~ "h-2.5"
    end

    test "the shimmer ends on its own token" do
      assigns = %{}
      html = rendered_to_string(~H|<Skeleton.skeleton />|)
      assert html =~ "var(--shimmer)"
      refute html =~ "var(--wrap)"
    end
  end

  describe "EmptyState measures" do
    test "the page text is 14px at 1.55 and the inline title 14px" do
      assigns = %{}

      page = rendered_to_string(~H|<EmptyState.empty_state variant={:page} title="T" text="x" />|)
      assert page =~ "leading-[1.55]"

      inline = rendered_to_string(~H|<EmptyState.empty_state variant={:inline} title="T" />|)
      assert inline =~ "text-sm font-medium"
    end
  end
end
