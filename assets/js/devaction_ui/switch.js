import {press} from "./switch_logic.js"

/**
 * Makes a switch part of a form. The button has `aria-checked`; with a `name` the component also renders a
 * hidden input `<id>-field` that the form submits, and this hook keeps the two the same: a press flips both and
 * fires `input` on the field so a `phx-change` hears it. A disabled or busy switch (`aria-disabled`) is left
 * alone. A caller's own `phx-click` still runs.
 */
export default {
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
    this.field.dispatchEvent(new Event("input", {bubbles: true}))
  },
}
