defmodule DevactionUI.OtpInput do
  @moduledoc """
  The boxes of a one-time code, one character each: the code sent by SMS or e-mail, a two-factor code. Typing a
  digit fills its box and moves on; pasting the code fills every box; Backspace clears a box and, on an empty one,
  steps back; the arrows, Home and End move between boxes (`DevactionUI.OtpInput` hook, logic in `text.js`).

  The boxes have no name: the code goes, joined, into one hidden input (`name`), which fires `input` (and
  `change` when every box is full) so a form with `phx-change` hears it. Every box has `autocomplete="one-time-code"`
  and a numeric keyboard (`inputmode="numeric"`), so the phone offers the code it just got, which arrives as one value
  and is spread over the boxes. `numeric` false takes letters and digits.

  The state is `status`: `:idle` (an empty box has a quiet border, a filled one a stronger one, the focused one the
  ink), `:error` (red boxes, `aria-invalid`, and the `helper` is announced as an alert) or `:ok` (green boxes). The
  line under the boxes is the `helper` attr (`2 digits to go`), and the line under that, such as `Did not arrive?
  Resend in 0:24`, is the `resend` slot, so the caller draws the countdown and the button. Words are all attrs and
  slots: `label` names the group and `box_label` names each box (`Digit %{n} of %{total}`).
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  attr :id, :string, required: true

  attr :name, :string,
    required: true,
    doc: "the name of the hidden input that carries the joined code"

  attr :label, :string, required: true, doc: "names the group of boxes, e.g. `Verification code`"

  attr :box_label, :string,
    required: true,
    doc: "names each box; `%{n}` and `%{total}` are filled in, as in `Digit %{n} of %{total}`"

  attr :value, :string, default: "", doc: "the code so far, as the server knows it"
  attr :length, :integer, default: 6, doc: "how many boxes"

  attr :separator_after, :integer,
    default: nil,
    doc: "puts a separator after this many boxes, e.g. `3` for `482 – 913`"

  attr :status, :atom, values: [:idle, :error, :ok], default: :idle

  attr :numeric, :boolean,
    default: true,
    doc: "digits only, with a numeric keyboard; false takes letters too"

  attr :disabled, :boolean, default: false
  attr :autofocus, :boolean, default: false, doc: "focuses the first box on load"

  attr :helper, :string,
    default: nil,
    doc: "the line under the boxes, such as `2 digits to go` or `Wrong code. 2 tries left.`"

  attr :class, :any, default: nil

  slot :separator,
    doc: "between the boxes at `separator_after`; a short dash when empty"

  slot :resend,
    doc: "the line under the helper, such as `Did not arrive? <button>Resend in 0:24</button>`"

  attr :rest, :global

  def input(assigns) do
    assigns = assign(assigns, :chars, chars(assigns.value, assigns.length))

    ~H"""
    <div
      id={@id}
      role="group"
      aria-label={@label}
      phx-hook="DevactionUI.OtpInput"
      data-numeric={to_string(@numeric)}
      data-status={@status}
      class={["flex flex-col items-center gap-3.5", @class]}
      {@rest}
    >
      <div class="flex items-center justify-center gap-2">
        <span :for={{char, index} <- Enum.with_index(@chars)} class="contents">
          <span
            :if={@separator_after == index}
            aria-hidden="true"
            class="flex items-center text-muted-2"
          >
            {(@separator != [] && render_slot(@separator)) || "–"}
          </span>
          <input
            type="text"
            data-otp-box
            value={char}
            placeholder=" "
            autocomplete="one-time-code"
            inputmode={(@numeric && "numeric") || "text"}
            pattern={@numeric && "[0-9]*"}
            autofocus={@autofocus && index == 0}
            disabled={@disabled}
            aria-label={box_name(@box_label, index + 1, @length)}
            aria-invalid={@status == :error && "true"}
            aria-describedby={@helper && @id <> "-helper"}
            class={[
              "h-[58px] w-12 rounded-xl border-[1.5px] bg-card text-center font-mono text-2xl font-medium caret-ink outline-none transition-colors focus:ring-[3px] focus:ring-ink/10 disabled:cursor-not-allowed disabled:opacity-50 motion-reduce:transition-none",
              box_class(@status)
            ]}
          />
        </span>
      </div>
      <input
        type="hidden"
        name={@name}
        value={@value}
        data-otp-value
        phx-mounted={JS.ignore_attributes(["value"])}
      />
      <p
        :if={@helper}
        id={@id <> "-helper"}
        role={(@status == :error && "alert") || "status"}
        class={["m-0 min-h-5 text-[13px]", helper_class(@status)]}
      >
        {@helper}
      </p>
      <div :if={@resend != []} class="text-[13px] text-muted">{render_slot(@resend)}</div>
    </div>
    """
  end

  defp chars(value, length),
    do: value |> String.graphemes() |> Enum.take(length) |> pad(length)

  defp pad(chars, length), do: chars ++ List.duplicate("", length - length(chars))

  defp box_name(pattern, n, total),
    do:
      pattern
      |> String.replace("%{n}", Integer.to_string(n))
      |> String.replace("%{total}", Integer.to_string(total))

  defp box_class(:idle),
    do: "border-line text-ink not-placeholder-shown:border-muted-2 focus:border-ink"

  defp box_class(:error),
    do: "border-tag-risk-text bg-(--field-error-fill) text-tag-risk-text"

  defp box_class(:ok), do: "border-ok-fg bg-(--field-ok-fill) text-ok-fg"

  defp helper_class(:idle), do: "text-muted"
  defp helper_class(:error), do: "text-tag-risk-text"
  defp helper_class(:ok), do: "text-ok-fg"
end
