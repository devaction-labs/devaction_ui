import {runKey} from "./keys.js"
import {STEP_KEYS, clampText, keyDelta, parseLimit} from "./number_logic.js"

/**
 * The spinbutton keys of a `NumberInput`: ArrowUp/ArrowDown move a step, PageUp/PageDown ten, by the same
 * event the buttons send; leaving the field holds what was typed inside `min` and `max`.
 */
export default {
  mounted() {
    this.field = this.el.querySelector("input")
    const table = Object.fromEntries(Object.keys(STEP_KEYS).map((key) => [key, () => this.press(key)]))
    this.field.addEventListener("keydown", (event) => runKey(table, event))
    this.field.addEventListener("change", () => this.hold())
  },

  limits() {
    const {step, min, max} = this.el.dataset
    return {step: Number(step), min: parseLimit(min), max: parseLimit(max)}
  },

  press(key) {
    const delta = keyDelta(key, this.field.value, this.limits())
    delta !== null && this.pushEvent(this.el.dataset.event, {step: String(delta)})
    return delta !== null
  },

  hold() {
    const held = clampText(this.field.value, this.limits())
    const changed = held !== this.field.value
    changed && (this.field.value = held)
    changed && this.field.dispatchEvent(new Event("input", {bubbles: true}))
  },
}
