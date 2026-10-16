import {runKey} from "./keys.js"
import {placeTip, screenSize} from "./placement.js"
import {FOCUSABLE, afterTimer, isShown, settle, tapOpens, withDescription} from "./tooltip_logic.js"

const DEFAULT_OPEN = 400
const DEFAULT_CLOSE = 150

/**
 * The timing and the keeping on the screen of `HoverCard`. The card opens when the pointer has rested on the
 * trigger for `data-open-delay` ms (400 by default) or at once when the keyboard focus reaches it, and closes
 * after `data-close-delay` ms once the pointer and the focus have both left, so the pointer can cross the gap
 * and rest on the card (the card is inside the element the pointer leaves, so it counts as the trigger). Esc
 * closes it and is never consumed, so it still reaches a dialog around it; it comes back after the pointer and
 * the focus have left. On a touch screen a tap on the trigger opens it (the link under the finger does not go)
 * and a tap anywhere else closes it. The card flips to the other side and slides along the trigger when it
 * would leave the window. The decisions are in `tooltip_logic.js`.
 */
export default {
  mounted() {
    this.card = this.el.querySelector("[data-card]")
    this.trigger = this.el.querySelector("[data-trigger]")
    this.phase = "closed"
    this.state = {pointer: false, focus: false, dismissed: false}

    this.el.addEventListener("pointerenter", (event) => event.pointerType === "touch" || this.hold({pointer: true}))
    this.el.addEventListener("pointerleave", (event) => event.pointerType === "touch" || this.hold({pointer: false}))
    this.el.addEventListener("focusin", () => this.hold({focus: true}))
    this.el.addEventListener("focusout", (event) => this.el.contains(event.relatedTarget) || this.hold({focus: false}))
    this.el.addEventListener("keydown", (event) => runKey({Escape: () => this.dismiss()}, event))
    this.trigger.addEventListener("pointerdown", (event) => (this.tapped = tapOpens(event.pointerType, this.phase)))
    this.trigger.addEventListener("click", (event) => this.onClick(event), true)

    this.outside = (event) => event.pointerType === "touch" && !this.el.contains(event.target) && this.hold({pointer: false})
    document.addEventListener("pointerdown", this.outside)
    this.describe()
  },

  updated() {
    this.describe()
    this.render()
  },

  destroyed() {
    clearTimeout(this.timer)
    document.removeEventListener("pointerdown", this.outside)
  },

  describe() {
    const control = this.trigger.querySelector(FOCUSABLE) ?? this.trigger
    control.matches(FOCUSABLE) || control.setAttribute("tabindex", "0")
    control.setAttribute("aria-describedby", withDescription(control.getAttribute("aria-describedby"), this.card.id))
  },

  delay(name) {
    const fallback = {open: DEFAULT_OPEN, close: DEFAULT_CLOSE}[name]
    const value = Number.parseInt(this.el.dataset[`${name}Delay`] ?? "", 10)
    return Number.isNaN(value) ? fallback : value
  },

  hold(changes) {
    this.state = {...this.state, ...changes}
    const idle = !this.state.pointer && !this.state.focus
    this.state.dismissed = this.state.dismissed && !idle
    const next = settle({phase: this.phase, ...this.state})
    this.phase = next.phase

    const schedules = {
      open: () => this.after("open"),
      close: () => this.after("close"),
      now: () => clearTimeout(this.timer),
      cancel: () => clearTimeout(this.timer),
      none: () => {},
    }
    schedules[next.schedule]()
    this.render()
  },

  after(name) {
    clearTimeout(this.timer)
    this.timer = setTimeout(() => {
      this.phase = afterTimer(this.phase, name)
      this.render()
    }, this.delay(name))
  },

  onClick(event) {
    const tapped = this.tapped
    this.tapped = false
    tapped && (event.preventDefault(), event.stopPropagation(), this.tap())
  },

  tap() {
    this.state = {...this.state, pointer: true, dismissed: false}
    this.phase = "open"
    clearTimeout(this.timer)
    this.render()
  },

  dismiss() {
    isShown(this.phase) && this.hold({dismissed: true})
    return false
  },

  render() {
    const shown = isShown(this.phase)
    const was = this.card.dataset.state === "open"
    this.card.dataset.state = shown ? "open" : "closed"
    shown && !was && this.place()
  },

  place() {
    const {side, shift} = placeTip(this.card.dataset.placement, {
      tip: {width: this.card.offsetWidth, height: this.card.offsetHeight},
      trigger: this.trigger.getBoundingClientRect(),
      viewport: screenSize(),
    })
    this.card.dataset.side = side
    this.card.style.setProperty("--card-shift", `${shift}px`)
  },
}
