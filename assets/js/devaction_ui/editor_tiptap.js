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
import {blocks, filterItems, sends} from "./editor_logic.js"
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
          render: () => popup(`${this.editor.options.element.id}-slash`),
        }),
      ]
    },
  })

const suggestions = (el) => {
  const slash = list(el, "slash")
  const mentions = list(el, "mentions")
  const id = el.id
  const mention = Mention.extend({
    renderMarkdown: (node) => `@[${node.attrs.label}](mention:${node.attrs.id})`,
  }).configure({
    HTMLAttributes: {class: "rounded bg-info-bg px-1 text-info-fg"},
    suggestion: {
      char: "@",
      items: ({query}) => filterItems(mentions, query).slice(0, 8),
      render: () => popup(`${id}-mention`),
    },
  })
  return [...(slash.length ? [slashMenu(slash)] : []), ...(mentions.length ? [mention] : [])]
}

/**
 * The TipTap editor of the hook. It lives apart from `editor.js` so the packages of TipTap are loaded (by a
 * dynamic `import()`) only on a page that has an editor.
 */
export function createEditor({el, onUpdate, onTransaction, onSend}) {
  return new Editor({
    element: el.querySelector("[data-editor-content]"),
    content: el.querySelector("[data-html]").value,
    contentType: "html",
    extensions: [
      StarterKit.configure({link: {openOnClick: false, autolink: true}}),
      TaskList,
      TaskItem.configure({nested: true}),
      TextAlign.configure({types: ["heading", "paragraph"]}),
      Placeholder.configure({placeholder: el.dataset.placeholder ?? ""}),
      CharacterCount,
      Image.configure({inline: false}),
      Markdown,
      ...suggestions(el),
    ],
    editorProps: {
      attributes: {class: "editor-content", role: "textbox", "aria-multiline": "true"},
      handleKeyDown: (_view, event) => el.dataset.send === "true" && sends(event) && (onSend(), true),
    },
    onUpdate,
    onTransaction,
  })
}
