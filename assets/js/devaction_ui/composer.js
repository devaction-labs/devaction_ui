import {canSend, carriesFiles, countView, fieldHeight, intentOf, isOver, joinFiles} from "./composer_logic.js"
import {notify} from "./dom.js"

/**
 * The message field of `Composer`. The textarea grows with its text up to `data-max-rows` lines and then scrolls
 * inside; Enter sends the form, Shift+Enter breaks the line, and Enter while a word is being composed (IME) does
 * neither. The send button is off while there is nothing to send or the text is over `data-max-length`
 * (`data-over` on the root, and a counter from 80% of the limit). While the root has `data-busy="true"` the same
 * button is the stop button: it, or Esc, sends the `data-stop` command (a `JS.push` the server drew, with its
 * `phx-target`) and fires `composer:stop` on the root. ↑ in an empty field fires `composer:edit-last`.
 *
 * Files pasted into the field or dropped on the composer go to its `input[type=file]` (the `live_file_input`, so
 * LiveView uploads them) and also leave in `composer:files`. After a send the server pushes `composer:clear`
 * with the id of the composer: LiveView never overwrites a focused field, so the hook empties it.
 */
export default {
  mounted() {
    this.measures = this.measure()

    this.el.addEventListener("input", (event) => event.target === this.input() && this.sync())
    this.el.addEventListener("keydown", (event) => event.target === this.input() && this.onKey(event))
    this.el.addEventListener("paste", (event) => event.target === this.input() && this.take(event, event.clipboardData?.files))
    this.el.addEventListener("click", (event) => this.onClick(event))
    this.el.addEventListener("dragover", (event) => this.onDragOver(event))
    this.el.addEventListener("dragleave", (event) => this.el.contains(event.relatedTarget) || this.el.removeAttribute("data-dragging"))
    this.el.addEventListener("drop", (event) => (this.el.removeAttribute("data-dragging"), this.take(event, event.dataTransfer?.files)))
    this.form().addEventListener("submit", () => requestAnimationFrame(() => this.sync()))
    this.handleEvent("composer:clear", ({id}) => id === this.el.id && this.clear())

    this.sync()
  },

  updated() {
    this.sync()
  },

  input() {
    return this.el.querySelector("[data-composer-input]")
  },

  send() {
    return this.el.querySelector("[data-composer-send]")
  },

  form() {
    return this.el.closest("form")
  },

  measure() {
    const style = getComputedStyle(this.input())
    return {
      lineHeight: parseFloat(style.lineHeight) || 22,
      padding: (parseFloat(style.paddingTop) || 0) + (parseFloat(style.paddingBottom) || 0),
      maxRows: Number(this.el.dataset.maxRows || 8),
    }
  },

  isBusy() {
    return this.el.dataset.busy === "true"
  },

  state() {
    return {text: this.input().value, maxLength: Number(this.el.dataset.maxLength || 0), busy: this.isBusy()}
  },

  sync() {
    const state = this.state()
    const input = this.input()
    input.style.height = "auto"
    const {height, scrolls} = fieldHeight({...this.measures, scrollHeight: input.scrollHeight})
    input.style.height = `${height}px`
    input.style.overflowY = scrolls ? "auto" : "hidden"
    this.el.toggleAttribute("data-over", isOver(state.text, state.maxLength))
    this.send().disabled = !state.busy && !canSend(state)
    this.syncCount(state)
  },

  syncCount({text, maxLength}) {
    const {hidden, text: shown} = countView(text.length, maxLength, document.documentElement.lang || undefined)
    const count = this.el.querySelector("[data-composer-count]")
    count.hidden = hidden
    count.textContent = shown
  },

  onKey(event) {
    const actions = {
      send: () => (event.preventDefault(), this.form().requestSubmit(this.send())),
      hold: () => event.preventDefault(),
      stop: () => (event.preventDefault(), this.stop()),
      "edit-last": () => this.el.dispatchEvent(new CustomEvent("composer:edit-last", {bubbles: true})),
      none: () => {},
    }
    actions[intentOf(event, this.state())]()
  },

  stop() {
    const command = this.el.dataset.stop
    command && this.liveSocket.execJS(this.el, command)
    this.el.dispatchEvent(new CustomEvent("composer:stop", {bubbles: true}))
  },

  onDragOver(event) {
    carriesFiles(event.dataTransfer?.types) && (event.preventDefault(), this.el.setAttribute("data-dragging", ""))
  },

  onClick(event) {
    const onSend = event.target.closest("[data-composer-send]") !== null
    onSend && this.isBusy() && (event.preventDefault(), this.stop())
    ;[this.el, this.el.querySelector(".composer-actions")].includes(event.target) && this.input().focus()
  },

  take(event, files) {
    const added = [...(files ?? [])]
    added.length > 0 && (event.preventDefault(), this.addFiles(added))
  },

  addFiles(added) {
    this.fileInput() && this.attach(added)
    this.el.dispatchEvent(new CustomEvent("composer:files", {bubbles: true, detail: {files: added}}))
  },

  fileInput() {
    return this.el.querySelector("[data-composer-files]")
  },

  attach(added) {
    const files = this.fileInput()
    const transfer = new DataTransfer()
    joinFiles(files.files, added).forEach((file) => transfer.items.add(file))
    files.files = transfer.files
    notify(files, "input")
    notify(files, "change")
  },

  clear() {
    this.input().value = ""
    this.sync()
  },
}
