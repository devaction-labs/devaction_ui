import {fraction, percent, valueText} from "./range_logic.js"

/**
 * Paints a single range input as it is dragged: the server sets `--p` (the filled part) and the bubble's `--f`
 * for the value it has, and this keeps them up with the thumb between two round trips. With
 * `data-format-text` the value beside the label (the `<output>` of the input) and the value bubble over the
 * thumb (`data-bubble`, when the component has one) follow the thumb too.
 */
export default {
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
