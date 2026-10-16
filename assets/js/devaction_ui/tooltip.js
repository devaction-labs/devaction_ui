import {runKey} from "./keys.js"
import {placeTip, screenSize} from "./placement.js"
import {FOCUSABLE, dismissesOnTap, withDescription} from "./tooltip_logic.js"

/**
 * The part of `Tooltip` that CSS cannot do: it points the first focusable control inside the trigger at the
 * hint with `aria-describedby` (the focused element is the one a screen reader describes), keeps the hint
 * on the screen (it flips to the other side and slides along the trigger when it would leave the viewport,
 * and the arrow keeps pointing at the trigger), and dismisses it: Esc while the pointer or the focus is on
 * the trigger, or a tap. The hint comes back when the mouse leaves or the focus moves away (after a tap, only when the focus moves away). Esc is never
 * consumed, so it still reaches a dialog around the trigger. The hint can be hovered, so the pointer may
 * move onto it without it closing.
 */
export default {
  mounted() {
    this.tip = document.getElementById(this.el.dataset.tip)
    this.el.addEventListener("keydown", (event) => runKey({Escape: () => this.dismiss()}, event))
    this.el.addEventListener("pointerdown", (event) => dismissesOnTap(event.pointerType) && this.dismiss())
    this.el.addEventListener("pointerenter", () => this.place())
    this.el.addEventListener("focusin", () => this.place())
    this.el.addEventListener("pointerleave", (event) => dismissesOnTap(event.pointerType) || this.restore())
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

  place() {
    const {side, shift, arrow} = placeTip(this.tip.dataset.placement, {
      tip: {width: this.tip.offsetWidth, height: this.tip.offsetHeight},
      trigger: this.el.getBoundingClientRect(),
      viewport: screenSize(),
    })
    this.tip.dataset.side = side
    this.tip.style.setProperty("--tip-shift", `${shift}px`)
    this.tip.style.setProperty("--tip-arrow", `${arrow}px`)
  },

  dismiss() {
    this.el.matches(":hover, :focus-within") && this.el.setAttribute("data-dismissed", "")
    return false
  },

  restore() {
    this.el.removeAttribute("data-dismissed")
  },
}
