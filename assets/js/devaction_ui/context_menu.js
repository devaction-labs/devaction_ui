import {runKey, wrap} from "./keys.js"
import {asksForContextMenu, extendBuffer, isTypeahead, keyboardAnchor, matchIndex} from "./menu_logic.js"
import {placeAtPoint, screenSize} from "./placement.js"

const ITEM = '[role^="menuitem"]:not([aria-disabled="true"])'

/**
 * The menu of `ContextMenu`: a right click on the target area, or Shift + F10 (or the menu key) while the focus is
 * in it, opens the menu at the pointer (at the focused element for the keyboard) and keeps it on the screen,
 * opening to the left or upwards when it would leave it. ↑ ↓ Home End move round the items (the first letters
 * jump to an item), Enter or Space chooses, Esc closes and gives the focus back to where it was, Tab, a click
 * outside, a scroll and a resize close it, and choosing an item closes it. The target carries `data-open` while
 * the menu is open, so the row can show which one it belongs to.
 */
export default {
  mounted() {
    this.area = this.el.querySelector("[data-target]")
    this.menu = this.el.querySelector("[data-context-menu]")

    this.area.addEventListener("contextmenu", (event) => this.onContext(event))
    this.area.addEventListener("keydown", (event) => asksForContextMenu(event) && this.onAsk(event))
    this.menu.addEventListener("keydown", (event) => this.onMenuKey(event))
    this.menu.addEventListener("click", (event) => event.target.closest(ITEM) && this.close(true))

    this.outside = (event) => !this.menu.contains(event.target) && this.close(false)
    this.leave = () => this.close(false)
    document.addEventListener("pointerdown", this.outside, true)
    window.addEventListener("resize", this.leave)
    window.addEventListener("blur", this.leave)
    document.addEventListener("scroll", this.leave, true)
  },

  destroyed() {
    document.removeEventListener("pointerdown", this.outside, true)
    window.removeEventListener("resize", this.leave)
    window.removeEventListener("blur", this.leave)
    document.removeEventListener("scroll", this.leave, true)
  },

  items() {
    return [...this.menu.querySelectorAll(ITEM)]
  },

  focusItem(index) {
    this.items()[index]?.focus()
  },

  inNestedMenu(event) {
    return event.target.closest?.('[role="menu"]') !== null
  },

  onContext(event) {
    this.inNestedMenu(event) || (event.preventDefault(), this.open({x: event.clientX, y: event.clientY}, false))
  },

  onAsk(event) {
    event.preventDefault()
    const anchor = document.activeElement?.closest?.("[data-target] *") ?? this.area
    this.open(keyboardAnchor(anchor.getBoundingClientRect()), true)
  },

  open(point, byKeyboard) {
    this.close(false)
    this.returnTo = document.activeElement
    this.menu.style.visibility = "hidden"
    this.menu.hidden = false
    const {left, top} = placeAtPoint(point, {width: this.menu.offsetWidth, height: this.menu.offsetHeight}, screenSize())
    this.menu.style.left = `${left}px`
    this.menu.style.top = `${top}px`
    this.menu.style.visibility = ""
    this.area.setAttribute("data-open", "")
    byKeyboard ? this.focusItem(0) : this.menu.focus()
  },

  close(returnFocus) {
    if (this.menu.hidden) return
    this.menu.hidden = true
    this.area.removeAttribute("data-open")
    returnFocus && (this.returnTo?.isConnected ? this.returnTo : this.area).focus?.()
  },

  onMenuKey(event) {
    const items = this.items()
    const at = items.indexOf(document.activeElement)
    const go = (index) => () => this.focusItem(index)

    const handled = runKey(
      {
        ArrowDown: go(wrap(at, 1, items.length)),
        ArrowUp: go(wrap(at, -1, items.length)),
        Home: go(0),
        End: go(items.length - 1),
        Escape: () => this.close(true),
        Tab: () => {
          this.close(true)
          return false
        },
      },
      event,
    )

    handled || (isTypeahead(event) && this.typeahead(event, items))
  },

  typeahead(event, items) {
    const now = Date.now()
    this.typed = extendBuffer(this.typed ?? "", event.key, now - (this.typedAt ?? 0))
    this.typedAt = now
    const labels = items.map((item) => item.textContent)
    this.focusItem(matchIndex(labels, items.indexOf(document.activeElement), this.typed))
  },
}
