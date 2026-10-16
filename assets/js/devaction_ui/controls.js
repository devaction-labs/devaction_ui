/**
 * The small hooks that keep one attribute or value of a form control in step with what the person does:
 * `Indeterminate`, `Switch`, `Segmented`, `Range`, `RangePair` and `NumberInput`. Each is registered under its
 * own name in `index.js`.
 */
import {notify} from "./dom.js"
import {moveSegment, runKey, tabStop} from "./keys.js"
import {clampPair, clampText, fillBox, fillStyle, fraction, keyDelta, NUMBER_KEYS, pairText, parseLimit, percent, scaled, valueText} from "./numbers.js"

/**
 * The partial state of a "select all" box. `indeterminate` is a property of the element, not an attribute, so
 * only script can set it; the server marks the box with `data-partial` and this keeps the property up with it.
 */
export const Indeterminate = {
  mounted() {
    this.sync()
  },

  updated() {
    this.sync()
  },

  sync() {
    this.el.indeterminate = this.el.dataset.partial === "true"
  },
}

/** The other state of a switch, as the text of `aria-checked` and of the field. */
export const flip = (checked) => (checked === "true" ? "false" : "true")

/** The state after a press: the same while the switch is disabled or busy (`aria-disabled="true"`). */
export const press = (checked, disabled) => (disabled === "true" ? checked : flip(checked))

/**
 * Makes a switch part of a form. The button has `aria-checked`; with a `name` the component also renders a
 * hidden input `<id>-field` that the form submits, and this hook keeps the two the same: a press flips both and
 * fires `input` on the field so a `phx-change` hears it. A disabled or busy switch (`aria-disabled`) is left
 * alone. A caller's own `phx-click` still runs.
 */
export const Switch = {
  mounted() {
    this.field = this.el.ownerDocument.getElementById(`${this.el.id}-field`)
    this.onClick = () => this.toggle()
    this.el.addEventListener("click", this.onClick)
  },

  destroyed() {
    this.el.removeEventListener("click", this.onClick)
  },

  toggle() {
    const current = this.el.getAttribute("aria-checked")
    const next = press(current, this.el.getAttribute("aria-disabled"))
    if (next === current) return

    this.el.setAttribute("aria-checked", next)
    this.field.value = next
    notify(this.field)
  },
}

/**
 * Arrow keys for a segmented control without changing what it is: the segments stay toggle buttons with
 * `aria-pressed`, and only the keyboard gets easier. One segment is in the Tab order (roving tabindex): the
 * pressed one, or the first enabled one. ← → ↑ ↓ move the focus round the segments, Home and End jump to the
 * ends and disabled ones are skipped; Enter or Space presses the focused one as for any button. Moving the
 * focus does not choose: that stays a press.
 */
export const Segmented = {
  mounted() {
    this.onKey = (event) => this.key(event)
    this.el.addEventListener("keydown", this.onKey)
    this.sync()
  },

  updated() {
    this.sync()
  },

  destroyed() {
    this.el.removeEventListener("keydown", this.onKey)
  },

  segments() {
    return [...this.el.querySelectorAll("button")]
  },

  items() {
    return this.segments().map((button) => ({
      pressed: button.getAttribute("aria-pressed") === "true",
      disabled: button.disabled,
    }))
  },

  sync() {
    this.rove(tabStop(this.items()))
  },

  rove(stop) {
    this.segments().forEach((button, index) => {
      button.tabIndex = index === stop ? 0 : -1
    })
  },

  key(event) {
    const segments = this.segments()
    const from = segments.indexOf(event.target.closest("button"))
    const target = segments[moveSegment(this.items(), from, event.key)]
    const go = () => {
      if (!target) return false
      this.rove(segments.indexOf(target))
      target.focus()
    }

    runKey(Object.fromEntries(["ArrowRight", "ArrowLeft", "ArrowDown", "ArrowUp", "Home", "End"].map((key) => [key, go])), event)
  },
}

/**
 * Paints a single range input as it is dragged: the server sets `--p` (the filled part) and the bubble's `--f`
 * for the value it has, and this keeps them up with the thumb between two round trips. With
 * `data-format-text` the value beside the label (the `<output>` of the input) and the value bubble over the
 * thumb (`data-bubble`, when the component has one) follow the thumb too.
 */
export const Range = {
  mounted() {
    const root = this.el.closest("[data-slider]") ?? this.el.parentElement
    this.output = root.querySelector(`output[for="${this.el.id}"]`)
    this.bubble = root.querySelector("[data-bubble]")
    this.paint = () => {
      const {value, min, max} = this.el
      this.el.style.setProperty("--p", `${percent(value, min, max)}%`)
      const template = this.el.dataset.formatText
      template && this.output && (this.output.textContent = valueText(template, value))
      this.bubble?.style.setProperty("--f", String(fraction(value, min, max)))
      this.bubble && (this.bubble.textContent = valueText(template, value))
    }
    this.el.addEventListener("input", this.paint)
  },
  destroyed() {
    this.el.removeEventListener("input", this.paint)
  },
}

/**
 * Two range inputs on one track (`data-low` and `data-high`): the thumb being dragged stops at the other one,
 * the filled part (`data-fill`) follows both (from the bottom when `data-orientation="vertical"`) and, with
 * `data-format-text`, so does the value written in the `<output>` of the group. The value bubbles
 * (`data-bubble-low`, `data-bubble-high`), when the component has them, follow their thumbs. The server still
 * sends both values on `phx-change`; this only keeps the page right between two round trips.
 */
export const RangePair = {
  mounted() {
    this.low = this.el.querySelector("[data-low]")
    this.high = this.el.querySelector("[data-high]")
    this.fill = this.el.querySelector("[data-fill]")
    this.bubbles = {low: this.el.querySelector("[data-bubble-low]"), high: this.el.querySelector("[data-bubble-high]")}
    this.output = document.getElementById(`${this.el.id}-output`)
    this.onInput = (event) => this.sync(event.target === this.low ? "low" : "high")
    this.el.addEventListener("input", this.onInput)
  },

  destroyed() {
    this.el.removeEventListener("input", this.onInput)
  },

  sync(moved) {
    const pair = clampPair(this.low.value, this.high.value, moved)
    this.low.value = pair.low
    this.high.value = pair.high
    const {min, max} = this.low
    Object.assign(this.fill.style, fillStyle(this.el.dataset.orientation, fillBox(pair.low, pair.high, min, max)))
    const template = this.el.dataset.formatText
    template && this.output && (this.output.textContent = pairText(template, pair.low, pair.high))
    this.moveBubble("low", pair.low, template)
    this.moveBubble("high", pair.high, template)
  },

  moveBubble(which, value, template) {
    const bubble = this.bubbles[which]
    bubble?.style.setProperty("--f", String(fraction(value, this.low.min, this.low.max)))
    bubble && (bubble.textContent = valueText(template, value))
  },
}

/**
 * The spinbutton keys of a `NumberInput`: ArrowUp/ArrowDown move a step, PageUp/PageDown ten, Home/End go to the
 * limits, by the same event the buttons send; leaving the field holds what was typed inside `min` and `max`. The
 * steps are decimal-exact (`data-step="0.25"`), shown with `data-precision` decimals and `data-decimal` between.
 */
export const NumberInput = {
  mounted() {
    this.field = this.el.querySelector("input")
    const table = Object.fromEntries(NUMBER_KEYS.map((key) => [key, () => this.press(key)]))
    this.field.addEventListener("keydown", (event) => runKey(table, event))
    this.field.addEventListener("change", () => this.hold())
  },

  limits() {
    const {step, min, max, precision, decimal} = this.el.dataset
    return {
      step: scaled(step) ?? {int: 1, scale: 0},
      min: parseLimit(min),
      max: parseLimit(max),
      precision: Number(precision ?? 0),
      decimal: decimal ?? ".",
    }
  },

  press(key) {
    const delta = keyDelta(key, this.field.value, this.limits())
    delta !== null && this.pushEvent(this.el.dataset.event, {step: delta})
    return delta !== null
  },

  hold() {
    const held = clampText(this.field.value, this.limits())
    const changed = held !== this.field.value
    changed && (this.field.value = held)
    changed && notify(this.field)
  },
}
