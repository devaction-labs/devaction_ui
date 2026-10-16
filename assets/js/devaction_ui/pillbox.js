import {runKey} from "./keys.js"
import {clean, fillLabel, isTaken} from "./pillbox_logic.js"

/**
 * A field of removable pills. Enter or a comma adds what was typed, Backspace on an empty field removes the
 * last pill, the × removes the one it sits on, and a repeat is ignored. Text left in the field when it loses
 * focus is added too. Every pill carries a hidden input `name[]`, so the form submits the list as the page
 * shows it; each change fires `input` on the field so a `phx-change` hears it. The element is
 * `phx-update="ignore"`: the browser owns the pills after mount. The `data-remove-label` pattern names each
 * new pill's ×, and `data-added-label` / `data-removed-label` are announced in the live region. The blank
 * `data-sentinel` input of `empty_sentinel` is not a pill and is never counted.
 */
export default {
  mounted() {
    this.input = this.el.querySelector('input[type="text"]')
    this.live = this.el.querySelector("[data-live]")
    this.el.addEventListener("click", (event) => this.onClick(event))
    this.input.addEventListener("keydown", (event) => this.onKey(event))
    this.input.addEventListener("blur", () => this.add(this.input.value))
  },

  pills() {
    return [...this.el.querySelectorAll("[data-pill-item]")]
  },

  values() {
    return [...this.el.querySelectorAll('[data-pill-item] input[type="hidden"]')].map((input) => input.value)
  },

  onClick(event) {
    const remove = event.target.closest("[data-remove]")
    remove && this.remove(remove.closest("[data-pill-item]"))
    this.input.focus()
  },

  onKey(event) {
    const add = () => this.add(this.input.value)
    const removeLast = () => {
      const last = this.pills().at(-1)
      // With text typed, Backspace is for the text.
      if (this.input.value !== "" || !last) return false
      this.remove(last)
    }

    runKey({Enter: add, ",": add, Backspace: removeLast}, event)
  },

  add(raw) {
    const value = clean(raw)
    this.input.value = ""
    if (value === "" || isTaken(this.values(), value)) return

    const pill = this.el.querySelector("template[data-pill]").content.firstElementChild.cloneNode(true)
    pill.querySelector("[data-label]").textContent = value
    pill.querySelector('input[type="hidden"]').value = value
    const remove = pill.querySelector("[data-remove]")
    remove.setAttribute("aria-label", fillLabel(this.el.dataset.removeLabel, value) ?? "")
    this.el.insertBefore(pill, this.input)
    this.announce(this.el.dataset.addedLabel, value)
    this.changed()
  },

  remove(pill) {
    const label = pill.querySelector("[data-label]").textContent
    pill.remove()
    this.announce(this.el.dataset.removedLabel, label)
    this.changed()
  },

  announce(pattern, label) {
    this.live.textContent = fillLabel(pattern, label) ?? ""
  },

  changed() {
    this.input.dispatchEvent(new Event("input", {bubbles: true}))
  },
}
