defmodule DevactionUI.Button do
  @moduledoc """
  The buttons of the canvas, as a button or as a link, in the same colors and sizes.

  `variant` says what the action means: `:primary` (the one thing to do), `:secondary`, `:ghost`, `:ai`
  (what the AI offers), `:danger` (asking for changes), `:info` (leading to something to learn), `:link`.
  `size` is `:sm` (38px), `:md` (46px) or `:lg` (54px); `:sm` is under the 44px of a touch target, so use `:md` on touch screens. With `navigate`, `patch` or `href` it is a link
  that looks like a button; without, a real `<button>`. `loading` shows a spinner and sets `aria-busy`, on the link as well. A disabled link is taken out of the tab order
  (`tabindex="-1"`) and ignores the pointer. `shape: :round` makes it a pill, or a circle with `icon_only` (44px at `:md`).

  It is called as `<Button.button>` (`alias DevactionUI.Button`), not imported, so it does not collide
  with the `button/1` of another UI kit in the same app.
  """
  use Phoenix.Component

  attr :variant, :atom,
    values: [:primary, :secondary, :ghost, :ai, :danger, :info, :link],
    default: :secondary,
    doc: "what the action means, from `:primary` (the one thing to do) to `:link`"

  attr :size, :atom, values: [:sm, :md, :lg], default: :md, doc: "38, 46 or 54 px high"
  attr :shape, :atom, values: [:square, :round], default: :square
  attr :loading, :boolean, default: false, doc: "a spinner before the text, and `aria-busy`"
  attr :disabled, :boolean, default: false

  attr :icon_only, :boolean,
    default: false,
    doc: "a square button with just an icon (44px at `:md`); give it an `aria-label`"

  attr :class, :any, default: nil

  attr :rest, :global,
    include: ~w(href navigate patch method download name value form type target rel)

  slot :inner_block, required: true

  @doc """
  A button, or a link that looks like one when `navigate`, `patch` or `href` is given.

      <Button.button variant={:primary} phx-click="save">Save</Button.button>
      <Button.button navigate={~p"/orders"}>Orders</Button.button>
  """
  def button(%{rest: %{navigate: _}} = assigns), do: as_link(assigns)
  def button(%{rest: %{patch: _}} = assigns), do: as_link(assigns)
  def button(%{rest: %{href: _}} = assigns), do: as_link(assigns)

  def button(assigns) do
    ~H"""
    <button
      type={@rest[:type] || "button"}
      disabled={@disabled or @loading}
      aria-busy={@loading && "true"}
      class={classes(assigns)}
      {Map.delete(@rest, :type)}
    >
      <.content loading={@loading}>{render_slot(@inner_block)}</.content>
    </button>
    """
  end

  defp as_link(assigns) do
    ~H"""
    <.link
      aria-disabled={@disabled && "true"}
      aria-busy={@loading && "true"}
      tabindex={tabindex(@disabled)}
      class={classes(assigns)}
      {@rest}
    >
      <.content loading={@loading}>{render_slot(@inner_block)}</.content>
    </.link>
    """
  end

  defp tabindex(true), do: "-1"
  defp tabindex(false), do: nil

  attr :loading, :boolean, required: true
  slot :inner_block, required: true

  defp content(assigns) do
    ~H"""
    <span
      :if={@loading}
      aria-hidden="true"
      class="size-3.5 animate-spin rounded-full border-2 border-current/30 border-t-current motion-reduce:animate-none"
    />
    {render_slot(@inner_block)}
    """
  end

  defp classes(assigns) do
    [
      "inline-flex items-center justify-center whitespace-nowrap no-underline outline-none transition-colors",
      "focus-visible:ring-4 focus-visible:ring-ink/10",
      gap(assigns.loading),
      size(assigns.size, assigns.icon_only),
      radius(assigns.shape, assigns.size),
      padding(assigns.size, assigns.icon_only, assigns.variant),
      weight(assigns.size, assigns.variant),
      look(assigns),
      assigns.class
    ]
  end

  defp gap(true), do: "gap-2.5"
  defp gap(false), do: "gap-2"

  defp look(%{disabled: true, loading: false}),
    do: "pointer-events-none cursor-not-allowed border border-transparent bg-line text-muted"

  defp look(%{loading: true} = assigns), do: ["cursor-progress", variant(assigns.variant)]
  defp look(assigns), do: variant(assigns.variant)

  defp size(:sm, false), do: "h-[38px] text-[13px]"
  defp size(:md, false), do: "h-[46px] text-[15px]"
  defp size(:lg, false), do: "h-[54px] text-base"
  defp size(:sm, true), do: "size-[38px]"
  defp size(:md, true), do: "size-11"
  defp size(:lg, true), do: "size-[54px]"

  defp radius(:round, _size), do: "rounded-full"
  defp radius(:square, :sm), do: "rounded-[10px]"
  defp radius(:square, :md), do: "rounded-xl"
  defp radius(:square, :lg), do: "rounded-[14px]"

  defp padding(_size, true, _variant), do: nil
  defp padding(_size, false, :link), do: "px-1.5"
  defp padding(:sm, false, _variant), do: "px-3.5"
  defp padding(:md, false, :primary), do: "px-[18px]"
  defp padding(:md, false, _variant), do: "px-4"
  defp padding(:lg, false, _variant), do: "px-6"

  defp weight(:lg, _variant), do: "font-semibold"
  defp weight(_size, variant) when variant in [:secondary, :ghost], do: "font-normal"
  defp weight(_size, _variant), do: "font-medium"

  defp variant(:primary), do: "bg-ink text-on-primary hover:opacity-90"
  defp variant(:secondary), do: "border border-line-strong bg-card text-ink hover:bg-wrap"
  defp variant(:ghost), do: "text-ink-2 hover:bg-wrap"
  defp variant(:ai), do: "border border-tag-warn-line bg-tag-warn-bg text-tag-warn-text"
  defp variant(:danger), do: "border border-tag-risk-line bg-tag-risk-bg text-tag-risk-text"
  defp variant(:info), do: "border border-tag-info-line bg-tag-info-bg text-tag-info-text"
  defp variant(:link), do: "text-ink hover:text-ink-2"
end
