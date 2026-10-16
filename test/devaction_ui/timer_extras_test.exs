defmodule DevactionUI.TimerExtrasTest do
  @moduledoc "The mini timer of the app bar and the list of the time logged today."
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.Timer

  defp mini(base, started_at) do
    assigns = %{base: base, started_at: started_at}

    rendered_to_string(~H"""
    <Timer.timer_mini
      id="m"
      base={@base}
      started_at={@started_at}
      now={2000}
      label="Timer running"
    />
    """)
  end

  describe "timer_mini/1" do
    test "short time is hours and minutes" do
      assert Timer.format_short(0) == "00:00"
      assert Timer.format_short(2843) == "00:47"
      assert Timer.format_short(3725) == "01:02"
    end

    test "paused: a grey dot and the minutes of the base, with the same hook as the timer" do
      html = mini(2843, nil)

      assert html =~ ~s(phx-hook="DevactionUI.Timer")
      assert html =~ ~s(data-format="short")
      assert html =~ ~s(data-state="paused")
      assert html =~ ~s(data-running="false")
      assert html =~ "00:47"
      refute html =~ "00:47:"
      assert html =~ "bg-muted-2"
      assert html =~ ~s(aria-label="Timer running")
    end

    test "running: a green dot and the time since it started" do
      html = mini(60, 1000)

      assert html =~ ~s(data-state="running")
      assert html =~ ~s(data-started-at="1000")
      assert html =~ ~s(data-now="2000")
      assert html =~ "bg-ok-fg"
      assert html =~ "00:17"
    end

    test "the dot is 8px, hidden from assistive technology, and the time is mono 13px" do
      html = mini(0, nil)

      assert html =~ ~r/aria-hidden="true"[^>]*size-2|size-2[^>]*aria-hidden="true"/
      assert html =~ "font-mono text-[13px]"
      assert html =~ ~s(role="timer")
    end

    test "other attributes go to the box" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Timer.timer_mini id="m" base={0} label="Timer" phx-click="open" />
        """)

      assert html =~ ~s(phx-click="open")
    end
  end

  describe "time_log/1" do
    defp log(extra \\ %{}) do
      assigns =
        Map.merge(
          %{
            entries: [
              %{id: "a", label: "GraphQL contract routes", seconds: 4800},
              %{id: "b", label: "SGE daily", seconds: 1500}
            ],
            duration: nil
          },
          extra
        )

      rendered_to_string(~H"""
      <Timer.time_log id="log" title="LOGGED TODAY" entries={@entries} duration={@duration} />
      """)
    end

    test "is a titled list with a row per entry, the time in mono on the right" do
      html = log()

      assert html =~ ~s(aria-labelledby="log-title")
      assert html =~ ~r/<h4 id="log-title"[^>]*>\s*LOGGED TODAY/
      assert html =~ "uppercase"
      assert html =~ "tracking-[0.08em]"
      assert html =~ ~s(id="log-a")
      assert html =~ "GraphQL contract routes"
      assert html =~ "01:20"
      assert html =~ "00:25"
      assert html =~ "font-mono"
      assert length(Regex.scan(~r/<li /, html)) == 2
      assert html =~ "border-t border-line-soft"
    end

    test "the caller can write the time its own way" do
      html =
        log(%{
          duration: fn seconds -> "#{div(seconds, 3600)}h #{rem(div(seconds, 60), 60)}min" end
        })

      assert html =~ "1h 20min"
      assert html =~ "0h 25min"
    end

    test "no entries is only the title" do
      html = log(%{entries: []})

      assert html =~ "LOGGED TODAY"
      refute html =~ "<li"
    end
  end
end
