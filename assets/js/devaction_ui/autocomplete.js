import {isExpanded, selectedStates} from "./menu_logic.js"
import {keyName, nextTab, runKey, wrap} from "./keys.js"

/**
 * The keys of an autocomplete: ↑ ↓ move the active row (round the list), Enter opens it (rows are links),
 * ⌘/Ctrl + Enter runs the "ask the AI" row, Esc closes the list. The list opens again when the field gets
 * the focus or text, and closes when the focus leaves the whole component. On a `role="tab"` of a scope row
 * (the command palette) ← → Home End move to a tab and press it, so the server chooses the scope. The server searches and draws the
 * rows; after each redraw the first row is active. The active row has `data-active` and `aria-selected`, and
 * the field's `aria-expanded` follows the list: it is false when the list has no row to move to.
 */
export default {
  mounted() {
    this.el.addEventListener("keydown", (event) => this.onKey(event))
    this.el.addEventListener("input", () => this.show(true))
    this.el.addEventListener("focusin", () => this.show(true))
    this.el.addEventListener("focusout", (event) => this.onFocusOut(event))
  },

  updated() {
    this.activate(0)
    this.announce(!this.list()?.hidden)
  },

  destroyed() {
    clearTimeout(this.closing)
  },

  list() {
    return this.el.querySelector('[role="listbox"]')
  },

  options() {
    return [...this.el.querySelectorAll("[data-option]")]
  },

  activeIndex() {
    return this.options().findIndex((option) => option.hasAttribute("data-active"))
  },

  show(visible) {
    const list = this.list()
    list && (list.hidden = !visible)
    this.announce(visible)
  },

  announce(visible) {
    const expanded = isExpanded({hasList: Boolean(this.list()), visible, options: this.options().length})
    this.el.querySelector('[role="combobox"]')?.setAttribute("aria-expanded", String(expanded))
  },

  onFocusOut(event) {
    if (event.relatedTarget && this.el.contains(event.relatedTarget)) return
    // A click on a row blurs the field first: let the click land before the list goes.
    clearTimeout(this.closing)
    this.closing = setTimeout(() => !this.el.contains(document.activeElement) && this.show(false), 120)
  },

  onTabKey(event) {
    const tabs = [...event.target.closest('[role="tablist"]').querySelectorAll('[role="tab"]')]
    const target = tabs[nextTab(keyName(event), tabs.indexOf(event.target), tabs.length)]
    target && (event.preventDefault(), target.focus(), target.click())
  },

  onKey(event) {
    const onTab = Boolean(event.target.closest?.('[role="tablist"]'))
    onTab ? this.onTabKey(event) : this.onListKey(event)
  },

  onListKey(event) {
    const options = this.options()
    const move = (delta) => () => options.length > 0 && this.activate(wrap(this.activeIndex(), delta, options.length))

    runKey(
      {
        ArrowDown: move(1),
        ArrowUp: move(-1),
        Enter: () => options[this.activeIndex()]?.click() ?? false,
        "Mod+Enter": () => this.el.querySelector("[data-ask]")?.click() ?? false,
        Escape: () => this.list() && this.show(false),
      },
      event,
    )
  },

  activate(index) {
    const options = this.options()
    options.forEach((option) => option.removeAttribute("data-active"))
    selectedStates(options.length, index).forEach((state, at) => options[at].setAttribute("aria-selected", state))
    const active = options[index]
    active?.setAttribute("data-active", "")
    active?.scrollIntoView({block: "nearest"})
    active && this.el.querySelector('input[role="combobox"]').setAttribute("aria-activedescendant", active.id)
  },
}
