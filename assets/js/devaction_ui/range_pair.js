import {clampPair, fillBox, fillStyle, fraction, pairText, valueText} from "./numbers.js"

/**
 * Two range inputs on one track (`data-low` and `data-high`): the thumb being dragged stops at the other one,
 * the filled part (`data-fill`) follows both (from the bottom when `data-orientation="vertical"`) and, with
 * `data-format-text`, so does the value written in the `<output>` of the group. The value bubbles
 * (`data-bubble-low`, `data-bubble-high`), when the component has them, follow their thumbs. The server still
 * sends both values on `phx-change`; this only keeps the page right between two round trips.
 */
export default {
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
