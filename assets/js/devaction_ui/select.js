import {notify} from "./dom.js"
import {runKey} from "./keys.js"
import {isTypeKey, moveActive, placePanel, readItems, startIndex, typeAhead, typedText} from "./select_logic.js"

/** Above the modal (70), because a select is often inside one. */
const PORTAL_Z = "80"

const CHECK =
  '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M5 12.5l4.5 4.5L19 7.5"/></svg>'

const element = (tag, className, text) => {
  const node = document.createElement(tag)
  node.className = className
  text !== undefined && (node.textContent = text)
  return node
}

/**
 * The styled list of `DevactionUI.Select`. The native `<select>` stays the field (name, value, validation,
 * `phx-change`); on a fine pointer the hook keeps the browser's own popup from opening and draws a panel under
 * the select instead, from its options and option groups. The select keeps focus and points at the active row
 * with `aria-activedescendant`. ↑ ↓ Home End move, a typed word jumps, Enter or Space chooses, Esc closes with
 * the focus where it was, Tab and a press outside close. Choosing sets the value and fires `input` and
 * `change`. On a touch screen nothing changes: the system picker opens.
 *
 * The panel lives in `document.body` while it is open, drawn with `position: fixed` from the rectangle of the
 * select, so no ancestor with `overflow` clips it; it opens above when there is no room below.
 */
export default {
  mounted() {
    this.group = this.el.closest(".select")
    this.panel = null
    this.items = []
    this.active = -1
    this.typed = {text: "", at: 0}
    this.pointer = window.matchMedia("(pointer: fine)")

    this.el.addEventListener("mousedown", (event) => this.onMouseDown(event))
    this.el.addEventListener("keydown", (event) => this.onKey(event))
    this.el.addEventListener("blur", () => this.close())
    this.outside = (event) => !this.group.contains(event.target) && !this.panel?.contains(event.target) && this.close()
    this.reflow = (event) => event?.target !== this.panel && this.place()
    document.addEventListener("pointerdown", this.outside)
    this.announce()
  },

  updated() {
    this.announce()
    this.isOpen() && this.refresh()
  },

  destroyed() {
    document.removeEventListener("pointerdown", this.outside)
    this.close()
  },

  isOpen() {
    return this.panel !== null
  },

  enabled() {
    return this.pointer.matches && !this.el.disabled && !this.el.multiple
  },

  announce() {
    this.el.setAttribute("aria-haspopup", "listbox")
    this.el.setAttribute("aria-expanded", String(this.isOpen()))
    this.group.toggleAttribute("data-open", this.isOpen())
  },

  onMouseDown(event) {
    const own = this.enabled() && event.button === 0
    own && event.preventDefault()
    own && this.el.focus()
    own && (this.isOpen() ? this.close() : this.open())
  },

  onKey(event) {
    const now = Date.now()
    const typing = this.enabled() && this.isOpen() && isTypeKey(event, this.typed, now)
    typing ? this.type(event.key, now, event) : this.enabled() && runKey(this.isOpen() ? this.openKeys(event) : this.closedKeys(), event)
  },

  closedKeys() {
    const open = () => this.open()
    return {ArrowDown: open, ArrowUp: open, "Alt+ArrowDown": open, "Alt+ArrowUp": open, Enter: open, " ": open}
  },

  openKeys(event) {
    const move = () => this.activate(moveActive(this.items, this.active, event.key))
    return {
      ArrowDown: move,
      ArrowUp: move,
      Home: move,
      End: move,
      Enter: () => this.choose(this.active),
      " ": () => this.choose(this.active),
      Escape: () => (event.stopPropagation(), this.close()),
      Tab: () => (this.close(), false),
    }
  },

  type(key, now, event) {
    event.preventDefault()
    this.typed = typedText(this.typed, key, now)
    this.activate(typeAhead(this.items, this.active, this.typed.text))
  },

  open() {
    this.items = readItems(this.el)
    this.active = startIndex(this.items)
    this.typed = {text: "", at: 0}
    this.build()
    document.body.appendChild(this.panel)
    this.announce()
    this.place()
    this.activate(this.active)
    window.addEventListener("resize", this.reflow)
    window.addEventListener("scroll", this.reflow, true)
  },

  close() {
    if (!this.isOpen()) return
    window.removeEventListener("resize", this.reflow)
    window.removeEventListener("scroll", this.reflow, true)
    this.panel.remove()
    this.panel = null
    this.el.removeAttribute("aria-activedescendant")
    this.el.removeAttribute("aria-controls")
    this.announce()
  },

  refresh() {
    const previous = this.items[this.active]?.position
    this.items = readItems(this.el)
    this.active = this.items.findIndex((item) => item.kind === "option" && item.position === previous)
    this.panel.replaceChildren(...this.rows())
    this.place()
    this.activate(this.active === -1 ? startIndex(this.items) : this.active)
  },

  build() {
    this.panel = element("div", "select-panel")
    this.panel.id = `${this.el.id}-panel`
    this.panel.dataset.size = this.group.dataset.size
    this.panel.setAttribute("role", "listbox")
    this.panel.setAttribute("tabindex", "-1")
    this.panel.addEventListener("mousedown", (event) => event.preventDefault())
    this.panel.addEventListener("click", (event) => this.onClick(event))
    this.panel.addEventListener("mouseover", (event) => this.onHover(event))
    this.panel.replaceChildren(...this.rows())
    this.el.setAttribute("aria-controls", this.panel.id)
    Object.assign(this.panel.style, {position: "fixed", zIndex: PORTAL_Z, colorScheme: getComputedStyle(this.group).colorScheme})
  },

  rows() {
    return this.items.map((item, index) => (item.kind === "group" ? this.groupRow(item) : this.optionRow(item, index)))
  },

  groupRow(item) {
    return element("div", "select-group", item.label)
  },

  optionRow(item, index) {
    const row = element("div", "select-option")
    row.id = `${this.el.id}-option-${index}`
    row.dataset.index = String(index)
    row.setAttribute("role", "option")
    row.setAttribute("aria-selected", String(item.selected))
    item.disabled && row.setAttribute("aria-disabled", "true")
    item.value === "" && row.setAttribute("data-empty", "")
    row.append(element("span", "select-option-label", item.label))
    const check = element("span", "select-check")
    check.innerHTML = CHECK
    item.selected && row.append(check)
    return row
  },

  rowAt(event) {
    return event.target.closest?.("[data-index]") ?? null
  },

  onHover(event) {
    const row = this.rowAt(event)
    row && !row.hasAttribute("aria-disabled") && this.activate(Number(row.dataset.index))
  },

  onClick(event) {
    const row = this.rowAt(event)
    row && this.choose(Number(row.dataset.index))
  },

  activate(index) {
    this.active = index
    this.panel.querySelector("[data-active]")?.removeAttribute("data-active")
    const row = this.panel.querySelector(`[data-index="${index}"]`)
    row?.setAttribute("data-active", "")
    row?.scrollIntoView({block: "nearest"})
    row ? this.el.setAttribute("aria-activedescendant", row.id) : this.el.removeAttribute("aria-activedescendant")
  },

  choose(index) {
    const item = this.items[index]
    const allowed = item?.kind === "option" && !item.disabled
    const changed = allowed && this.el.selectedIndex !== item.position
    allowed && (this.el.selectedIndex = item.position)
    allowed && this.close()
    changed && (notify(this.el, "input"), notify(this.el, "change"))
    return allowed
  },

  place() {
    const style = this.panel.style
    style.maxHeight = ""
    const placed = placePanel({
      anchor: this.group.getBoundingClientRect(),
      height: this.panel.offsetHeight,
      screen: {width: window.innerWidth, height: window.innerHeight},
    })
    this.panel.dataset.side = placed.side
    Object.assign(style, {
      top: `${placed.top}px`,
      left: `${placed.left}px`,
      width: `${placed.width}px`,
      maxHeight: `${placed.maxHeight}px`,
    })
  },
}
