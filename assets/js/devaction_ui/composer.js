import {activatesButton, applyPick, canSend, carriesFiles, countView, fieldHeight, intentOf, isOver, joinFiles, moveActive, triggerOf} from "./composer_logic.js"
import {notify} from "./dom.js"

/**
 * The message field of `Composer`. The textarea grows with its text up to `data-max-rows` lines and then scrolls
 * inside; Enter sends the form, Shift+Enter breaks the line, and Enter while a word is being composed (IME) does
 * neither. The send button is off while there is nothing to send or the text is over `data-max-length`
 * (`data-over` on the root, and a counter from 80% of the limit). While the root has `data-busy="true"` the same
 * button is the stop button: it, or Esc, sends the `data-stop` command (a `JS.push` the server drew, with its
 * `phx-target`) and fires `composer:stop` on the root. ↑ in an empty field runs `data-edit-last` the same way and
 * fires `composer:edit-last`; the server answers with `composer:fill` (`%{id, text}`) to put the message in the field.
 *
 * With `data-suggest` (the event the server named) the word at the caret is watched: a `/` at the start of the text
 * or an `@` at the start of a word sends `%{id, trigger, query}` to the `phx-target` of the form (and `trigger: null`
 * when the word is gone), and the server draws the list in the `suggestions` slot (`[data-composer-suggest]`). While
 * the list has rows the hook owns its keys: ↑ ↓ move the highlight (`aria-selected`), Enter or Tab choose the row
 * (a click on it, which puts its `data-insert` in place of the typed word) and Esc closes the list.
 *
 * Over the limit the field says `aria-invalid`. A file button drawn as a `label` with `role="button"` opens the chooser
 * with Enter or Space too.
 *
 * Files pasted into the field or dropped on the composer go to its `input[type=file]` (the `live_file_input`, so
 * LiveView uploads them) and also leave in `composer:files`. After a send the server pushes `composer:clear`
 * with the id of the composer: LiveView never overwrites a focused field, so the hook empties it.
 */
export default {
  mounted() {
    this.measures = this.measure()

    this.el.addEventListener("input", (event) => event.target === this.input() && (this.sync(), this.watch()))
    this.el.addEventListener("keydown", (event) => event.target === this.input() && this.onKey(event))
    this.el.addEventListener("keydown", (event) => this.onLabelKey(event))
    this.el.addEventListener("paste", (event) => event.target === this.input() && this.take(event, event.clipboardData?.files))
    this.el.addEventListener("keyup", (event) => event.target === this.input() && this.onCaret(event))
    this.el.addEventListener("click", (event) => this.onClick(event))
    this.el.addEventListener("mousedown", (event) => event.target.closest("[data-composer-suggest]") && event.preventDefault())
    this.el.addEventListener("dragover", (event) => this.onDragOver(event))
    this.el.addEventListener("dragleave", (event) => this.el.contains(event.relatedTarget) || this.el.removeAttribute("data-dragging"))
    this.el.addEventListener("drop", (event) => (this.el.removeAttribute("data-dragging"), this.take(event, event.dataTransfer?.files)))
    this.form().addEventListener("submit", () => requestAnimationFrame(() => this.sync()))
    this.handleEvent("composer:clear", ({id}) => id === this.el.id && this.clear())
    this.handleEvent("composer:fill", ({id, text}) => id === this.el.id && this.fill(text))

    this.sync()
  },

  updated() {
    this.sync()
    this.mark()
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
    return {
      text: this.input().value,
      maxLength: Number(this.el.dataset.maxLength || 0),
      busy: this.isBusy(),
      suggesting: this.options().length > 0,
    }
  },

  options() {
    return [...this.el.querySelectorAll("[data-composer-suggest] [role=option]")]
  },

  mark() {
    const options = this.options()
    this.active = Math.min(this.active ?? 0, Math.max(options.length - 1, 0))
    options.forEach((option, at) => option.setAttribute("aria-selected", String(at === this.active)))
    options[this.active]?.scrollIntoView({block: "nearest"})
  },

  move(key) {
    this.active = moveActive(this.active ?? 0, key, this.options().length)
    this.mark()
  },

  pick() {
    this.options()[this.active ?? 0]?.click()
  },

  watch() {
    const input = this.input()
    const event = this.el.dataset.suggest
    const token = event ? triggerOf(input.value, input.selectionStart) : null
    const key = token ? `${token.trigger}${token.query}` : ""
    key === this.dismissed || this.announce(token, key)
  },

  announce(token, key) {
    this.dismissed = null
    this.token = token
    key === (this.announced ?? "") || this.tell(token, key)
  },

  tell(token, key) {
    this.announced = key
    this.active = 0
    this.report({trigger: token?.trigger ?? null, query: token?.query ?? ""})
  },

  report(payload) {
    const target = this.form().getAttribute("phx-target")
    const event = this.el.dataset.suggest
    const body = {id: this.el.id, ...payload}
    target ? this.pushEventTo(target, event, body) : this.pushEvent(event, body)
  },

  close() {
    this.dismissed = this.announced
    this.announced = ""
    this.token = null
    this.report({trigger: null, query: ""})
  },

  insert(option) {
    const input = this.input()
    const insert = option.dataset.insert
    const picked = this.token && insert !== undefined && applyPick(input.value, this.token, insert)
    picked && ((input.value = picked.text), input.setSelectionRange(picked.caret, picked.caret), input.focus(), notify(input))
  },

  onCaret(event) {
    ;["ArrowLeft", "ArrowRight", "Home", "End"].includes(event.key) && this.watch()
  },

  sync() {
    const state = this.state()
    const input = this.input()
    input.style.height = "auto"
    const {height, scrolls} = fieldHeight({...this.measures, scrollHeight: input.scrollHeight})
    input.style.height = `${height}px`
    input.style.overflowY = scrolls ? "auto" : "hidden"
    const over = isOver(state.text, state.maxLength)
    this.el.toggleAttribute("data-over", over)
    input.setAttribute("aria-invalid", String(over))
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
      "edit-last": () => this.editLast(),
      next: () => (event.preventDefault(), this.move("ArrowDown")),
      previous: () => (event.preventDefault(), this.move("ArrowUp")),
      pick: () => (event.preventDefault(), this.pick()),
      close: () => (event.preventDefault(), this.close()),
      none: () => {},
    }
    actions[intentOf(event, this.state())]()
  },

  run(command) {
    command && this.liveSocket.execJS(this.el, command)
  },

  stop() {
    this.run(this.el.dataset.stop)
    this.el.dispatchEvent(new CustomEvent("composer:stop", {bubbles: true}))
  },

  editLast() {
    this.run(this.el.dataset.editLast)
    this.el.dispatchEvent(new CustomEvent("composer:edit-last", {bubbles: true}))
  },

  onLabelKey(event) {
    const label = event.target.closest("label[role=button]")
    label && activatesButton(event) && (event.preventDefault(), label.click())
  },
  onDragOver(event) {
    carriesFiles(event.dataTransfer?.types) && (event.preventDefault(), this.el.setAttribute("data-dragging", ""))
  },

  onClick(event) {
    const onSend = event.target.closest("[data-composer-send]") !== null
    onSend && this.isBusy() && (event.preventDefault(), this.stop())
    const option = event.target.closest("[data-composer-suggest] [role=option]")
    option && this.insert(option)
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
    this.fill("")
  },

  fill(text) {
    const input = this.input()
    input.value = text
    input.focus()
    input.setSelectionRange(text.length, text.length)
    this.sync()
    this.watch()
  },
}
