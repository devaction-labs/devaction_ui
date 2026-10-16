defmodule DevactionUI.CodeBlock do
  @moduledoc """
  A block of code in mono, given as the `code` attribute. `lang: :heex` colours it (components, slots, attributes,
  strings, expressions, comments) through `DevactionUI.Highlight`. `tone: :dark` is the ink block of a suggestion; `:risk` and `:ok` are the
  "your code" and "idiomatic" blocks of a lesson, tinted red and green; `:neutral` is the quiet tint. The dark
  block has fixed colours on purpose: it is a dark surface in both themes. It keeps its own line breaks and
  scrolls sideways instead of widening the page.

  `lang` knows only `:heex`; any other code stays plain. With a `label` the block is a named region that the
  keyboard can focus, so a long line can be scrolled without a mouse. With `copy_label` a button copies the
  code (the `DevactionUI.CodeCopy` hook, so it needs an `id`; it stays hidden where the browser cannot write to
  the clipboard) and says `copied_label` for a moment.
  """
  use Phoenix.Component

  alias DevactionUI.{Highlight, Tone}

  attr :tone, :atom, values: [:dark, :risk, :ok, :neutral], default: :dark
  attr :id, :string, default: nil

  attr :label, :string,
    default: nil,
    doc: "a mono caption above the block, and the name of its region for assistive technology"

  attr :copy_label, :string,
    default: nil,
    doc: "the name of the copy button; without it, no button"

  attr :copied_label, :string, default: nil, doc: "said for a moment after the copy"

  attr :lang, :atom,
    values: [nil, :heex],
    default: nil,
    doc: "`:heex` colours the code by what each part of the template is"

  attr :class, :any, default: nil

  attr :code, :string,
    required: true,
    doc: "the code as text: a `pre` keeps every space, so it never comes from a slot"

  attr :rest, :global
  slot :copy_icon, doc: "the icon of the copy button; without it the button shows `copy_label`"

  def code_block(%{copy_label: copy_label, id: nil}) when is_binary(copy_label),
    do: raise(ArgumentError, "code_block: `copy_label` needs an `id`")

  def code_block(assigns) do
    ~H"""
    <div
      id={@id}
      phx-hook={@copy_label && "DevactionUI.CodeCopy"}
      class="flex min-w-0 flex-col gap-2"
    >
      <span
        :if={@label}
        class={["font-mono text-xs tracking-[0.08em] uppercase", label_class(@tone)]}
      >
        {@label}
      </span>
      <div class="relative flex min-w-0 flex-col">
        <button
          :if={@copy_label}
          type="button"
          hidden
          data-code-copy
          data-copied-label={@copied_label}
          class="absolute top-2 right-2 rounded-lg border border-line bg-card px-2 py-1 font-mono text-xs text-ink-2 outline-none hover:text-ink focus-visible:ring-4 focus-visible:ring-ink/10 data-[copied]:text-tag-ok-text"
        >
          {render_slot(@copy_icon)}<span class={@copy_icon != [] && "sr-only"}>{@copy_label}</span>
        </button>
        <span :if={@copy_label} data-code-status role="status" class="sr-only"></span>
        <pre
          role={@label && "region"}
          aria-label={@label}
          tabindex={@label && "0"}
          phx-no-curly-interpolation
          class={[
            "m-0 overflow-x-auto font-mono text-[13px] leading-[21px]",
            surface(@tone),
            @class
          ]}
          {@rest}
        ><code><.tokens lang={@lang} code={@code} /></code></pre>
      </div>
    </div>
    """
  end

  attr :lang, :atom, required: true
  attr :code, :string, required: true

  defp tokens(%{lang: :heex} = assigns) do
    assigns = assign(assigns, :tokens, Highlight.heex(assigns.code))

    ~H|<span :for={{kind, text} <- @tokens} class={kind_class(kind)}>{text}</span>|
  end

  defp tokens(assigns), do: ~H|{@code}|

  defp kind_class(:punct), do: "text-[#6B7280]"
  defp kind_class(:html), do: "text-[#7AA2F7]"
  defp kind_class(:component), do: "text-[#7AA2F7]"
  defp kind_class(:slot), do: "text-[#A3B35A]"
  defp kind_class(:attr), do: "text-[#9CA3AF]"
  defp kind_class(:string), do: "text-[#E4E4E7]"
  defp kind_class(:expr), do: "text-[#E3A72F]"
  defp kind_class(:comment), do: "text-[#6B7280] italic"
  defp kind_class(:text), do: nil

  defp surface(:dark), do: "rounded-[10px] bg-[#18181B] px-3.5 py-3 text-[#E4E4E7]"
  defp surface(tone), do: ["rounded-xl border p-3.5 text-ink", Tone.surface(tone)]

  defp label_class(:dark), do: "text-muted"
  defp label_class(tone), do: Tone.text(tone)
end
