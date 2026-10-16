import {runKey} from "./keys.js"
import {dividerEnd, dividerKey, dividerValues, limit, moveDivider, pixelsToPercent, resetDivider, startSizes} from "./resizable_logic.js"

const AXIS = {
  horizontal: {pointer: "clientX", length: "offsetWidth"},
  vertical: {pointer: "clientY", length: "offsetHeight"},
}

/**
 * A group of panels with dividers between them. Drag a divider (a mouse, a pen or a finger), or focus it and press
 * ← → (↑ ↓ in a vertical group; Shift takes a larger step) and Home or End to go to its limits; a double click shares
 * the two panels around it equally. The panels follow at once (their `flex` is the size in percent) and nothing is
 * stored: when a move ends (the pointer is released, a key is let go) the LiveView gets one event with
 * `{sizes: {panelId: percent}}`, and keeps it or not. Each divider says the size of the panel before it
 * (`aria-valuenow`) and the limits it can go to (`aria-valuemin`, `aria-valuemax`), and any `[data-size-value]`
 * inside a panel shows that panel's size as a number. When the server gives other `data-size`s the panels take them.
 */
export default {
  mounted() {
    this.axis = AXIS[this.el.dataset.orientation] ?? AXIS.horizontal
    this.read()
    this.apply()

    this.el.addEventListener("pointerdown", (event) => this.onPress(event))
    this.el.addEventListener("keydown", (event) => this.onKey(event))
    this.el.addEventListener("keyup", (event) => event.target.closest("[data-divider]") && this.settle())
    this.el.addEventListener("dblclick", (event) => this.onReset(event))
    this.el.addEventListener("selectstart", (event) => this.press && event.preventDefault())
  },

  updated() {
    const given = this.given()
    this.seen === given.join(",") || this.read()
    this.apply()
  },

  destroyed() {
    this.release(false)
  },

  panels() {
    return [...this.el.querySelectorAll(":scope > [data-panel]")]
  },

  dividers() {
    return [...this.el.querySelectorAll(":scope > [data-divider]")]
  },

  given() {
    return this.panels().map((panel) => panel.dataset.size ?? "")
  },

  read() {
    const panels = this.panels()
    this.seen = this.given().join(",")
    this.sizes = startSizes(panels.map((panel) => panel.dataset.size))
    this.limits = panels.map((panel) => ({min: limit(panel.dataset.min, 0), max: limit(panel.dataset.max, 100)}))
    this.sent = this.sizes
  },

  apply() {
    this.panels().forEach((panel, index) => {
      panel.style.flex = `${this.sizes[index]} 1 0%`
      panel.querySelectorAll("[data-size-value]").forEach((text) => (text.textContent = String(Math.round(this.sizes[index]))))
    })
    this.dividers().forEach((divider, index) => {
      const {now, min, max} = dividerValues(this.sizes, index, this.limits)
      divider.setAttribute("aria-valuenow", String(now))
      divider.setAttribute("aria-valuemin", String(min))
      divider.setAttribute("aria-valuemax", String(max))
    })
  },

  change(sizes) {
    this.sizes = sizes
    this.apply()
  },

  settle() {
    const changed = this.sizes.some((size, index) => size !== this.sent[index])
    this.sent = this.sizes
    const sizes = Object.fromEntries(this.panels().map((panel, index) => [panel.dataset.id, this.sizes[index]]))
    changed && this.pushEventTo(this.el, this.el.dataset.event, {sizes})
  },

  indexOf(divider) {
    return this.dividers().indexOf(divider)
  },

  // -- the pointer

  onPress(event) {
    const divider = event.target.closest("[data-divider]")
    if (!divider || this.press || !event.isPrimary || event.button > 0) return

    const room = this.el[this.axis.length] - this.dividers().reduce((sum, each) => sum + each[this.axis.length], 0)
    this.press = {divider, id: event.pointerId, from: event[this.axis.pointer], sizes: this.sizes, room, index: this.indexOf(divider)}
    divider.setAttribute("data-dragging", "")
    this.listeners = {
      pointermove: (move) => move.pointerId === this.press?.id && this.onMove(move),
      pointerup: (up) => up.pointerId === this.press?.id && this.release(true),
      pointercancel: (cancel) => cancel.pointerId === this.press?.id && this.release(false),
      keydown: (key) => runKey({Escape: () => this.press && this.release(false)}, key),
    }
    Object.entries(this.listeners).forEach(([type, handler]) => document.addEventListener(type, handler))
    event.preventDefault()
    divider.focus()
  },

  onMove(event) {
    const {sizes, index, room, from} = this.press
    this.change(moveDivider(sizes, index, pixelsToPercent(event[this.axis.pointer] - from, room), this.limits))
  },

  release(commit) {
    const press = this.press
    if (!press) return
    Object.entries(this.listeners ?? {}).forEach(([type, handler]) => document.removeEventListener(type, handler))
    press.divider.removeAttribute("data-dragging")
    this.press = null
    this.listeners = null
    commit ? this.settle() : this.change(press.sizes)
  },

  // -- the keyboard and the double click

  onKey(event) {
    const divider = event.target.closest("[data-divider]")
    if (!divider) return
    const index = this.indexOf(divider)
    const move = dividerKey(event.key, event.shiftKey, this.el.dataset.orientation)
    const next = {
      delta: () => moveDivider(this.sizes, index, move.delta, this.limits),
      to: () => dividerEnd(this.sizes, index, this.limits, move.to),
    }

    move && runKey({[event.key]: () => this.change(Object.entries(next).find(([key]) => key in move)[1]())}, event)
  },

  onReset(event) {
    const divider = event.target.closest("[data-divider]")
    divider && (this.change(resetDivider(this.sizes, this.indexOf(divider), this.limits)), this.settle())
  },
}
