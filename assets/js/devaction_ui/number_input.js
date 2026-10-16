import {runKey} from "./keys.js"
import {NUMBER_KEYS, clampText, keyDelta, parseLimit, scaled} from "./numbers.js"

/**
 * The spinbutton keys of a `NumberInput`: ArrowUp/ArrowDown move a step, PageUp/PageDown ten, Home/End go to the
 * limits, by the same event the buttons send; leaving the field holds what was typed inside `min` and `max`. The
 * steps are decimal-exact (`data-step="0.25"`), shown with `data-precision` decimals and `data-decimal` between.
 */
export default {
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
    changed && this.field.dispatchEvent(new Event("input", {bubbles: true}))
  },
}
