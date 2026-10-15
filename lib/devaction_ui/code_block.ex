defmodule DevactionUI.CodeBlock do
  @moduledoc """
  A block of code in mono, given as the `code` attribute. `lang: :heex` colours it (components, slots, attributes,
  strings, expressions, comments) through `DevactionUI.Highlight`. `tone: :dark` is the ink block of a suggestion; `:risk` and `:ok` are the
  "your code" and "idiomatic" blocks of a lesson, tinted red and green. It keeps its own line breaks and
  scrolls sideways instead of widening the page.
  """
  use Phoenix.Component

  alias DevactionUI.{Highlight, Tone}

  attr :tone, :atom, values: [:dark, :risk, :ok, :neutral], default: :dark
  attr :label, :string, default: nil, doc: "a mono caption above the block"

  attr :lang, :atom,
    values: [nil, :heex],
    default: nil,
    doc: "`:heex` colours the code by what each part of the template is"

  attr :class, :any, default: nil

  attr :code, :string,
    required: true,
    doc: "the code as text: a `pre` keeps every space, so it never comes from a slot"

  attr :rest, :global

  def code_block(assigns) do
    ~H"""
    <div class="flex min-w-0 flex-col gap-2">
      <span
        :if={@label}
        class={["font-mono text-xs tracking-[0.08em] uppercase", label_class(@tone)]}
      >
        {@label}
      </span>
      <pre
        phx-no-curly-interpolation
        class={[
          "m-0 overflow-x-auto font-mono text-[13px] leading-[21px]",
          surface(@tone),
          @class
        ]}
        {@rest}
      ><code><.tokens lang={@lang} code={@code} /></code></pre>
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
