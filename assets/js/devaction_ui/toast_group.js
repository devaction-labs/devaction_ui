import {runKey} from "./keys.js"
import {countText, escapeStep, HOVER_CLOSE_MS, hoverStep, layerCount, planLayout, stackPadding, styleFor} from "./toast_logic.js"

/**
 * Notices that pile up without covering the screen: a toast with up to two layers peeking out above it
 * while there are several, a panel with a heading, "Collapse" and "Clear" when opened. The pile opens by
 * itself while the pointer or the focus is on it and closes a moment after they leave; a click opens it for
 * good (until "Collapse"), which is also what a tap does. A toast closes by itself after its `data-duration` (0
 * keeps it), the timers pausing while the pointer or the focus is in the group or the list is open. Closing
 * one or clearing all is told to the LiveView (`data-on-dismiss`, `data-on-clear`), which is the source of
 * truth for what is shown. Escape closes the open list, or the toast the focus is on.
 */
export default {
  mounted() {
    this.timers = new Map()
    this.paused = false
    this.auto = false
    this.el.addEventListener("click", (event) => this.onClick(event))
    this.el.addEventListener("keydown", (event) => this.onKey(event))
    ;["mouseenter", "focusin"].forEach((name) =>
      this.el.addEventListener(name, () => (this.pause(true), this.hover("enter"))),
    )
    ;["mouseleave", "focusout"].forEach((name) =>
      this.el.addEventListener(name, () => (this.pause(false), this.hover("leave"))),
    )
    this.layout()
  },

  updated() {
    this.layout()
  },

  destroyed() {
    this.timers.forEach((timer) => clearTimeout(timer))
    clearTimeout(this.leaving)
  },

  hover(event) {
    clearTimeout(this.leaving)
    const state = {event, stacked: this.el.dataset.stacked === "true", expanded: this.expanded(), auto: this.auto}
    const steps = {
      open: () => ((this.auto = true), this.expand(true)),
      close: () => (this.leaving = setTimeout(() => ((this.auto = false), this.expand(false)), HOVER_CLOSE_MS)),
      null: () => false,
    }
    steps[hoverStep(state)]()
  },

  toasts() {
    return [...this.el.querySelectorAll("[data-toast]")]
  },

  expanded() {
    return this.el.dataset.expanded === "true"
  },

  onClick(event) {
    const on = (selector) => event.target.closest(selector)
    const actions = [
      ["[data-dismiss]", (button) => this.dismiss(button.closest("[data-toast]"))],
      ["[data-clear]", () => this.clear()],
      ["[data-collapse]", () => ((this.auto = false), this.expand(false))],
      ["[data-expand]", () => ((this.auto = false), this.expand(true))],
      // A click on a stacked toast opens the stack; on an open one it does nothing.
      ["[data-toast]", () => ((this.auto = false), !this.expanded() && this.expand(true))],
    ]
    const [selector, act] = actions.find(([candidate]) => on(candidate)) ?? []
    selector && act(on(selector))
  },

  onKey(event) {
    const focused = event.target.closest("[data-toast]")
    const steps = {collapse: () => this.expand(false), dismiss: () => this.dismiss(focused), null: () => false}
    runKey({Escape: () => steps[escapeStep({expanded: this.expanded(), focused: Boolean(focused)})]()}, event)
  },

  expand(open) {
    this.el.dataset.expanded = String(open)
    this.layout()
  },

  pause(on) {
    this.paused = on
    this.schedule()
  },

  dismiss(toast) {
    this.pushEventTo(this.el, this.el.dataset.onDismiss, {id: toast.id})
    toast.remove()
    this.layout()
  },

  clear() {
    this.toasts().forEach((toast) => toast.remove())
    this.pushEventTo(this.el, this.el.dataset.onClear, {})
    this.layout()
  },

  layout() {
    const toasts = this.toasts()
    const plan = planLayout({count: toasts.length, expanded: this.expanded()})
    this.el.dataset.expanded = String(plan.expanded)

    const bar = this.el.querySelector("[data-bar]")
    bar.hidden = !plan.showBar
    this.el.querySelector("[data-expand]").hidden = !plan.showExpand
    bar.querySelector("[data-count]").textContent = countText({
      heading: this.el.dataset.heading,
      label: this.el.dataset.countLabel,
      count: toasts.length,
    })
    const layers = plan.stacked ? layerCount(toasts.length) : 0
    this.el.dataset.stacked = String(plan.stacked)
    this.el.querySelectorAll("[data-layer]").forEach((layer) => (layer.hidden = Number(layer.dataset.layer) > layers))

    toasts.forEach((toast, index) => this.style(toast, index, plan.stacked))
    this.el.style.paddingTop = plan.stacked ? stackPadding(toasts.length) : ""
    this.schedule()
  },

  style(toast, index, stacked) {
    const behind = stacked && index > 0
    Object.assign(toast.style, styleFor({index, stacked}))
    toast.toggleAttribute("aria-hidden", behind)
    toast.inert = behind
  },

  schedule() {
    const alive = new Set(this.toasts().map((toast) => toast.id))
    this.timers.forEach((timer, id) => alive.has(id) || (clearTimeout(timer), this.timers.delete(id)))

    const hold = this.paused || this.expanded()
    this.toasts().forEach((toast) => {
      const ms = Number.parseInt(toast.dataset.duration, 10)
      const waiting = this.timers.has(toast.id)
      const stop = hold || !ms
      stop && waiting && (clearTimeout(this.timers.get(toast.id)), this.timers.delete(toast.id))
      stop || waiting || this.timers.set(toast.id, setTimeout(() => this.expire(toast.id), ms))
    })
  },

  expire(id) {
    this.timers.delete(id)
    const toast = document.getElementById(id)
    toast && this.dismiss(toast)
  },
}
