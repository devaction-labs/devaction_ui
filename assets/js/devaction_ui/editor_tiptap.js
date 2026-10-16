import {blocks, filterItems, sends} from "./editor_logic.js"
import {popup} from "./suggest.js"

const absent = () => null

/**
 * The packages of TipTap, by `import()` with a `.catch`, so a bundler (esbuild) that cannot find them downgrades
 * the error to a warning and an app that never renders an editor builds without installing them. A missing one
 * fails here, with its own message, when an editor is mounted.
 */
async function load() {
  const [core, starter, extensionList, placeholder, characterCount, textAlign, mention, suggestion, image, markdown] =
    await Promise.all([
      import("@tiptap/core").catch(absent),
      import("@tiptap/starter-kit").catch(absent),
      import("@tiptap/extension-list").catch(absent),
      import("@tiptap/extension-placeholder").catch(absent),
      import("@tiptap/extension-character-count").catch(absent),
      import("@tiptap/extension-text-align").catch(absent),
      import("@tiptap/extension-mention").catch(absent),
      import("@tiptap/suggestion").catch(absent),
      import("@tiptap/extension-image").catch(absent),
      import("@tiptap/markdown").catch(absent),
    ])
  const loaded = {core, starter, extensionList, placeholder, characterCount, textAlign, mention, suggestion, image, markdown}
  const missing = Object.entries(loaded).filter(([, module]) => module === null).map(([name]) => name)
  if (missing.length > 0) throw new Error(`DevactionUI.Editor needs the @tiptap/* packages of assets/package.json (missing: ${missing.join(", ")})`)
  return {
    Editor: core.Editor,
    Extension: core.Extension,
    StarterKit: starter.default,
    TaskList: extensionList.TaskList,
    TaskItem: extensionList.TaskItem,
    Placeholder: placeholder.default,
    CharacterCount: characterCount.default,
    TextAlign: textAlign.default,
    Mention: mention.default,
    Suggestion: suggestion.default,
    Image: image.default,
    Markdown: markdown.Markdown,
  }
}

const list = (el, name) => JSON.parse(el.dataset[name] ?? "[]")

const slashMenu = ({Extension, Suggestion}, items) =>
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

const suggestions = (tiptap, el) => {
  const slash = list(el, "slash")
  const mentions = list(el, "mentions")
  const id = el.id
  const mention = tiptap.Mention.extend({
    renderMarkdown: (node) => `@[${node.attrs.label}](mention:${node.attrs.id})`,
  }).configure({
    HTMLAttributes: {class: "rounded bg-info-bg px-1 text-info-fg"},
    suggestion: {
      char: "@",
      items: ({query}) => filterItems(mentions, query).slice(0, 8),
      render: () => popup(`${id}-mention`),
    },
  })
  return [...(slash.length ? [slashMenu(tiptap, slash)] : []), ...(mentions.length ? [mention] : [])]
}

/**
 * The TipTap editor of the hook. It lives apart from `editor.js` so the packages of TipTap are loaded (by a
 * dynamic `import()`) only on a page that has an editor.
 */
export async function createEditor({el, onUpdate, onTransaction, onSend}) {
  const tiptap = await load()
  const {Editor, StarterKit, TaskList, TaskItem, TextAlign, Placeholder, CharacterCount, Image, Markdown} = tiptap
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
      ...suggestions(tiptap, el),
    ],
    editorProps: {
      attributes: {class: "editor-content", role: "textbox", "aria-multiline": "true"},
      handleKeyDown: (_view, event) => el.dataset.send === "true" && sends(event) && (onSend(), true),
    },
    onUpdate,
    onTransaction,
  })
}
