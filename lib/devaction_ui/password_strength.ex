defmodule DevactionUI.PasswordStrength do
  @moduledoc """
  The meter under a new-password field: four bars that fill as the password meets the rules, a line saying how
  strong it is, and the rules with a mark for each that is met. The server computes it from the text
  (`evaluate/2`) and the field sends it on `phx-change`; nothing is kept in the browser.

  The rules are three: at least `min_length` characters, both capitals and small letters, and a number or a
  symbol. A password meeting all three and at least four characters longer than the minimum is `score` 4; with the
  field empty it is 0. The words for the rules and the line are the caller's; the marks are slots.
  """
  use Phoenix.Component

  alias DevactionUI.Tone

  @rules [:length, :mixed_case, :digit_or_symbol]

  @doc """
  What a password meets: `%{score: 0..4, rules: [length: boolean, mixed_case: boolean, digit_or_symbol: boolean]}`.
  """
  @spec evaluate(String.t(), pos_integer()) :: %{score: 0..4, rules: keyword(boolean())}
  def evaluate(password, min_length \\ 12)

  def evaluate("", _min_length), do: %{score: 0, rules: Enum.map(@rules, &{&1, false})}

  def evaluate(password, min_length) do
    met = [
      length: String.length(password) >= min_length,
      mixed_case: password =~ ~r/\p{Lu}/u and password =~ ~r/\p{Ll}/u,
      digit_or_symbol: password =~ ~r/[\d\p{P}\p{S}]/u
    ]

    count = Enum.count(met, fn {_rule, ok?} -> ok? end)

    %{score: score(count, String.length(password) >= min_length + 4), rules: met}
  end

  defp score(3, true), do: 4
  defp score(count, _long?), do: max(count, 1)

  attr :score, :integer, required: true, doc: "0 to 4, from `evaluate/2`"
  attr :label, :string, required: true, doc: "the line under the bars, e.g. `Strong`"
  attr :rules, :list, required: true, doc: "`%{label: text, met: boolean}` each"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :met_icon, doc: "the mark of a rule that is met"
  slot :unmet_icon, doc: "the mark of a rule that is not met yet"

  def password_strength(assigns) do
    assigns = assign(assigns, :tone, tone(assigns.score))

    ~H"""
    <div class={["flex flex-col gap-2", @class]} {@rest}>
      <div
        role="meter"
        aria-valuemin="0"
        aria-valuemax="4"
        aria-valuenow={@score}
        aria-label={@label}
        class="grid grid-cols-4 gap-2"
      >
        <span
          :for={bar <- 1..4}
          class={["h-1 rounded-full", (bar <= @score && Tone.fill(@tone)) || "bg-line"]}
        ></span>
      </div>
      <p class="m-0 text-[13px] text-muted">{@label}</p>
      <ul class="m-0 flex list-none flex-col gap-1.5 p-0">
        <li
          :for={rule <- @rules}
          data-met={to_string(rule.met)}
          class="flex items-center gap-2 text-[13px] text-muted data-[met=true]:text-ink-2"
        >
          <span
            class={["grid size-4 place-items-center", rule.met && "text-ok-fg"]}
            aria-hidden="true"
          >
            {(rule.met && render_slot(@met_icon)) || render_slot(@unmet_icon)}
          </span>
          {rule.label}
        </li>
      </ul>
    </div>
    """
  end

  defp tone(score) when score <= 1, do: :risk
  defp tone(2), do: :warn
  defp tone(3), do: :info
  defp tone(_score), do: :ok
end
