import {runKey, wrap} from "./keys.js"

/**
 * The keys and the opening of `Dropdown`: the button opens the menu and puts the focus on the chosen item
 * (or the first); ↑ ↓ move round the items, Home and End go to the ends, Esc closes and gives the focus
 * back to the button, Tab closes, a click outside closes, and choosing an item closes it. Items are the
 * `[role^="menuitem"]` buttons and links; the server draws which one is checked.
 */
export default {
  mounted() {
    this.trigger = this.el.querySelector("[data-trigger]")
    this.menu = this.el.querySelector("[data-menu]")

    this.trigger.addEventListener("click", () => (this.menu.hidden ? this.open() : this.close(true)))
    this.trigger.addEventListener("keydown", (event) => this.onTriggerKey(event))
    this.menu.addEventListener("keydown", (event) => this.onMenuKey(event))
    this.menu.addEventListener("click", (event) => event.target.closest('[role^="menuitem"]') && this.close(true))
    this.outside = (event) => !this.el.contains(event.target) && this.close(false)
    document.addEventListener("mousedown", this.outside)
  },

  destroyed() {
    document.removeEventListener("mousedown", this.outside)
  },

  items() {
    return [...this.menu.querySelectorAll('[role^="menuitem"]')]
  },

  focusItem(index) {
    this.items()[index]?.focus()
  },

  onTriggerKey(event) {
    const openAt = (where) => () => {
      this.open()
      this.focusItem(where === "last" ? this.items().length - 1 : 0)
    }
    runKey({ArrowDown: openAt("first"), ArrowUp: openAt("last")}, event)
  },

  onMenuKey(event) {
    const items = this.items()
    const at = items.indexOf(document.activeElement)
    const go = (index) => () => this.focusItem(index)

    runKey(
      {
        ArrowDown: go(wrap(at, 1, items.length)),
        ArrowUp: go(wrap(at, -1, items.length)),
        Home: go(0),
        End: go(items.length - 1),
        Escape: () => this.close(true),
        Tab: () => {
          this.close(false)
          return false
        },
      },
      event,
    )
  },

  open() {
    this.menu.hidden = false
    this.trigger.setAttribute("aria-expanded", "true")
    const chosen = this.items().findIndex((item) => item.getAttribute("aria-checked") === "true")
    this.focusItem(Math.max(chosen, 0))
  },

  close(returnFocus) {
    if (this.menu.hidden) return
    this.menu.hidden = true
    this.trigger.setAttribute("aria-expanded", "false")
    returnFocus && this.trigger.focus()
  },
}
