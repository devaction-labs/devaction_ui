import {COPIED_MS, canCopy, next} from "./code_copy_logic.js"

/**
 * Copies the text of the `<code>` of a code block and says so for a moment: `data-copied` on the button
 * (`data-code-copy`) and the button's `data-copied-label` in the status line (`data-code-status`).
 */
export default {
  mounted() {
    this.state = "idle"
    this.button = this.el.querySelector("[data-code-copy]")
    this.status = this.el.querySelector("[data-code-status]")
    this.button.hidden = !canCopy(navigator)
    this.button.addEventListener("click", () => this.copy())
  },

  destroyed() {
    clearTimeout(this.timer)
  },

  async copy() {
    await navigator.clipboard.writeText(this.el.querySelector("code").textContent)
    this.show(next(this.state, "copy"))
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.show(next(this.state, "reset")), COPIED_MS)
  },

  show(state) {
    this.state = state
    this.button.toggleAttribute("data-copied", state === "copied")
    this.status.textContent = state === "copied" ? this.button.dataset.copiedLabel : ""
  },
}
