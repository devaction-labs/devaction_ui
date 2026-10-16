import {notify} from "./dom.js"
import {
  commands,
  styles,
  currentStyle,
  safeHref,
  wordCount,
  imageProblem,
  uploadError,
  toolbarTarget,
  textboxAttributes,
  hostNames,
  uploadHeaders,
} from "./editor_logic.js"

/**
 * The rich text editor: `phx-hook="DevactionUI.Editor"` on the root, with `[data-editor-content]` for the
 * text, `[data-command]` buttons, an optional `[data-style]` select, a link bar (`[data-link-bar]`) and a
 * `[data-count]` for the words. The text goes out as HTML and as Markdown in the two hidden inputs
 * (`[data-html]`, `[data-markdown]`), which fire `input` so a form with `phx-change` hears it.
 *
 * TipTap is loaded by `import("./editor_tiptap.js")` when the hook mounts, so a host that never renders an
 * editor does not need the TipTap packages installed. `data-invalid`, `data-disabled`, `data-labelledby` and
 * `data-described-by` are read on mount and on every update. `data-csrf-meta`, `data-csrf-header`,
 * `data-improve-event`, `data-replace-event` and `data-failed-event` name what the hook shares with its host
 * (the defaults are Phoenix's).
 */
export default {
  async mounted() {
    const {createEditor} = await import("./editor_tiptap.js")
    if (!this.el.isConnected) return

    const editor = await createEditor({
      el: this.el,
      onUpdate: () => this.save(),
      onTransaction: () => this.refresh(),
      onSend: () => this.send(),
    })
    if (!this.el.isConnected) return editor.destroy()
    this.editor = editor

    this.on("click", "[data-command]", (button) => this.run(button.dataset.command))
    this.on("change", "[data-style]", (select) => styles[select.value]?.(this.editor.chain().focus()).run())
    this.on("click", "[data-link]", () => this.openLink())
    const names = hostNames(this.el.dataset)
    this.handleEvent(names.replace, (payload) => this.replace(payload))
    this.handleEvent(names.failed, (payload) => payload.id === this.el.id && this.settle("failed"))
    this.on("click", "[data-ai]", (button) => this.improve(button))
    this.on("click", "[data-image]", () => this.el.querySelector("[data-image-input]")?.click())
    this.on("change", "[data-image-input]", (input) => this.upload(input))
    this.on("keydown", "[data-link-input]", (input, event) => this.linkKey(input, event))
    this.setupToolbar()
    this.refresh()
    this.sync()
  },

  updated() {
    this.editor && this.sync()
  },

  sync() {
    const data = this.el.dataset
    const disabled = data.disabled === "true"
    this.editor.setEditable(!disabled)
    this.tools().forEach((tool) => (tool.disabled = disabled))
    const attributes = textboxAttributes({
      label: data.label,
      labelledby: data.labelledby,
      invalid: data.invalid === "true",
      describedby: data.describedBy,
      disabled,
    })
    Object.entries(attributes).forEach(([name, value]) =>
      value === null ? this.editor.view.dom.removeAttribute(name) : this.editor.view.dom.setAttribute(name, value),
    )
  },

  tools() {
    return [...this.el.querySelectorAll('[role="toolbar"] button, [role="toolbar"] select')]
  },

  rove(at) {
    this.tools().forEach((tool, index) => (tool.tabIndex = index === at ? 0 : -1))
  },

  setupToolbar() {
    const selector = '[role="toolbar"] button, [role="toolbar"] select'
    this.rove(0)
    this.on("focusin", selector, (tool) => this.rove(this.tools().indexOf(tool)))
    this.on("keydown", selector, (tool, event) => {
      const tools = this.tools()
      const next = toolbarTarget(event.key, tools.indexOf(tool), tools.length)
      next !== null && (tools[next].focus(), event.preventDefault())
    })
  },

  send() {
    this.el.closest("form")?.requestSubmit()
  },

  destroyed() {
    this.editor?.destroy()
  },

  on(type, selector, handler) {
    this.el.addEventListener(type, (event) => {
      const target = event.target.closest(selector)
      target && this.el.contains(target) && handler(target, event)
    })
  },

  run(name) {
    const command = commands[name]
    command && command.run(this.editor.chain().focus()).run()
  },

  save() {
    this.write("[data-html]", this.editor.getHTML())
    this.write("[data-markdown]", this.editor.getMarkdown())
  },

  write(selector, value) {
    const input = this.el.querySelector(selector)
    if (input.value === value) return
    input.value = value
    notify(input)
  },

  refresh() {
    this.el.querySelectorAll("[data-command]").forEach((button) => {
      const command = commands[button.dataset.command]
      button.setAttribute("aria-pressed", String(Boolean(command?.active(this.editor))))
    })
    this.el.querySelector("[data-link]")?.setAttribute("aria-pressed", String(this.editor.isActive("link")))
    const select = this.el.querySelector("[data-style]")
    if (select) select.value = currentStyle(this.editor)
    const count = this.el.querySelector("[data-count]")
    if (count) count.textContent = String(wordCount(this.editor.getText()))
  },

  improve(button) {
    const markdown = this.editor.getMarkdown()
    if (markdown.trim() === "" || button.disabled) return

    button.disabled = true
    this.status(null)
    this.note("working")
    this.pushEventTo(`#${this.el.id}`, hostNames(this.el.dataset).improve, {markdown})
  },

  replace({id, markdown}) {
    if (id !== this.el.id) return
    this.editor.chain().focus().setContent(markdown, {contentType: "markdown"}).run()
    this.settle("done")
  },

  settle(key) {
    this.el.querySelectorAll("[data-ai]").forEach((button) => (button.disabled = false))
    this.note(key)
  },

  note(key) {
    const line = this.el.querySelector("[data-editor-status]")
    const labels = JSON.parse(this.el.dataset.aiLabels ?? "{}")
    line.textContent = labels[key] ?? ""
    line.hidden = !labels[key]
  },

  async upload(input) {
    const file = input.files[0]
    input.value = ""
    if (!file) return

    const problem = imageProblem(file, Number(this.el.dataset.uploadMax))
    if (problem) return this.status(problem)

    this.status(null)
    const names = hostNames(this.el.dataset)
    const token = document.querySelector(`meta[name='${names.csrfMeta}']`)?.getAttribute("content")

    const target = new URL(this.el.dataset.uploadUrl, location.href)
    if (target.origin !== location.origin) return this.status("failed")

    try {
      const response = await fetch(target, {method: "POST", body: file, headers: uploadHeaders({token, csrfHeader: names.csrfHeader, type: file.type})})
      const answer = await response.json().catch(() => null)
      if (!response.ok) return this.status(uploadError(answer))
      this.editor.chain().focus().setImage({src: answer.url, alt: file.name.replace(/\.[^.]+$/, "")}).run()
    } catch (_error) {
      this.status("failed")
    }
  },

  status(key) {
    const line = this.el.querySelector("[data-editor-status]")
    const messages = JSON.parse(this.el.dataset.uploadErrors ?? "{}")
    line.textContent = key ? (messages[key] ?? "") : ""
    line.hidden = !key
  },

  openLink() {
    const bar = this.el.querySelector("[data-link-bar]")
    const input = bar.querySelector("[data-link-input]")
    input.value = this.editor.getAttributes("link").href ?? ""
    bar.hidden = false
    input.focus()
  },

  linkKey(input, event) {
    const actions = {Enter: () => this.applyLink(input.value), Escape: () => this.closeLink()}
    const action = actions[event.key]
    if (!action) return
    event.preventDefault()
    action()
  },

  applyLink(text) {
    const href = safeHref(text)
    const chain = this.editor.chain().focus().extendMarkRange("link")
    href ? chain.setLink({href}).run() : chain.unsetLink().run()
    this.closeLink()
  },

  closeLink() {
    this.el.querySelector("[data-link-bar]").hidden = true
    this.editor.commands.focus()
  },
}
