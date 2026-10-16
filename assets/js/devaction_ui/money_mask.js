import {caretAfter, formatMoney, moneyOptions} from "./numbers.js"

/**
 * A text field that formats what is typed as money (`1.234,56` by default; `data-decimal`, `data-group`,
 * `data-precision` and `data-signed` set the currency's way). The value the server renders it with and the one it
 * patches in are formatted too, and the caret stays among the same digits.
 */
export default {
  mounted() {
    this.format()
    this.el.addEventListener("input", () => this.format())
  },

  updated() {
    this.format()
  },

  format() {
    const before = this.el.value
    const caret = this.el.selectionStart ?? before.length
    const after = formatMoney(before, moneyOptions(this.el.dataset))
    const changed = after !== before
    const position = caretAfter(before, caret, after)
    changed && (this.el.value = after)
    changed && document.activeElement === this.el && this.el.setSelectionRange(position, position)
  },
}
