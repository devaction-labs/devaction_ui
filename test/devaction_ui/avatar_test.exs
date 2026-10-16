defmodule DevactionUI.AvatarTest do
  @moduledoc "The avatar in its sizes, its shapes, with a status, the agent, the group with +N and the invite slot."
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.Avatar

  test "the letters come from the first and the last word" do
    assert Avatar.initials("Carlos André Souza") == "CS"
    assert Avatar.initials("alex") == "AL"
    assert Avatar.initials("") == ""
  end

  test "an avatar is read out by name and shows its letters" do
    assigns = %{}
    html = rendered_to_string(~H|<Avatar.avatar name="Carlos André" />|)

    assert html =~ ~s(title="Carlos André")
    assert html =~ "sr-only"
    assert html =~ ">CA<"
    assert html =~ "rounded-full"
    refute html =~ "data-status"
  end

  test "has five sizes and a square shape for what is not a person" do
    assigns = %{}

    for {size, expected} <- [
          xs: "size-[22px] text-[9px]",
          sm: "size-8 text-[11px]",
          md: "size-10 text-xs",
          lg: "size-14",
          xl: "size-[72px] text-xl"
        ] do
      assert rendered_to_string(~H|<Avatar.avatar name="A B" size={size} />|) =~ expected
    end

    small = rendered_to_string(~H|<Avatar.avatar name="W" shape={:square} size={:sm} />|)
    middle = rendered_to_string(~H|<Avatar.avatar name="W" shape={:square} />|)
    large = rendered_to_string(~H|<Avatar.avatar name="W" shape={:square} size={:xl} />|)

    assert small =~ "rounded-md"
    assert middle =~ "rounded-[11px]"
    assert large =~ "rounded-[14px]"
    refute middle =~ "rounded-full"
  end

  test "a status is a coloured dot and is also read out" do
    assigns = %{}

    for {status, color} <- [
          online: "bg-tag-ok-text",
          away: "bg-ai",
          busy: "bg-missing",
          offline: "bg-muted-2"
        ] do
      html =
        rendered_to_string(~H|<Avatar.avatar name="A B" status={status} status_label="Here" />|)

      assert html =~ ~s(data-status="#{status}")
      assert html =~ color
      assert html =~ "Here"
    end

    assert rendered_to_string(~H|<Avatar.avatar name="A B" status={:busy} />|) =~ "busy"

    assert rendered_to_string(~H|<Avatar.avatar name="A B" size={:xs} status={:online} />|) =~
             "size-2.5"

    assert rendered_to_string(~H|<Avatar.avatar name="A B" size={:xl} status={:online} />|) =~
             "size-3.5"
  end

  test "the agent is amber, has its own mark and a name for assistive technology" do
    assigns = %{}

    html =
      rendered_to_string(~H|<Avatar.agent name="DevAction IA" size={:lg}>MARK</Avatar.agent>|)

    assert html =~ "border-[1.5px] border-ai"
    assert html =~ "MARK"
    assert html =~ "DevAction IA"
    assert html =~ "size-14"
    assert html =~ "size-[45%]"
  end

  test "the invite slot is a button with a name" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<Avatar.avatar_invite label="Invite" phx-click="x">+</Avatar.avatar_invite>|
      )

    assert html =~ ~s(aria-label="Invite")
    assert html =~ "border-[1.5px] border-dashed border-muted-2"
    assert html =~ "text-muted"
    refute html =~ "bg-card"
    assert html =~ "size-[45%]"
    assert html =~ ~s(type="button")
    assert html =~ ~s(phx-click="x")
  end

  test "a group overlaps its people, shows +N for the rest and takes an extra at the end" do
    assigns = %{
      people: [
        %{name: "A One"},
        %{name: "B Two", tone: :ok},
        %{name: "C Three"},
        %{name: "D Four"}
      ]
    }

    html =
      rendered_to_string(~H"""
      <Avatar.avatar_stack label="Members" people={@people} max={2} size={:lg}>
        <:extra>EXTRA</:extra>
      </Avatar.avatar_stack>
      """)

    assert html =~ ~s(role="group")
    assert html =~ ~s(aria-label="Members")
    assert html =~ ~s(data-more="2")
    assert html =~ "+2"
    assert html =~ "-ml-2"
    assert html =~ "EXTRA"
    refute html =~ ">CT<"

    all = rendered_to_string(~H|<Avatar.avatar_stack label="M" people={@people} />|)
    refute all =~ "data-more"
    assert all =~ ">DF<"

    enough = rendered_to_string(~H|<Avatar.avatar_stack label="M" people={@people} max={9} />|)
    refute enough =~ "data-more"
  end

  test "a lone avatar takes its border from the tone and no card ring" do
    assigns = %{}
    html = rendered_to_string(~H|<Avatar.avatar name="A B" tone={:ok} />|)

    assert html =~ "border-tag-ok-line"
    refute html =~ "border-card"
  end

  test "a person in a stack has the card ring and only the tone's fill" do
    assigns = %{people: [%{name: "A One", tone: :ok}]}
    html = rendered_to_string(~H|<Avatar.avatar_stack label="M" people={@people} />|)

    assert html =~ "border-2 border-card"
    assert html =~ "bg-tag-ok-bg"
    refute html =~ "border-tag-ok-line"
  end

  test "a stack is 32px by default" do
    assigns = %{people: [%{name: "A One"}]}
    assert rendered_to_string(~H|<Avatar.avatar_stack label="M" people={@people} />|) =~ "size-8"
  end

  test "the square sets its letters in the semibold sans and the round in the mono" do
    assigns = %{}
    square = rendered_to_string(~H|<Avatar.avatar name="Work Space" shape={:square} />|)
    round = rendered_to_string(~H|<Avatar.avatar name="Work Space" />|)

    assert square =~ "font-sans font-semibold"
    refute square =~ "font-mono"
    assert round =~ "font-mono"
  end

  test "the icon slot replaces the letters" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Avatar.avatar name="sge-api" shape={:square}>
        <:icon>MARK</:icon>
      </Avatar.avatar>
      """)

    assert html =~ "MARK"
    refute html =~ ">SA<"
    assert html =~ "sge-api"
  end

  test "the status dot is an image with its label" do
    assigns = %{}

    html =
      rendered_to_string(~H|<Avatar.avatar name="A B" status={:online} status_label="Online" />|)

    assert html =~ ~s(role="img")
    assert html =~ ~s(aria-label="Online")
  end

  test "the auto tone gives the same name the same palette colour every time" do
    assigns = %{}
    first = rendered_to_string(~H|<Avatar.avatar name="Carlos André" tone={:auto} />|)
    again = rendered_to_string(~H|<Avatar.avatar name="Carlos André" tone={:auto} />|)

    assert first == again
    assert first =~ ~r/bg-avatar-(indigo|green|red|gray)-bg/
    assert first =~ ~r/text-avatar-(indigo|green|red|gray)-fg/
    assert first =~ "border-transparent"
    refute first =~ "bg-tag-"
  end

  test "the auto tone uses all four colours across different names" do
    colors =
      for name <- ~w(Ana Bruno Carla Diego Elisa Fabio Gina Hugo Iris Joao Kátia Luis Maria Nuno),
          into: MapSet.new() do
        assigns = %{name: name}
        html = rendered_to_string(~H|<Avatar.avatar name={@name} tone={:auto} />|)
        [_all, color] = Regex.run(~r/bg-avatar-(\w+)-bg/, html)
        color
      end

    assert colors == MapSet.new(~w(indigo green red gray))
  end

  test "the auto tone also works in a stack, with the card ring" do
    assigns = %{people: [%{name: "Ana Lima", tone: :auto}]}
    html = rendered_to_string(~H|<Avatar.avatar_stack label="M" people={@people} />|)

    assert html =~ "border-2 border-card"
    assert html =~ ~r/bg-avatar-\w+-bg/
  end

  test "the group overlaps rounded squares, with status dots and a caption" do
    assigns = %{
      people: [
        %{name: "Ana Nogueira", tone: :ink, status: :online, status_label: "online"},
        %{name: "Carlos Andre", tone: :info, status: :online},
        %{name: "Fernando Pinto", tone: :warn}
      ]
    }

    html =
      rendered_to_string(~H"""
      <Avatar.group people={@people} label="SGE team">
        <:caption>SGE team, 2 online</:caption>
      </Avatar.group>
      """)

    assert html =~ ~s(role="group" aria-label="SGE team")
    assert html =~ "size-9"
    assert html =~ "rounded-[11px]"
    assert html =~ "bg-ink text-card"
    assert html =~ "bg-tag-info-bg"
    assert html =~ "-ml-[9px]"
    assert length(Regex.scan(~r/data-status=/, html)) == 2
    assert html =~ ~s(aria-label="online")
    assert html =~ ~s(aria-label="online")
    assert html =~ ">AN<"
    assert html =~ "SGE team, 2 online"
    refute html =~ "data-more"
  end

  test "the group folds the people past max into a +N chip and has three sizes" do
    assigns = %{people: for(name <- ~w(Ana Bia Caio Dani Edu Fabi), do: %{name: name})}

    for {size, shape, overlap} <- [
          {:md, "rounded-[11px]", "-ml-[9px]"},
          {:sm, "rounded-[9px]", "-ml-[7px]"},
          {:xs, "rounded-[7px]", "-ml-1.5"}
        ] do
      html =
        rendered_to_string(
          ~H|<Avatar.group people={@people} label="Reviewers" max={3} size={size} />|
        )

      assert html =~ shape
      assert html =~ overlap
      assert html =~ ~s(data-more="3")
      assert html =~ "+3"
      assert length(Regex.scan(~r/data-person/, html)) == 3
    end
  end

  test "the group can be round" do
    assigns = %{people: [%{name: "Ana Lima", tone: :auto}]}
    html = rendered_to_string(~H|<Avatar.group people={@people} label="M" shape={:round} />|)

    assert html =~ "rounded-full"
    assert html =~ ~r/bg-avatar-\w+-bg/
  end
end
