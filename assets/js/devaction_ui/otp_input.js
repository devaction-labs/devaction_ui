import {notify} from "./dom.js"
import {runKey} from "./keys.js"
import {backspaceAt, deleteAt, enterChars, isComplete, joinCode, moveBox} from "./text.js"

/**
 * The boxes of a one-time code. Typing a character fills its box and moves on; pasting the code (or the iPhone
 * and Android filling it from the SMS, which arrives as one value) fills every box; Backspace clears the box
 * and, on an empty one, steps back; the arrows, Home and End move between boxes. The boxes have no name: the
 * code goes, joined, into one hidden input, which fires `input` (and `change` when every box is full) so the
 * `phx-change` of the form hears it. The logic is `text.js`; this only reads and writes the boxes.
 */
export default {
  mounted() {
    this.numeric = this.el.dataset.numeric !== "false"
    this.el.addEventListener("input", (event) => this.onInput(event))
    this.el.addEventListener("keydown", (event) => this.onKey(event))
    this.el.addEventListener("paste", (event) => this.onPaste(event))
    this.el.addEventListener("focusin", (event) => event.target.matches?.("[data-otp-box]") && event.target.select())
    this.sync(false)
  },

  updated() {
    this.sync(false)
  },

  boxes() {
    return [...this.el.querySelectorAll("[data-otp-box]")]
  },

  values() {
    return this.boxes().map((box) => [...box.value][0] ?? "")
  },

  index(event) {
    return this.boxes().indexOf(event.target.closest("[data-otp-box]"))
  },

  onInput(event) {
    const index = this.index(event)
    event.target.matches("[data-otp-box]") && (event.stopPropagation(), this.enter(index, event.target.value))
  },

  onPaste(event) {
    const index = this.index(event)
    index >= 0 && (event.preventDefault(), this.enter(index, event.clipboardData?.getData("text") ?? ""))
  },

  enter(index, raw) {
    const base = this.values().map((value, at) => (at === index ? "" : value))
    this.apply(enterChars(base, index, raw, {numeric: this.numeric}))
  },

  onKey(event) {
    const index = this.index(event)
    const boxes = this.boxes()
    const go = () => this.focusBox(moveBox(event.key, index, boxes.length))
    index >= 0 &&
      runKey(
        {
          Backspace: () => this.apply(backspaceAt(this.values(), index)),
          Delete: () => this.apply(deleteAt(this.values(), index)),
          ArrowLeft: go,
          ArrowRight: go,
          Home: go,
          End: go,
        },
        event,
      )
  },

  apply({boxes, focus}) {
    this.boxes().forEach((box, at) => {
      box.value = boxes[at]
    })
    this.focusBox(focus)
    this.sync(true)
  },

  focusBox(index) {
    const box = this.boxes()[index]
    box.focus()
    box.select()
  },

  sync(announce) {
    const hidden = this.el.querySelector("[data-otp-value]")
    const values = this.values()
    const code = joinCode(values)
    const changed = hidden.value !== code
    hidden.value = code
    announce && changed && notify(hidden)
    announce && changed && isComplete(values) && notify(hidden, "change")
  },
}
