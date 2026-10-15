import {formatReais} from "./money.js"

/** A text field that formats what is typed as Brazilian money (`R$ 1.234,56`). */
export default {
  mounted() {
    this.el.addEventListener("input", () => (this.el.value = formatReais(this.el.value)))
  },
}
