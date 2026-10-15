import {runKey, wrap} from "./keys.js"
import {matches} from "./text.js"

/**
 * The ARIA combobox: a button that shows the choice and a panel with a search field and a list. The field
 * keeps focus and points at the active option with `aria-activedescendant`; ↑ ↓ move (round the visible
 * options), Enter chooses, Esc closes and returns to the button. The value goes in a hidden input, and
 * choosing fires `input` on it so `phx-change` hears it.
 */
export default {
  mounted() {
    this.hidden = this.el.querySelector('input[type="hidden"]')
    this.trigger = this.el.querySelector("[data-trigger]")
    this.panel = this.el.querySelector("[data-panel]")
    this.search = this.el.querySelector("[data-search]")
    this.options = [...this.el.querySelectorAll('[role="option"]')]
    this.empty = this.el.querySelector("[data-empty]")

    this.trigger.addEventListener("click", () => (this.panel.hidden ? this.open() : this.close()))
    this.search.addEventListener("input", () => this.filter())
    this.search.addEventListener("keydown", (event) => this.onKey(event))
    this.panel.addEventListener("click", (event) => {
      const option = event.target.closest('[role="option"]')
      option && this.choose(option)
    })

    this.outside = (event) => !this.el.contains(event.target) && this.close()
    document.addEventListener("mousedown", this.outside)
  },

  destroyed() {
    document.removeEventListener("mousedown", this.outside)
  },

  visible() {
    return this.options.filter((option) => !option.hidden)
  },

  activeIndex() {
    return this.visible().findIndex((option) => option.hasAttribute("data-active"))
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
    this.activate(this.options.find((option) => option.getAttribute("aria-selected") === "true") ?? this.visible()[0])
    this.search.focus()
  },

  close() {
    if (this.panel.hidden) return
    this.panel.hidden = true
    this.trigger.setAttribute("aria-expanded", "false")
    this.search.removeAttribute("aria-activedescendant")
  },

  filter() {
    this.options.forEach((option) => (option.hidden = !matches(option.dataset.label, this.search.value)))
    this.empty.hidden = this.visible().length > 0
    this.activate(this.visible()[0])
  },

  activate(option) {
    this.options.forEach((other) => other.removeAttribute("data-active"))
    option?.setAttribute("data-active", "")
    option?.scrollIntoView({block: "nearest"})
    option ? this.search.setAttribute("aria-activedescendant", option.id) : this.search.removeAttribute("aria-activedescendant")
  },

  choose(option) {
    this.options.forEach((other) => other.setAttribute("aria-selected", String(other === option)))
    this.hidden.value = option.dataset.value
    const current = this.el.querySelector("[data-current]")
    current.textContent = option.dataset.label
    current.classList.remove("text-muted")
    this.hidden.dispatchEvent(new Event("input", {bubbles: true}))
    this.close()
    this.trigger.focus()
  },
}
