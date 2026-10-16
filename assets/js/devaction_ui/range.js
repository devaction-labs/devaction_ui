import {percent, valueText} from "./range_logic.js"

/**
 * Paints the filled part of a single range input as it is dragged: the server sets `--p` for the value it
 * has, and this keeps it up with the thumb between two round trips. With `data-format-text` the value beside
 * the label (the `<output>` of the input) follows the thumb too.
 */
export default {
  mounted() {
    this.output = this.el.parentElement.querySelector(`output[for="${this.el.id}"]`)
    this.paint = () => {
      this.el.style.setProperty("--p", `${percent(this.el.value, this.el.min, this.el.max)}%`)
      const template = this.el.dataset.formatText
      template && this.output && (this.output.textContent = valueText(template, this.el.value))
    }
    this.el.addEventListener("input", this.paint)
  },
  destroyed() {
    this.el.removeEventListener("input", this.paint)
  },
}
