import {clampPair, fillBox, pairText} from "./range_logic.js"

/**
 * Two range inputs on one track (`data-low` and `data-high`): the thumb being dragged stops at the other one,
 * the filled part (`data-fill`) follows both and, with `data-format-text`, so does the value written in the
 * `<output>` of the group. The server still sends both values on `phx-change`; this only keeps the page
 * right between two round trips.
 */
export default {
  mounted() {
    this.low = this.el.querySelector("[data-low]")
    this.high = this.el.querySelector("[data-high]")
    this.fill = this.el.querySelector("[data-fill]")
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
    const box = fillBox(pair.low, pair.high, this.low.min, this.low.max)
    this.fill.style.left = `${box.left}%`
    this.fill.style.width = `${box.width}%`
    const template = this.el.dataset.formatText
    template && this.output && (this.output.textContent = pairText(template, pair.low, pair.high))
  },
}
