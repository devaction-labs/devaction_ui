import {runKey, tabExit} from "./keys.js"
import {arrowShift, clampShift, fixedCorner, flipSide, roomAround, screenSize} from "./placement.js"
import {FOCUSABLE} from "./tooltip_logic.js"

/** Above the modal (70), because a panel in a portal is usually opened from inside one. */
const PORTAL_Z = "80"

/**
 * A panel anchored to a trigger: the trigger opens and closes it, Esc and a press outside close it, focus
 * goes into the panel when it opens and back to the trigger when it is closed with the keyboard or the
 * trigger. It flips to the opposite side when there is no room on the screen and is shifted along the edge
 * to stay inside it, with the arrow still on the trigger. Tab past the last control closes it and the focus
 * goes on; Shift+Tab before the first one closes it and the focus goes back to the trigger.
 *
 * With `data-portal` the panel is moved to the end of `document.body` while it is open and drawn with
 * `position: fixed` from the rectangle of the trigger, so no ancestor with `overflow` can clip it.
 */
export default {
  mounted() {
    this.trigger = this.el.querySelector("[data-trigger]")
    this.panel = this.el.querySelector("[data-panel]")
    this.arrow = this.panel.querySelector("[data-arrow]")
    this.portal = this.el.hasAttribute("data-portal")

    this.trigger.addEventListener("click", () => this.toggle())
    this.trigger.addEventListener("keydown", (event) => {
      const own = () => event.target === this.trigger && this.toggle()
      runKey({Enter: own, " ": own, Tab: () => this.enter(event)}, event)
    })
    this.announce()
    this.el.addEventListener("keydown", (event) => this.onKey(event))
    this.panel.addEventListener("keydown", (event) => this.onPanelKey(event))
    this.outside = (event) => !this.el.contains(event.target) && !this.panel.contains(event.target) && this.close(false)
    this.reflow = () => !this.panel.hidden && this.place()
    document.addEventListener("pointerdown", this.outside)
  },

  beforeUpdate() {
    this.portal && !this.panel.hidden && this.el.appendChild(this.panel)
  },

  updated() {
    this.portal && !this.panel.hidden && document.body.appendChild(this.panel)
    this.announce()
  },

  control() {
    return this.trigger.querySelector("button, a[href], [tabindex]") ?? this.trigger
  },

  toggle() {
    this.panel.hidden ? this.open() : this.close(true)
  },

  announce() {
    const control = this.control()
    control === this.trigger && (control.setAttribute("role", "button"), control.tabIndex = 0)
    control.setAttribute("aria-haspopup", "dialog")
    control.setAttribute("aria-controls", this.panel.id)
    control.setAttribute("aria-expanded", String(!this.panel.hidden))
  },

  destroyed() {
    document.removeEventListener("pointerdown", this.outside)
    window.removeEventListener("resize", this.reflow)
    window.removeEventListener("scroll", this.reflow, true)
    this.panel.remove()
  },

  focusables() {
    return [...this.panel.querySelectorAll(FOCUSABLE)]
  },

  onKey(event) {
    runKey({Escape: () => this.dismiss(event)}, event)
  },

  onPanelKey(event) {
    runKey({Escape: () => this.dismiss(event), Tab: () => this.leave(event)}, event)
  },

  dismiss(event) {
    // A closed popover declines Esc, so it reaches whatever is around it.
    if (this.panel.hidden) return false
    event.stopPropagation()
    this.close(true)
  },

  leave(event) {
    const items = this.focusables()
    const exit = tabExit({
      shift: event.shiftKey,
      active: document.activeElement,
      first: items[0] ?? this.panel,
      last: items.at(-1) ?? this.panel,
    })
    const exits = {
      forward: () => (this.close(true), false),
      back: () => (this.close(true), true),
    }
    return exits[exit]?.() ?? false
  },

  enter(event) {
    const into = this.portal && !this.panel.hidden && !event.shiftKey
    into && (this.focusables()[0] ?? this.panel).focus()
    return into || false
  },

  open() {
    this.panel.hidden = false
    this.portal && document.body.appendChild(this.panel)
    this.place()
    this.announce()
    window.addEventListener("resize", this.reflow)
    window.addEventListener("scroll", this.reflow, true)
    const target = this.panel.querySelector("[autofocus], input, button, a[href], select, textarea") ?? this.panel
    target.focus({preventScroll: true})
  },

  close(returnFocus) {
    if (this.panel.hidden) return
    this.panel.hidden = true
    this.portal && this.el.appendChild(this.panel)
    this.panel.removeAttribute("style")
    this.arrow.removeAttribute("style")
    window.removeEventListener("resize", this.reflow)
    window.removeEventListener("scroll", this.reflow, true)
    this.announce()
    returnFocus && this.control().focus()
  },

  place() {
    const anchor = this.el.getBoundingClientRect()
    const screen = screenSize()
    this.panel.style.translate = ""
    this.arrow.style.translate = ""
    this.portal && this.pin()
    const size = this.panel.getBoundingClientRect()
    const side = flipSide(this.el.dataset.placement, size, roomAround(anchor, screen))
    this.panel.dataset.side = side
    this.arrow.dataset.side = side
    const vertical = side === "top" || side === "bottom"
    const arrowCenter = this.arrowCenter(vertical)
    const shift = this.portal
      ? this.fix(fixedCorner({side, align: this.el.dataset.align, anchor, panel: size, screen}), vertical)
      : this.slide(vertical, screen)
    const moves = {true: (by) => `${by}px 0`, false: (by) => `0 ${by}px`}
    this.arrow.style.translate = moves[vertical](arrowShift(shift, {center: arrowCenter, size: vertical ? size.width : size.height}))
  },

  pin() {
    Object.assign(this.panel.style, {position: "fixed", right: "auto", bottom: "auto", margin: "0", zIndex: PORTAL_Z})
  },

  fix(corner, vertical) {
    Object.assign(this.panel.style, {top: `${corner.top}px`, left: `${corner.left}px`})
    return vertical ? corner.shiftX : corner.shiftY
  },

  slide(vertical, screen) {
    const rect = this.panel.getBoundingClientRect()
    const by = vertical ? clampShift(rect.left, rect.width, screen.width) : clampShift(rect.top, rect.height, screen.height)
    this.panel.style.translate = vertical ? `${by}px 0` : `0 ${by}px`
    return by
  },

  arrowCenter(vertical) {
    const panel = this.panel.getBoundingClientRect()
    const arrow = this.arrow.getBoundingClientRect()
    return vertical ? arrow.left + arrow.width / 2 - panel.left : arrow.top + arrow.height / 2 - panel.top
  },
}
