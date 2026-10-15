defmodule DevactionUI.Avatar do
  @moduledoc """
  A person as two letters in a circle, and the stack of them overlapping by 8px. The letters come from the
  name (`initials/1`); the tone only tells people apart, it never carries meaning. A circle with no name is
  decoration, so a stack names its people for assistive technology once, as a group.

  Around it: five sizes (`:xs` to `:xl`), a square shape for what is not a person (a workspace, a repository, a
  client), a status dot (online, away, busy, offline), the AI agent (`agent/1`, amber, with its own mark) and
  the invite slot (`avatar_invite/1`). A status is never alone: it is also read out.
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

  attr :name, :string, required: true
  attr :tone, :atom, values: [:ok, :warn, :risk, :info, :neutral], default: :neutral

  attr :size, :atom,
    values: [:xs, :sm, :md, :lg, :xl],
    default: :md,
    doc: "22, 34 (default), 24, 56 and 72 px"

  attr :shape, :atom,
    values: [:round, :square],
    default: :round,
    doc: "square is for a workspace, a repository, a client"

  attr :status, :atom, values: [nil, :online, :away, :busy, :offline], default: nil
  attr :status_label, :string, default: nil, doc: "what the status says, read by screen readers"
  attr :class, :any, default: nil
  attr :rest, :global

  def avatar(assigns) do
    ~H"""
    <span
      title={@name}
      class={[
        "relative inline-flex shrink-0 items-center justify-center border-2 border-card font-mono",
        shape_class(@shape, @size),
        size_class(@size),
        Tone.surface(@tone),
        Tone.text(@tone),
        @class
      ]}
      {@rest}
    >
      <span aria-hidden="true">{initials(@name)}</span><span class="sr-only">{@name}</span>
      <.status_dot :if={@status} status={@status} label={@status_label} size={@size} />
    </span>
    """
  end

  attr :name, :string, default: "DevAction IA"
  attr :size, :atom, values: [:xs, :sm, :md, :lg, :xl], default: :md
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true, doc: "the mark of the agent, an icon"

  @doc "The AI agent: amber, with its own mark instead of letters."
  def agent(assigns) do
    ~H"""
    <span
      title={@name}
      class={[
        "inline-flex shrink-0 items-center justify-center rounded-full border-2 border-ai bg-tag-warn-bg text-tag-warn-text",
        size_class(@size),
        @class
      ]}
      {@rest}
    >
      <span aria-hidden="true" class="size-1/2 [&>*]:size-full">{render_slot(@inner_block)}</span>
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
  def avatar_invite(assigns) do
    ~H"""
    <button
      type="button"
      aria-label={@label}
      class={[
        "inline-flex shrink-0 items-center justify-center rounded-full border-2 border-dashed border-line-strong bg-card text-muted outline-none hover:border-ink hover:text-ink focus-visible:ring-4 focus-visible:ring-ink/10",
        size_class(@size),
        @class
      ]}
      {@rest}
    >
      <span class="size-1/2 [&>*]:size-full" aria-hidden="true">{render_slot(@inner_block)}</span>
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
      class={[
        "absolute -right-px -bottom-px rounded-full border-2 border-card",
        dot_size(@size),
        dot_color(@status)
      ]}
    >
      <span class="sr-only">{@label || to_string(@status)}</span>
    </span>
    """
  end

  defp dot_size(size) when size in [:xs, :sm], do: "size-2.5"
  defp dot_size(:md), do: "size-3"
  defp dot_size(_large), do: "size-3.5"

  defp dot_color(:online), do: "bg-tag-ok-text"
  defp dot_color(:away), do: "bg-ai"
  defp dot_color(:busy), do: "bg-missing"
  defp dot_color(:offline), do: "bg-done-cell"

  defp shape_class(:round, _size), do: "rounded-full"
  defp shape_class(:square, size) when size in [:xs, :sm], do: "rounded-md"
  defp shape_class(:square, :md), do: "rounded-[10px]"
  defp shape_class(:square, _large), do: "rounded-[14px]"

  defp size_class(:xs), do: "size-6 text-[9px]"
  defp size_class(:sm), do: "size-[22px] text-[10px]"
  defp size_class(:md), do: "size-[34px] text-[11px]"
  defp size_class(:lg), do: "size-14 text-base"
  defp size_class(:xl), do: "size-[72px] text-xl"

  attr :people, :list, required: true, doc: "`%{name: ..., tone: ...}` each, the first on top"
  attr :label, :string, required: true, doc: "what the group is, e.g. `Reviewers`"
  attr :max, :integer, default: nil, doc: "how many are drawn; the rest become a `+N` chip"
  attr :size, :atom, values: [:xs, :sm, :md, :lg, :xl], default: :md
  attr :class, :any, default: nil
  attr :rest, :global
  slot :extra, doc: "after the people, such as an `avatar_invite/1`"

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

  defp split(people, nil), do: {people, 0}
  defp split(people, max), do: {Enum.take(people, max), max(length(people) - max, 0)}
end
