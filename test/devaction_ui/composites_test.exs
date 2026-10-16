defmodule DevactionUI.CompositesTest do
  @moduledoc "The markup and the pure parts of the empty state, avatars, chat bubble, AI prompt, money input, dropdown and confirm dialog. Keys, focus and drops are checked in a browser through `/dev/ui`."
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.{
    AiPrompt,
    Avatar,
    ChatBubble,
    ConfirmDialog,
    Dropdown,
    EmptyState,
    MoneyInput
  }

  describe "Avatar.initials/1" do
    test "the first letter of the first and of the last word, in capitals" do
      assert Avatar.initials("Carlos André") == "CA"
      assert Avatar.initials("fernando de paiva") == "FP"
      assert Avatar.initials("Alex") == "AL"
      assert Avatar.initials("") == ""
    end
  end

  describe "avatar and avatar_stack" do
    test "an avatar shows the letters to the eye and the name to a screen reader" do
      assigns = %{}
      html = rendered_to_string(~H|<Avatar.avatar name="Carlos André" />|)
      assert html =~ ~s(aria-hidden="true">CA<)
      assert html =~ ~s(<span class="sr-only">Carlos André</span>)
    end

    test "a stack is one group, and only the people after the first overlap" do
      assigns = %{people: [%{name: "Ana Lima"}, %{name: "Bia Souza", tone: :ok}]}

      html =
        rendered_to_string(~H|<Avatar.avatar_stack label="Reviewers" people={@people} />|)

      assert html =~ ~s(role="group")
      assert html =~ ~s(aria-label="Reviewers")
      assert length(Regex.scan(~r/-ml-2/, html)) == 1
    end
  end

  describe "empty_state/1" do
    test "has the title, the text and the action, and no icon chip without an icon" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <EmptyState.empty_state title="Nothing yet" text="It will appear here.">
          <:action><a href="/x">Go</a></:action>
        </EmptyState.empty_state>
        """)

      assert html =~ "Nothing yet"
      assert html =~ "It will appear here."
      assert html =~ ~s(href="/x")
      refute html =~ "size-10"
    end
  end

  describe "chat_bubble/1" do
    test "the AI is on the left with its mark, the person on the right in ink" do
      assigns = %{}

      ai =
        rendered_to_string(~H"""
        <ChatBubble.chat_bubble from={:ai}>
          <:avatar><i class="mark" /></:avatar>Hi
        </ChatBubble.chat_bubble>
        """)

      me =
        rendered_to_string(~H|<ChatBubble.chat_bubble from={:me}>Hello</ChatBubble.chat_bubble>|)

      assert ai =~ "mark"
      assert ai =~ "bg-wrap"
      assert me =~ "justify-end"
      assert me =~ "bg-ink"
    end

    test "a message that did something is amber" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<ChatBubble.chat_bubble from={:ai} highlight>Done</ChatBubble.chat_bubble>|
        )

      assert html =~ "bg-tag-warn-bg"
    end
  end

  describe "ai_prompt/1" do
    test "is a form that sends the event, with a named field and a named button" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <AiPrompt.ai_prompt id="p" event="ask" label="Ask the AI" send_label="Send">
          <:icon>↑</:icon>
        </AiPrompt.ai_prompt>
        """)

      assert html =~ ~s(phx-submit="ask")
      assert html =~ ~s(for="p-input")
      assert html =~ ~s(aria-label="Send")
      assert html =~ ~s(name="prompt")
    end
  end

  describe "MoneyInput" do
    test "parse reads the cents from what is shown" do
      assert MoneyInput.parse("R$ 1.234,56") == {:ok, 123_456}
      assert MoneyInput.parse("R$ 0,05") == {:ok, 5}
      assert MoneyInput.parse("abc") == :error
      assert MoneyInput.parse("") == :error
      assert MoneyInput.parse(nil) == :error
    end

    test "the field carries the hook, and an error marks it invalid and is tied to it" do
      assigns = %{}

      ok = rendered_to_string(~H|<MoneyInput.money_input id="m" name="amount" label="Value" />|)
      assert ok =~ ~s(phx-hook="DevactionUI.MoneyMask")
      refute ok =~ "aria-invalid"

      bad =
        rendered_to_string(
          ~H|<MoneyInput.money_input id="m" name="amount" label="Value" errors={["Too low."]} />|
        )

      assert bad =~ ~s(aria-invalid="true")
      assert bad =~ ~s(aria-describedby="m-error")
      assert bad =~ "Too low."
    end
  end

  describe "dropdown/1" do
    setup do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Dropdown.dropdown id="d" label="Sort">
          <:trigger>Sort</:trigger>
          <:item event="order" value="a" checked={true}>A</:item>
          <:item event="order" value="b" checked={false}>B</:item>
          <:item event="export" separator shortcut="⌘E">Export</:item>
          <:item event="drop" danger>Archive</:item>
          <:item navigate="/somewhere">Go</:item>
        </Dropdown.dropdown>
        """)

      {:ok, html: html}
    end

    test "the menu starts closed and the button says it opens a menu", %{html: html} do
      assert html =~ ~s(aria-haspopup="menu")
      assert html =~ ~s(aria-expanded="false")
      assert html =~ ~r/role="menu"[^>]*hidden|hidden[^>]*role="menu"/
    end

    test "a choice is a radio item with its state, an action is a plain item", %{html: html} do
      assert length(Regex.scan(~r/role="menuitemradio"/, html)) == 2
      assert html =~ ~s(aria-checked="true")
      assert html =~ ~s(aria-checked="false")
      assert length(Regex.scan(~r/role="menuitem"/, html)) == 3
    end

    test "a choice has the 16px ring that fills when chosen, a separator and a shortcut are drawn, a link goes",
         %{html: html} do
      assert html =~ "group-aria-checked/item:border-[5px]"
      assert html =~ ~s(role="separator")
      assert html =~ "⌘E"
      assert html =~ ~s(href="/somewhere")
      assert html =~ "text-tag-risk-text"
    end

    test "the menu is 220px with the menu shadow and opens below", %{html: html} do
      assert html =~ "w-55"
      assert html =~ "shadow-menu"
      assert html =~ ~s(data-side="bottom")
      assert html =~ "h-[42px]"
    end

    defp render_dropdown(attrs) do
      assigns = %{attrs: attrs}

      rendered_to_string(~H"""
      <Dropdown.dropdown id="d" label="Menu" {@attrs}>
        <:trigger>Menu</:trigger>
        <:item event="a" heading="Group">A</:item>
        <:item event="b" disabled>B</:item>
        <:item patch="/p">P</:item>
        <:item href="https://example.com">H</:item>
      </Dropdown.dropdown>
      """)
    end

    test "the small button is 38px with radius 10 and align end puts the menu at the right" do
      html = render_dropdown(size: :sm, align: :end)
      assert html =~ "h-[38px]"
      assert html =~ "rounded-[10px]"
      assert html =~ "right-0"
    end

    test "the trigger can be an icon-only square with its own name and classes" do
      html = render_dropdown(variant: :icon, trigger_label: "More", trigger_class: "extra")
      assert html =~ ~s(aria-label="More")
      assert html =~ "size-[42px]"
      assert html =~ "extra"
      refute html =~ "border-line-strong px-3.5"
    end

    test "a heading captions the item, a disabled one is out of the keys, links go to patch and href" do
      html = render_dropdown([])
      assert html =~ ~r/role="presentation"[^>]*>\s*Group/
      assert html =~ ~r/aria-disabled="true"[^>]*disabled|disabled[^>]*aria-disabled="true"/
      assert html =~ ~s(data-phx-link="patch")
      assert html =~ ~s(href="https://example.com")
    end
  end

  describe "confirm_dialog/1" do
    test "is a modal dialog named by its title, with both buttons and a way out" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <ConfirmDialog.confirm_dialog id="c" title="Publish?" on_cancel="cancel" close_label="Close">
          <:close_icon>x</:close_icon>
          Ten comments.
          <:actions><button id="no">No</button><button id="yes">Yes</button></:actions>
        </ConfirmDialog.confirm_dialog>
        """)

      assert html =~ ~s(role="dialog")
      assert html =~ ~s(aria-modal="true")
      assert html =~ ~s(aria-labelledby="c-title")
      assert html =~ ~s(aria-label="Close")
      assert html =~ ~s(phx-key="escape")
      assert html =~ ~s(id="no") and html =~ ~s(id="yes")
    end
  end
end
