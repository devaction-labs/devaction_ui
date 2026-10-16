defmodule DevactionUI.Callout do
  @moduledoc """
  A tinted block that says something to the reader: a note, what the AI did, a tip, a warning, a decision.
  Color is never alone: it always carries a title or an `icon` slot, and an `:alert` role when it is urgent.

  `kind` is the canvas's name (`:note`, `:ai`, `:tip`, `:warning`, `:decision`) or a plain tone (`:risk`,
  `:warn`, `:ok`, `:info`, `:neutral`). With `title`, the title is bold on its own line; `actions` is a row
  for buttons under the body. The role follows the kind: `alert` for `:risk`, `:warn` and `:warning`,
  `status` for the rest; `role` overrides it.

  `icon_layout: :inline` (the canvas's) draws the icon, 16 px, on the line of the title, or beside the body when
  there is no title; `:box` puts it in a 32 px tile at the left of everything. `compact` is the tight one for
  a note inside a card or a form: less padding, a 13 px text.

  The boundary with `DevactionUI.Alert`: a callout is a block the reader acts on, with a longer body and
  `actions`; an alert is the one-line notice with no way out.
  """

  use Phoenix.Component

  alias DevactionUI.Tone

  attr :kind, :atom,
    values: [
      :note,
      :ai,
      :tip,
      :warning,
      :decision,
      :risk,
      :warn,
      :ok,
      :info,
      :neutral,
      :indigo,
      :emerald,
      :chart_1,
      :chart_2,
      :chart_3,
      :chart_4
    ],
    default: :note,
    doc: "the canvas's name for what it says, or a plain tone"

  attr :title, :string, default: nil, doc: "the bold first line"

  attr :icon_layout, :atom,
    values: [:inline, :box],
    default: :inline,
    doc: "`:inline` the icon on the line of the title, `:box` a tile at the left of the body"

  attr :compact, :boolean, default: false, doc: "less padding and a 13 px text"

  attr :role, :string,
    default: nil,
    doc: "overrides the role the kind gives: `alert` for something urgent, `status` for a change"

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true
  slot :icon, doc: "the icon, drawn by the caller in the tone of the callout"
  slot :actions

  @doc "A tinted block with an optional title, icon and actions."
  @spec callout(map()) :: Phoenix.LiveView.Rendered.t()
  def callout(assigns) do
    assigns =
      assigns
      |> assign(:tone, Tone.from_kind(assigns.kind))
      |> assign(:lead, lead(assigns.icon_layout, assigns.icon, assigns.title))

    ~H"""
    <div
      role={@role || role(@kind)}
      class={[
        "flex rounded-[14px] border leading-normal",
        layout(@icon_layout),
        (@compact && "p-3 text-[13px]") || "p-[18px] text-sm",
        Tone.surface(@tone),
        Tone.strong(@tone),
        @class
      ]}
      {@rest}
    >
      <span
        :if={@lead == :box}
        class="flex size-8 shrink-0 items-center justify-center rounded-lg bg-card/70"
        aria-hidden="true"
      >
        {render_slot(@icon)}
      </span>
      <div :if={@lead == :heading} class="flex items-center gap-2 font-semibold">
        <span class="flex size-4 shrink-0 items-center justify-center" aria-hidden="true">
          {render_slot(@icon)}
        </span>
        <p class="m-0">{@title}</p>
      </div>
      <div class={["flex min-w-0 flex-1 flex-col", (@compact && "gap-2") || "gap-2.5"]}>
        <p :if={@title && @lead != :heading} class="m-0 font-semibold">{@title}</p>
        <div class="flex gap-2">
          <span
            :if={@lead == :body}
            class="mt-0.5 flex size-4 shrink-0 items-center justify-center"
            aria-hidden="true"
          >
            {render_slot(@icon)}
          </span>
          <div>{render_slot(@inner_block)}</div>
        </div>
        <div :if={@actions != []} class="flex flex-wrap gap-2">{render_slot(@actions)}</div>
      </div>
    </div>
    """
  end

  defp lead(_layout, [], _title), do: :none
  defp lead(:box, _icon, _title), do: :box
  defp lead(:inline, _icon, nil), do: :body
  defp lead(:inline, _icon, _title), do: :heading

  defp layout(:box), do: "gap-2.5"
  defp layout(:inline), do: "flex-col gap-2.5"

  defp role(:risk), do: "alert"
  defp role(:warn), do: "alert"
  defp role(:warning), do: "alert"
  defp role(_kind), do: "status"
end
