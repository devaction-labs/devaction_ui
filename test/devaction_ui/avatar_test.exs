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
          xs: "size-6",
          sm: "size-[22px]",
          md: "size-[34px]",
          lg: "size-14",
          xl: "size-[72px]"
        ] do
      assert rendered_to_string(~H|<Avatar.avatar name="A B" size={size} />|) =~ expected
    end

    small = rendered_to_string(~H|<Avatar.avatar name="W" shape={:square} size={:sm} />|)
    middle = rendered_to_string(~H|<Avatar.avatar name="W" shape={:square} />|)
    large = rendered_to_string(~H|<Avatar.avatar name="W" shape={:square} size={:xl} />|)

    assert small =~ "rounded-md"
    assert middle =~ "rounded-[10px]"
    assert large =~ "rounded-[14px]"
    refute middle =~ "rounded-full"
  end

  test "a status is a coloured dot and is also read out" do
    assigns = %{}

    for {status, color} <- [
          online: "bg-tag-ok-text",
          away: "bg-ai",
          busy: "bg-missing",
          offline: "bg-done-cell"
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

    html = rendered_to_string(~H|<Avatar.agent size={:lg}>MARK</Avatar.agent>|)

    assert html =~ "border-ai"
    assert html =~ "MARK"
    assert html =~ "DevAction IA"
    assert html =~ "size-14"
  end

  test "the invite slot is a button with a name" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<Avatar.avatar_invite label="Invite" phx-click="x">+</Avatar.avatar_invite>|
      )

    assert html =~ ~s(aria-label="Invite")
    assert html =~ "border-dashed"
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
end
