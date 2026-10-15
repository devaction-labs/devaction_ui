import {counts} from "./filter_logic.js"
import {runKey, wrap} from "./keys.js"

/**
 * A button that opens a menu of groups; a group opens a submenu of ticks (checkboxes or radios). Ticking
 * does not close it: the form inside sends on Apply, or the server hears `phx-change`. Counts on each group
 * and on the button follow the ticks. ↑ ↓ Home End move, → opens a submenu, ← and Esc go back, Enter and
 * Space tick. Everything is delegated from the root, so a LiveView patch cannot orphan a listener.
 */
export default {
  mounted() {
    this.trigger = this.el.querySelector("[data-menu-trigger]")
    this.menu = this.el.querySelector("[data-menu]")
    this.el.addEventListener("click", (event) => this.onClick(event))
    this.el.addEventListener("mouseover", (event) => this.onHover(event))
    this.el.addEventListener("change", () => this.count())
    this.el.addEventListener("keydown", (event) => this.onKey(event))
    this.el.addEventListener("submit", () => this.close(false))
    this.outside = (event) => this.isOpen() && !this.el.contains(event.target) && this.close(false)
    document.addEventListener("pointerdown", this.outside)
    this.count()
  },

  destroyed() {
    document.removeEventListener("pointerdown", this.outside)
  },

  isOpen: function () {
    return !this.menu.hidden
  },

  subs() {
    return [...this.el.querySelectorAll("[data-submenu]")]
  },

  items(container) {
    return [...container.querySelectorAll("[role^=menuitem]")].filter(
      (item) => item.closest("[data-submenu], [data-menu]") === container,
    )
  },

  open() {
    this.menu.hidden = false
    this.trigger.setAttribute("aria-expanded", "true")
    this.items(this.menu)[0]?.focus()
  },

  close(refocus = true) {
    this.menu.hidden = true
    this.closeSubs()
    this.trigger.setAttribute("aria-expanded", "false")
    refocus && this.trigger.focus()
  },

  closeSubs(keep) {
    this.subs().forEach((sub) => (sub.hidden = sub.dataset.submenu !== keep))
    this.el
      .querySelectorAll("[data-submenu-trigger]")
      .forEach((row) => row.setAttribute("aria-expanded", String(row.dataset.submenuTrigger === keep)))
  },

  openSub(id, focus = false) {
    this.closeSubs(id)
    const sub = this.subs().find((candidate) => candidate.dataset.submenu === id)
    const row = this.el.querySelector(`[data-submenu-trigger="${id}"]`)
    sub.style.top = `${row.offsetTop - 6}px`
    focus && this.items(sub)[0]?.focus()
  },

  backToRow(sub) {
    const id = sub.dataset.submenu
    this.closeSubs()
    this.el.querySelector(`[data-submenu-trigger="${id}"]`)?.focus()
  },

  onClick(event) {
    const target = (selector) => event.target.closest(selector)
    const actions = [
      ["[data-menu-trigger]", () => (this.isOpen() ? this.close() : this.open())],
      ["[data-submenu-trigger]", (row) => this.openSub(row.dataset.submenuTrigger, true)],
      ["[data-menu-reset]", () => this.reset()],
      ["[data-menu-close]", () => this.close()],
    ]
    const hit = actions.find(([selector]) => target(selector))
    hit && hit[1](target(hit[0]))
  },

  onHover(event) {
    const row = event.target.closest("[data-menu] [role=menuitem]")
    const isSubmenuRow = row?.dataset.submenuTrigger !== undefined
    row && (isSubmenuRow ? this.openSub(row.dataset.submenuTrigger) : this.closeSubs())
  },

  reset() {
    this.el.querySelectorAll("input[data-group]").forEach((input) => (input.checked = input.hasAttribute("data-default")))
    this.count()
    this.el.querySelector("form")?.dispatchEvent(new Event("change", {bubbles: true}))
  },

  count() {
    this.el.querySelectorAll("[role=menuitemcheckbox], [role=menuitemradio]").forEach((row) => {
      const input = row.querySelector("input")
      input && row.setAttribute("aria-checked", String(input.checked))
    })
    const options = [...this.el.querySelectorAll("input[data-group]")].map((input) => ({
      group: input.dataset.group,
      checked: input.checked,
      isDefault: input.hasAttribute("data-default"),
    }))
    const {byGroup, total} = counts(options)
    this.el.querySelectorAll("[data-count-for]").forEach((badge) => {
      const n = byGroup[badge.dataset.countFor] ?? 0
      badge.textContent = n
      badge.hidden = n === 0
    })
    this.el.querySelectorAll("[data-count-total]").forEach((badge) => {
      badge.textContent = total
      badge.hidden = total === 0
    })
  },

  onKey(event) {
    if (!this.isOpen()) return
    const sub = event.target.closest("[data-submenu]")
    const list = this.items(sub ?? this.menu)
    const at = list.indexOf(document.activeElement)
    const focusAt = (to) => () => list[to(at, list.length)]?.focus()
    const tick = () => {
      const input = event.target.querySelector?.("input[type=checkbox], input[type=radio]")
      if (!input) return false
      input.checked = input.type === "radio" ? true : !input.checked
      input.dispatchEvent(new Event("change", {bubbles: true}))
    }

    runKey(
      {
        ArrowDown: focusAt((i, n) => wrap(i, 1, n)),
        ArrowUp: focusAt((i, n) => wrap(i, -1, n)),
        Home: focusAt(() => 0),
        End: focusAt((_i, n) => n - 1),
        ArrowRight: () => (sub || !event.target.dataset.submenuTrigger ? false : this.openSub(event.target.dataset.submenuTrigger, true)),
        ArrowLeft: () => (sub ? this.backToRow(sub) : false),
        Escape: () => (sub ? this.backToRow(sub) : this.close()),
        Enter: tick,
        " ": tick,
      },
      event,
    )
  },
}
