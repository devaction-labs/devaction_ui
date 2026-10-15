import {runKey} from "./keys.js"
import {chooseSide} from "./popover_logic.js"

/**
 * A panel anchored to a trigger: the trigger opens and closes it, Esc and a click outside close it, focus
 * goes into the panel when it opens and back to the trigger when it is closed with the keyboard or the
 * trigger. It flips to the other side when there is no room on the screen.
 */
export default {
  mounted() {
    this.trigger = this.el.querySelector("[data-trigger]")
    this.panel = this.el.querySelector("[data-panel]")
    this.arrow = this.panel.querySelector("[data-arrow]")

    this.trigger.addEventListener("click", () => (this.panel.hidden ? this.open() : this.close(true)))
    this.el.addEventListener("keydown", (event) => this.onKey(event))
    this.outside = (event) => !this.el.contains(event.target) && this.close(false)
    document.addEventListener("mousedown", this.outside)
  },

  destroyed() {
    document.removeEventListener("mousedown", this.outside)
  },

  onKey(event) {
    const close = () => {
      // A closed popover declines Esc, so it reaches whatever is around it.
      if (this.panel.hidden) return false
      event.stopPropagation()
      this.close(true)
    }
    runKey({Escape: close}, event)
  },

  open() {
    this.panel.hidden = false
    this.place()
    this.trigger.setAttribute("aria-expanded", "true")
    const target = this.panel.querySelector("[autofocus], input, button, a[href], select, textarea") ?? this.panel
    target.focus()
  },

  close(returnFocus) {
    if (this.panel.hidden) return
    this.panel.hidden = true
    this.trigger.setAttribute("aria-expanded", "false")
    returnFocus && (this.trigger.querySelector("button, a, [tabindex]") ?? this.trigger).focus()
  },

  place() {
    const anchor = this.el.getBoundingClientRect()
    const side = chooseSide(this.el.dataset.placement, {
      panel: this.panel.getBoundingClientRect().height,
      above: anchor.top,
      below: window.innerHeight - anchor.bottom,
    })
    this.panel.dataset.side = side
    this.arrow.dataset.side = side
  },
}
