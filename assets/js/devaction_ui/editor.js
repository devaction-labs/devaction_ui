import {Editor} from "@tiptap/core"
import StarterKit from "@tiptap/starter-kit"
import {TaskList, TaskItem} from "@tiptap/extension-list"
import Placeholder from "@tiptap/extension-placeholder"
import CharacterCount from "@tiptap/extension-character-count"
import TextAlign from "@tiptap/extension-text-align"
import Mention from "@tiptap/extension-mention"
import Suggestion from "@tiptap/suggestion"
import {Extension} from "@tiptap/core"
import Image from "@tiptap/extension-image"
import {Markdown} from "@tiptap/markdown"
import {
  commands,
  styles,
  currentStyle,
  safeHref,
  wordCount,
  blocks,
  filterItems,
  sends,
  imageProblem,
  uploadError,
  toolbarTarget,
} from "./editor_logic.js"
import {popup} from "./suggest.js"

const list = (el, name) => JSON.parse(el.dataset[name] ?? "[]")

const slashMenu = (items) =>
  Extension.create({
    name: "slashMenu",
    addProseMirrorPlugins() {
      return [
        Suggestion({
          editor: this.editor,
          char: "/",
          startOfLine: true,
          items: ({query}) => filterItems(items, query),
          command: ({editor, range, props}) => blocks[props.key]?.(editor.chain().focus().deleteRange(range)).run(),
          render: () => popup(`${this.editor.options.element.id}-slash`, (item) => item.label),
        }),
      ]
    },
  })

/**
 * The rich text editor: `phx-hook="DevactionUI.Editor"` on the root, with `[data-editor-content]` for the
 * text, `[data-command]` buttons, an optional `[data-style]` select, a link bar (`[data-link-bar]`) and a
 * `[data-count]` for the words. The text goes out as HTML and as Markdown in the two hidden inputs
 * (`[data-html]`, `[data-markdown]`), which fire `input` so a form with `phx-change` hears it.
 */
export default {
  mounted() {
    this.editor = new Editor({
      element: this.el.querySelector("[data-editor-content]"),
      content: this.el.querySelector("[data-html]").value,
      contentType: "html",
      extensions: [
        StarterKit.configure({link: {openOnClick: false, autolink: true}}),
        TaskList,
        TaskItem.configure({nested: true}),
        TextAlign.configure({types: ["heading", "paragraph"]}),
        Placeholder.configure({placeholder: this.el.dataset.placeholder ?? ""}),
        CharacterCount,
        Image.configure({inline: false}),
        Markdown,
        ...this.suggestions(),
      ],
      editorProps: {
        attributes: {class: "editor-content", role: "textbox", "aria-multiline": "true", "aria-label": this.el.dataset.label ?? ""},
        handleKeyDown: (_view, event) => this.el.dataset.send === "true" && sends(event) && (this.send(), true),
      },
      onUpdate: () => this.save(),
      onTransaction: () => this.refresh(),
    })

    this.on("click", "[data-command]", (button) => this.run(button.dataset.command))
    this.on("change", "[data-style]", (select) => styles[select.value]?.(this.editor.chain().focus()).run())
    this.on("click", "[data-link]", () => this.openLink())
    this.handleEvent("editor:replace", (payload) => this.replace(payload))
    this.handleEvent("editor:failed", (payload) => payload.id === this.el.id && this.settle("failed"))
    this.on("click", "[data-ai]", (button) => this.improve(button))
    this.on("click", "[data-image]", () => this.el.querySelector("[data-image-input]")?.click())
    this.on("change", "[data-image-input]", (input) => this.upload(input))
    this.on("keydown", "[data-link-input]", (input, event) => this.linkKey(input, event))
    this.setupToolbar()
    this.refresh()
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

  suggestions() {
    const slash = list(this.el, "slash")
    const mentions = list(this.el, "mentions")
    const id = this.el.id
    const mention = Mention.extend({
      renderMarkdown: (node) => `@[${node.attrs.label}](mention:${node.attrs.id})`,
    }).configure({
      HTMLAttributes: {class: "rounded bg-info-bg px-1 text-info-fg"},
      suggestion: {
        char: "@",
        items: ({query}) => filterItems(mentions, query).slice(0, 8),
        render: () => popup(`${id}-mention`, (item) => item.label),
      },
    })
    return [...(slash.length ? [slashMenu(slash)] : []), ...(mentions.length ? [mention] : [])]
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
    input.dispatchEvent(new Event("input", {bubbles: true}))
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
    this.pushEventTo(`#${this.el.id}`, "improve", {markdown})
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
    const token = document.querySelector("meta[name='csrf-token']")?.getAttribute("content")

    const target = new URL(this.el.dataset.uploadUrl, location.href)
    if (target.origin !== location.origin) return this.status("failed")

    try {
      const response = await fetch(target, {method: "POST", body: file, headers: {"x-csrf-token": token ?? "", "content-type": file.type}})
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
