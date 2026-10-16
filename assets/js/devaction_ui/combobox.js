import {buttonView} from "./combobox_logic.js"
import {runKey, wrap} from "./keys.js"
import {matches} from "./text.js"

/**
 * The ARIA combobox: a button that shows the choice and a panel with a search field and a list. The field
 * keeps focus and points at the active option with `aria-activedescendant`; ↑ ↓ move (round the visible
 * options), Enter chooses, Esc closes and returns to the button, and ↓ ↑ on the button open it. The value
 * goes in a hidden input, and choosing fires `input` on it so `phx-change` hears it. The options are read
 * live, so a patch that changes them is followed: the filter runs again while the panel is open. The clear
 * button, when there is one, empties the choice the same way.
 */
export default {
  mounted() {
    this.hidden = this.el.querySelector('input[type="hidden"]')
    this.trigger = this.el.querySelector("[data-trigger]")
    this.panel = this.el.querySelector("[data-panel]")
    this.search = this.el.querySelector("[data-search]")

    this.trigger.addEventListener("click", () => (this.panel.hidden ? this.open() : this.close()))
    this.trigger.addEventListener("keydown", (event) => this.onTriggerKey(event))
    this.search.addEventListener("input", () => this.filter())
    this.search.addEventListener("keydown", (event) => this.onKey(event))
    this.el.addEventListener("click", (event) => this.onClick(event))

    this.outside = (event) => !this.el.contains(event.target) && this.close()
    document.addEventListener("mousedown", this.outside)
  },

  updated() {
    this.panel.hidden || this.filter()
  },

  destroyed() {
    document.removeEventListener("mousedown", this.outside)
  },

  options() {
    return [...this.el.querySelectorAll('[role="option"]')]
  },

  visible() {
    return this.options().filter((option) => !option.hidden)
  },

  activeIndex() {
    return this.visible().findIndex((option) => option.hasAttribute("data-active"))
  },

  onClick(event) {
    const option = event.target.closest('[role="option"]')
    option && this.choose(option)
    event.target.closest("[data-clear]") && this.clear()
  },

  onTriggerKey(event) {
    runKey({ArrowDown: () => this.open(), ArrowUp: () => this.open()}, event)
  },

  onKey(event) {
    const list = this.visible()
    const move = (delta) => () => this.activate(list[wrap(this.activeIndex(), delta, list.length)])

    runKey(
      {
        ArrowDown: move(1),
        ArrowUp: move(-1),
        Enter: () => list[this.activeIndex()] && this.choose(list[this.activeIndex()]),
        Escape: () => {
          this.close()
          this.trigger.focus()
        },
        // Tab leaves the field: close, and let the browser move on.
        Tab: () => {
          this.close()
          return false
        },
      },
      event,
    )
  },

  open() {
    this.panel.hidden = false
    this.trigger.setAttribute("aria-expanded", "true")
    this.search.value = ""
    this.filter()
    this.activate(this.options().find((option) => option.getAttribute("aria-selected") === "true") ?? this.visible()[0])
    this.search.focus()
  },

  close() {
    if (this.panel.hidden) return
    this.panel.hidden = true
    this.trigger.setAttribute("aria-expanded", "false")
    this.search.removeAttribute("aria-activedescendant")
  },

  filter() {
    this.options().forEach((option) => (option.hidden = !matches(option.dataset.label, this.search.value)))
    this.el.querySelector("[data-empty]").hidden = this.visible().length > 0
    this.activate(this.visible()[0])
  },

  activate(option) {
    this.options().forEach((other) => other.removeAttribute("data-active"))
    option?.setAttribute("data-active", "")
    option?.scrollIntoView({block: "nearest"})
    option ? this.search.setAttribute("aria-activedescendant", option.id) : this.search.removeAttribute("aria-activedescendant")
  },

  show(option, placeholder) {
    const current = this.el.querySelector("[data-current]")
    const view = buttonView(option && {label: option.dataset.label}, placeholder)
    current.textContent = view.text
    current.classList.toggle("text-muted", view.muted)
    const clear = this.el.querySelector("[data-clear]")
    clear && (clear.hidden = view.muted)
  },

  commit(option) {
    this.options().forEach((other) => other.setAttribute("aria-selected", String(other === option)))
    this.hidden.value = option?.dataset.value ?? ""
    this.hidden.dispatchEvent(new Event("input", {bubbles: true}))
  },

  choose(option) {
    this.commit(option)
    this.show(option, "")
    this.close()
    this.trigger.focus()
  },

  clear() {
    this.commit(null)
    this.show(null, this.el.dataset.placeholder)
    this.close()
    this.trigger.focus()
  },
}
