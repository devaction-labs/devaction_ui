defmodule DevactionUI.PasswordStrength do
  @moduledoc """
  The meter under a new-password field: four bars that fill as the password meets the rules, a line saying how
  strong it is, and the rules with a mark for each that is met. The server computes it from the text
  (`evaluate/2`) and the field sends it on `phx-change`; nothing is kept in the browser.

  The rules are three: at least `min_length` characters, both capitals and small letters, and a number or a
  symbol. The `score` is the rules met, plus one more for a password of 16 characters or more (the canvas's
  rule); a password that meets no rule, like an empty one, is 0. The words for the rules, the line and the name of
  the meter are the caller's; the marks are slots (the canvas draws a circle with a check and a clock, 15px, with
  a stroke of 1.8).

  The colours are the tones (`DevactionUI.Tone`): red, amber, blue and green for the scores 1 to 4, on the bars and
  on the line under them; a rule that is met paints its whole line, mark and words, in the green of the tone `:ok`
  and one that is not stays muted, in both themes.
  """
  use Phoenix.Component

  alias DevactionUI.Tone

  @rules [:length, :mixed_case, :digit_or_symbol]
  @long 16

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

    %{score: score(count, String.length(password) >= @long), rules: met}
  end

  defp score(0, _long?), do: 0
  defp score(count, true), do: count + 1
  defp score(count, false), do: count

  attr :score, :integer, required: true, doc: "0 to 4, from `evaluate/2`"

  attr :label, :string,
    required: true,
    doc: "the line under the bars, e.g. `Strong`; read as the meter's value"

  attr :meter_label, :string,
    required: true,
    doc: "the name of the meter for assistive technology, e.g. `Password strength`"

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
        aria-label={@meter_label}
        aria-valuetext={@label}
        class="grid grid-cols-4 gap-1.5"
      >
        <span
          :for={bar <- 1..4}
          class={["h-[5px] rounded-full", (bar <= @score && Tone.fill(@tone)) || "bg-line"]}
        ></span>
      </div>
      <p aria-live="polite" class={["m-0 text-[13px]", line_color(@score, @tone)]}>{@label}</p>
      <ul class="m-0 flex list-none flex-col gap-1.5 p-0">
        <li
          :for={rule <- @rules}
          data-met={to_string(rule.met)}
          class={["flex items-center gap-2 text-[13px]", rule_color(rule.met)]}
        >
          <span class="grid size-4 place-items-center" aria-hidden="true">
            {(rule.met && render_slot(@met_icon)) || render_slot(@unmet_icon)}
          </span>
          {rule.label}
        </li>
      </ul>
    </div>
    """
  end

  defp rule_color(true), do: Tone.text(:ok)
  defp rule_color(false), do: "text-muted"

  defp line_color(0, _tone), do: "text-muted"
  defp line_color(_score, tone), do: Tone.text(tone)

  defp tone(score) when score <= 1, do: :risk
  defp tone(2), do: :warn
  defp tone(3), do: :info
  defp tone(_score), do: :ok
end
