import {runKey} from "./keys.js"
import {FOCUSABLE, withDescription} from "./tooltip_logic.js"

/**
 * The part of `Tooltip` that CSS cannot do: it points the first focusable control inside the trigger at the
 * hint with `aria-describedby` (the focused element is the one a screen reader describes), and Esc dismisses
 * the hint while the pointer or the focus is still on the trigger. The hint comes back when the pointer
 * leaves or the focus moves away. Esc is never consumed, so it still reaches a dialog around the trigger.
 */
export default {
  mounted() {
    this.el.addEventListener("keydown", (event) => runKey({Escape: () => this.dismiss()}, event))
    this.el.addEventListener("pointerleave", () => this.restore())
    this.el.addEventListener("focusout", () => this.restore())
    this.describe()
  },

  updated() {
    this.describe()
  },

  describe() {
    const control = this.el.querySelector(FOCUSABLE)
    control?.setAttribute("aria-describedby", withDescription(control.getAttribute("aria-describedby"), this.el.dataset.tip))
  },

  dismiss() {
    this.el.matches(":hover, :focus-within") && this.el.setAttribute("data-dismissed", "")
    return false
  },

  restore() {
    this.el.removeAttribute("data-dismissed")
  },
}
