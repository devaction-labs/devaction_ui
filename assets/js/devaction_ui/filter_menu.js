import {counts, pendingCount, resetAction, submenuSide} from "./filter_logic.js"
import {runKey, wrap} from "./keys.js"

/**
 * A button that opens a menu of groups; a group opens a submenu of ticks (checkboxes or radios). Ticking
 * does not close it: the form inside sends on Apply, or the server hears `phx-change`. The counts on each
 * group follow the ticks of the draft; the count on the button follows the filters that were APPLIED (what
 * the form sent last, or every tick when the form has `phx-change`), and Apply shows how many changes it
 * would send. ↑ ↓ Home End move, → opens a submenu (on the other side when there is no room), ← and Esc go
 * back, Enter and Space tick. Applying gives the focus back to the button, and the menu closes when the
 * focus leaves it. Clear unticks everything and then either tells the form it changed or, with
 * `data-reset="submit"`, submits it, which sends the empty filters and applies them. Everything is delegated from the root, so a LiveView patch cannot orphan a listener.
 */
export default {
  mounted() {
    this.trigger = this.el.querySelector("[data-menu-trigger]")
    this.menu = this.el.querySelector("[data-menu]")
    this.applied = this.snapshot()
    this.el.addEventListener("click", (event) => this.onClick(event))
    this.el.addEventListener("mouseover", (event) => this.onHover(event))
    this.el.addEventListener("change", () => this.onChange())
    this.el.addEventListener("keydown", (event) => this.onKey(event))
    this.el.addEventListener("submit", () => this.onSubmit())
    this.el.addEventListener("focusout", (event) => this.onFocusOut(event))
    this.outside = (event) => this.isOpen() && !this.el.contains(event.target) && this.close(false)
    document.addEventListener("pointerdown", this.outside)
    this.count()
  },

  updated() {
    this.isOpen() || (this.applied = this.snapshot())
    this.count()
  },

  destroyed() {
    document.removeEventListener("pointerdown", this.outside)
  },

  isOpen: function () {
    return !this.menu.hidden
  },

  live() {
    return this.menu.hasAttribute("phx-change")
  },

  snapshot() {
    return [...this.el.querySelectorAll("input[data-group]")].map((input) => ({
      group: input.dataset.group,
      value: input.value,
      checked: input.checked,
      isDefault: input.hasAttribute("data-default"),
    }))
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
    const panel = this.menu.getBoundingClientRect()
    const room = {panel: sub.offsetWidth, left: panel.left, right: window.innerWidth - panel.right}
    sub.dataset.side = submenuSide(sub.dataset.align, room)
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

  onChange() {
    this.live() && (this.applied = this.snapshot())
    this.count()
  },

  onSubmit() {
    this.applied = this.snapshot()
    this.count()
    this.close(true)
  },

  onFocusOut(event) {
    const to = event.relatedTarget
    this.isOpen() && to && !this.el.contains(to) && this.close(false)
  },

  reset() {
    this.el.querySelectorAll("input[data-group]").forEach((input) => (input.checked = input.hasAttribute("data-default")))
    this.count()
    const form = this.el.querySelector("form")
    const actions = {
      submit: () => form.requestSubmit(),
      change: () => form.dispatchEvent(new Event("change", {bubbles: true})),
    }
    actions[resetAction(this.el.dataset.reset)]()
  },

  count() {
    this.el.querySelectorAll("[role=menuitemcheckbox], [role=menuitemradio]").forEach((row) => {
      const input = row.querySelector("input")
      input && row.setAttribute("aria-checked", String(input.checked))
    })
    const draft = this.snapshot()
    const {byGroup} = counts(draft)
    this.el.querySelectorAll("[data-count-for]").forEach((badge) => {
      const n = byGroup[badge.dataset.countFor] ?? 0
      badge.textContent = n
      badge.hidden = n === 0
    })
    const {total} = counts(this.applied)
    this.el.querySelectorAll("[data-count-total]").forEach((badge) => {
      badge.textContent = total
      badge.hidden = total === 0
    })
    const pending = pendingCount(draft, this.applied)
    this.el.querySelectorAll("[data-count-pending]").forEach((badge) => {
      badge.textContent = pending
      badge.hidden = pending === 0
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
