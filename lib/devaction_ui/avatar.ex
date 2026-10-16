defmodule DevactionUI.Avatar do
  @moduledoc """
  A person as two letters in a circle, and the stack of them overlapping by 8px. The letters come from the
  name (`initials/1`); the tone only tells people apart, it never carries meaning, and `tone: :auto` picks one
  of four colours (indigo, green, red, gray) from a stable hash of the name, so the same person always has the
  same colour. A circle with no name is decoration, so a stack names its people for assistive technology
  once, as a group.

  Around it: five sizes (`:xs` to `:xl`), a square shape for what is not a person (a workspace, a repository, a
  client), a status dot (online, away, busy, offline), the AI agent (`agent/1`, amber, with its own mark) and
  the invite slot (`avatar_invite/1`). A status is never alone: it is also read out. `group/1` is the canvas's
  overlapped group: rounded squares in three sizes, status dots, a `+N` chip and a caption beside.
  """
  use Phoenix.Component

  alias DevactionUI.Tone

  @doc "Up to two capital letters: the first of the first and of the last word."
  @spec initials(String.t()) :: String.t()
  def initials(name) do
    name |> String.split() |> pick() |> String.upcase()
  end

  defp pick([]), do: ""
  defp pick([only]), do: String.slice(only, 0, 2)
  defp pick([first | rest]), do: String.first(first) <> String.first(List.last(rest))

  attr :name, :string,
    required: true,
    doc: "the person (or the workspace); the letters come from it"

  attr :tone, :atom,
    values: [:auto, :ok, :warn, :risk, :info, :neutral],
    default: :neutral,
    doc: "`:auto` takes one of four colours from a stable hash of the name"

  attr :size, :atom,
    values: [:xs, :sm, :md, :lg, :xl],
    default: :md,
    doc: "22 (for stacks), 32, 40 (default), 56 and 72 px, with letters of 9, 11, 12, 16 and 20px"

  attr :shape, :atom,
    values: [:round, :square],
    default: :round,
    doc:
      "square is for a workspace, a repository, a client; it sets its letters in the sans, semibold"

  attr :status, :atom, values: [nil, :online, :away, :busy, :offline], default: nil
  attr :status_label, :string, default: nil, doc: "what the status says, read by screen readers"

  attr :ring, :boolean,
    default: false,
    doc:
      "the 2px ring of the card colour that separates avatars in a stack, instead of the tone's line"

  attr :class, :any, default: nil
  attr :rest, :global
  slot :icon, doc: "replaces the letters, such as the mark of a repository"

  @doc "A person as their initials, or an icon, in a circle or a square."
  @spec avatar(map()) :: Phoenix.LiveView.Rendered.t()
  def avatar(assigns) do
    ~H"""
    <span
      title={@name}
      class={[
        "relative inline-flex shrink-0 items-center justify-center",
        shape_class(@shape, @size),
        size_class(@size),
        edge_class(@ring, @tone, @name),
        text_class(@tone, @name),
        @class
      ]}
      {@rest}
    >
      <span :if={@icon != []} aria-hidden="true" class="size-[45%] [&>*]:size-full">
        {render_slot(@icon)}
      </span>
      <span :if={@icon == []} aria-hidden="true">{initials(@name)}</span><span class="sr-only">{@name}</span>
      <.status_dot :if={@status} status={@status} label={@status_label} size={@size} />
    </span>
    """
  end

  attr :name, :string, required: true, doc: "the agent's name, read out"
  attr :size, :atom, values: [:xs, :sm, :md, :lg, :xl], default: :md
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true, doc: "the mark of the agent, an icon"

  @doc "The AI agent: amber, with its own mark instead of letters."
  @spec agent(map()) :: Phoenix.LiveView.Rendered.t()
  def agent(assigns) do
    ~H"""
    <span
      title={@name}
      class={[
        "inline-flex shrink-0 items-center justify-center rounded-full border-[1.5px] border-ai bg-tag-warn-bg text-tag-warn-text",
        size_class(@size),
        @class
      ]}
      {@rest}
    >
      <span aria-hidden="true" class="size-[45%] [&>*]:size-full">{render_slot(@inner_block)}</span>
      <span class="sr-only">{@name}</span>
    </span>
    """
  end

  attr :label, :string, required: true, doc: "what pressing it does: `Invite a person`"
  attr :size, :atom, values: [:xs, :sm, :md, :lg, :xl], default: :md
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true, doc: "a plus icon"

  @doc "The empty place at the end of a group, to invite someone."
  @spec avatar_invite(map()) :: Phoenix.LiveView.Rendered.t()
  def avatar_invite(assigns) do
    ~H"""
    <button
      type="button"
      aria-label={@label}
      class={[
        "inline-flex shrink-0 items-center justify-center rounded-full border-[1.5px] border-dashed border-muted-2 text-muted outline-none hover:border-ink hover:text-ink focus-visible:ring-4 focus-visible:ring-ink/10",
        size_class(@size),
        @class
      ]}
      {@rest}
    >
      <span class="size-[45%] [&>*]:size-full" aria-hidden="true">{render_slot(@inner_block)}</span>
    </button>
    """
  end

  attr :status, :atom, required: true
  attr :label, :string, default: nil
  attr :size, :atom, required: true

  defp status_dot(assigns) do
    ~H"""
    <span
      data-status={@status}
      role="img"
      aria-label={@label || to_string(@status)}
      class={[
        "absolute -right-px -bottom-px rounded-full border-2 border-card",
        dot_size(@size),
        dot_color(@status)
      ]}
    />
    """
  end

  defp dot_size(size) when size in [:xs, :sm], do: "size-2.5"
  defp dot_size(:md), do: "size-3"
  defp dot_size(_large), do: "size-3.5"

  defp dot_color(:online), do: "bg-tag-ok-text"
  defp dot_color(:away), do: "bg-ai"
  defp dot_color(:busy), do: "bg-missing"
  defp dot_color(:offline), do: "bg-muted-2"

  defp shape_class(:round, _size), do: "rounded-full font-mono"

  defp shape_class(:square, size) when size in [:xs, :sm],
    do: "rounded-md font-sans font-semibold"

  defp shape_class(:square, :md), do: "rounded-[11px] font-sans font-semibold"
  defp shape_class(:square, _large), do: "rounded-[14px] font-sans font-semibold"

  defp edge_class(true, tone, name), do: ["border-2 border-card", tint(tone, name)]
  defp edge_class(false, tone, name), do: ["border", surface(tone, name)]

  defp surface(:auto, name), do: ["border-transparent", tint(:auto, name)]
  defp surface(tone, _name), do: Tone.surface(tone)

  defp text_class(:auto, name), do: name |> bucket() |> palette_text()
  defp text_class(tone, _name), do: Tone.text(tone)

  defp tint(:auto, name), do: name |> bucket() |> palette_fill()
  defp tint(:risk, _name), do: "bg-tag-risk-bg"
  defp tint(:warn, _name), do: "bg-tag-warn-bg"
  defp tint(:ok, _name), do: "bg-tag-ok-bg"
  defp tint(:info, _name), do: "bg-tag-info-bg"
  defp tint(:neutral, _name), do: "bg-tag-neutral-bg"

  defp bucket(name), do: :erlang.phash2(name, 4)

  defp palette_fill(0), do: "bg-avatar-indigo-bg"
  defp palette_fill(1), do: "bg-avatar-green-bg"
  defp palette_fill(2), do: "bg-avatar-red-bg"
  defp palette_fill(3), do: "bg-avatar-gray-bg"

  defp palette_text(0), do: "text-avatar-indigo-fg"
  defp palette_text(1), do: "text-avatar-green-fg"
  defp palette_text(2), do: "text-avatar-red-fg"
  defp palette_text(3), do: "text-avatar-gray-fg"

  defp size_class(:xs), do: "size-[22px] text-[9px]"
  defp size_class(:sm), do: "size-8 text-[11px]"
  defp size_class(:md), do: "size-10 text-xs"
  defp size_class(:lg), do: "size-14 text-base"
  defp size_class(:xl), do: "size-[72px] text-xl"

  attr :people, :list,
    required: true,
    doc: "`%{name: ..., tone: ...}` each (`tone` may be `:auto`), the first on top"

  attr :label, :string, required: true, doc: "what the group is, e.g. `Reviewers`"
  attr :max, :integer, default: nil, doc: "how many are drawn; the rest become a `+N` chip"
  attr :size, :atom, values: [:xs, :sm, :md, :lg, :xl], default: :sm
  attr :class, :any, default: nil
  attr :rest, :global
  slot :extra, doc: "after the people, such as an `avatar_invite/1`"

  @doc "The people overlapping by 8px, with a `+N` chip for those past `max`."
  @spec avatar_stack(map()) :: Phoenix.LiveView.Rendered.t()
  def avatar_stack(assigns) do
    {shown, hidden} = split(assigns.people, assigns.max)
    assigns = assign(assigns, shown: shown, hidden: hidden)

    ~H"""
    <span role="group" aria-label={@label} class={["inline-flex items-center", @class]} {@rest}>
      <.avatar
        :for={{person, index} <- Enum.with_index(@shown)}
        name={person.name}
        tone={Map.get(person, :tone, :neutral)}
        size={@size}
        ring
        class={index > 0 && "-ml-2"}
      />
      <span
        :if={@hidden > 0}
        data-more={@hidden}
        class={[
          "-ml-2 inline-flex shrink-0 items-center justify-center rounded-full border-2 border-card bg-wrap font-mono text-ink-2",
          size_class(@size)
        ]}
      >
        +{@hidden}
      </span>
      <span :for={extra <- @extra} class="-ml-2">{render_slot(extra)}</span>
    </span>
    """
  end

  attr :people, :list,
    required: true,
    doc:
      "`%{name: ..., tone: ..., status: ..., status_label: ...}` each, the first on top; `tone` is `:ink` (the solid ink of whoever is the subject), `:auto` or a `Tone`, `status` and `status_label` are optional"

  attr :label, :string, required: true, doc: "what the group is, read by assistive technology"
  attr :max, :integer, default: nil, doc: "how many are drawn; the rest become a `+N` chip"
  attr :size, :atom, values: [:xs, :sm, :md], default: :md, doc: "22, 28 and 36 px"

  attr :shape, :atom,
    values: [:square, :round],
    default: :square,
    doc: "the corners: rounded squares (the canvas's group) or circles"

  attr :class, :any, default: nil
  attr :rest, :global
  slot :caption, doc: "the text beside the avatars, such as `Review team, 2 online`"

  @doc "Avatars overlapping by a quarter of their size, with status dots, a `+N` chip and a caption beside."
  @spec group(map()) :: Phoenix.LiveView.Rendered.t()
  def group(assigns) do
    {shown, hidden} = split(assigns.people, assigns.max)
    assigns = assign(assigns, shown: shown, hidden: hidden)

    ~H"""
    <span class={["inline-flex items-center gap-3", @class]} {@rest}>
      <span role="group" aria-label={@label} class="flex">
        <span
          :for={{person, index} <- Enum.with_index(@shown)}
          data-person
          title={person.name}
          class={[
            "relative inline-flex shrink-0 items-center justify-center border-2 border-card font-sans font-semibold",
            group_size(@size),
            group_shape(@shape, @size),
            group_tone(Map.get(person, :tone, :neutral), person.name),
            index > 0 && group_overlap(@size)
          ]}
        >
          <span aria-hidden="true">{initials(person.name)}</span>
          <span class="sr-only">{person.name}</span>
          <span
            :if={Map.get(person, :status)}
            data-status={person.status}
            role="img"
            aria-label={Map.get(person, :status_label) || to_string(person.status)}
            class={[
              "absolute -right-0.5 -bottom-0.5 size-2.5 rounded-full border-2 border-card",
              dot_color(person.status)
            ]}
          />
        </span>
        <span
          :if={@hidden > 0}
          data-more={@hidden}
          class={[
            "relative inline-flex shrink-0 items-center justify-center border-2 border-card bg-wrap font-sans font-semibold text-ink-2",
            group_size(@size),
            group_shape(@shape, @size),
            group_overlap(@size)
          ]}
        >
          +{@hidden}
        </span>
      </span>
      <span :if={@caption != []} class="text-[13px] text-ink-2">{render_slot(@caption)}</span>
    </span>
    """
  end

  defp group_size(:xs), do: "size-[22px] text-[9px]"
  defp group_size(:sm), do: "size-7 text-[10px]"
  defp group_size(:md), do: "size-9 text-xs"

  defp group_shape(:round, _size), do: "rounded-full"
  defp group_shape(:square, :xs), do: "rounded-[7px]"
  defp group_shape(:square, :sm), do: "rounded-[9px]"
  defp group_shape(:square, :md), do: "rounded-[11px]"

  defp group_overlap(:xs), do: "-ml-1.5"
  defp group_overlap(:sm), do: "-ml-[7px]"
  defp group_overlap(:md), do: "-ml-[9px]"

  defp group_tone(:ink, _name), do: "bg-ink text-card"
  defp group_tone(:auto, name), do: [tint(:auto, name), text_class(:auto, name)]
  defp group_tone(tone, _name), do: [Tone.bg(tone), Tone.text(tone)]

  defp split(people, nil), do: {people, 0}
  defp split(people, max), do: {Enum.take(people, max), max(length(people) - max, 0)}
end
