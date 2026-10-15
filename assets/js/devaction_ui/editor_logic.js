/**
 * What each button of the editor toolbar does and when it shows as pressed. A command is `run(chain)`, which
 * takes a TipTap command chain and returns it, and `active(editor)`; both are looked up by the name the
 * button carries in `data-command`. Nothing here touches the DOM, so it is tested with a fake chain.
 */
export const commands = {
  bold: {run: (c) => c.toggleBold(), active: (e) => e.isActive("bold")},
  italic: {run: (c) => c.toggleItalic(), active: (e) => e.isActive("italic")},
  strike: {run: (c) => c.toggleStrike(), active: (e) => e.isActive("strike")},
  code: {run: (c) => c.toggleCode(), active: (e) => e.isActive("code")},
  bulletList: {run: (c) => c.toggleBulletList(), active: (e) => e.isActive("bulletList")},
  orderedList: {run: (c) => c.toggleOrderedList(), active: (e) => e.isActive("orderedList")},
  taskList: {run: (c) => c.toggleTaskList(), active: (e) => e.isActive("taskList")},
  blockquote: {run: (c) => c.toggleBlockquote(), active: (e) => e.isActive("blockquote")},
  indent: {run: (c) => c.sinkListItem("listItem"), active: () => false},
  outdent: {run: (c) => c.liftListItem("listItem"), active: () => false},
  alignLeft: {run: (c) => c.setTextAlign("left"), active: (e) => e.isActive({textAlign: "left"})},
  alignCenter: {run: (c) => c.setTextAlign("center"), active: (e) => e.isActive({textAlign: "center"})},
  alignRight: {run: (c) => c.setTextAlign("right"), active: (e) => e.isActive({textAlign: "right"})},
  undo: {run: (c) => c.undo(), active: () => false},
  redo: {run: (c) => c.redo(), active: () => false},
}

/** The style of the text as the select of the toolbar names it: `paragraph`, `h2` or `h3`. */
export const styles = {
  paragraph: (c) => c.setParagraph(),
  h2: (c) => c.toggleHeading({level: 2}),
  h3: (c) => c.toggleHeading({level: 3}),
}

/** The style the cursor is in, as a key of `styles`. */
export function currentStyle(editor) {
  const levels = [[2, "h2"], [3, "h3"]]
  return levels.find(([level]) => editor.isActive("heading", {level}))?.[1] ?? "paragraph"
}

/** The name of every command, for the toolbar to be checked against. */
export const names = Object.keys(commands)

/** A link address the editor accepts: http, https or mailto; anything else (`javascript:`) is dropped. */
export function safeHref(text) {
  const value = (text ?? "").trim()
  const allowed = /^(https?:\/\/|mailto:)/i
  const withScheme = /^[a-z][a-z0-9+.-]*:/i.test(value) ? value : `https://${value}`
  return value && allowed.test(withScheme) ? withScheme : null
}

export const imageTypes = ["image/png", "image/jpeg", "image/gif", "image/webp"]

/** Why an image cannot be sent, as a key of the errors the page gives (`unsupported`, `too_large`), or `null` when it can. */
export function imageProblem(file, maxBytes) {
  const checks = [
    [!imageTypes.includes(file.type), "unsupported"],
    [file.size > maxBytes, "too_large"],
  ]
  return checks.find(([wrong]) => wrong)?.[1] ?? null
}

/** The key the server answered an upload with, or `failed` for anything else. */
export function uploadError(body) {
  const known = ["unsupported", "too_large", "empty"]
  return known.includes(body?.error) ? body.error : "failed"
}

/** Words of a text, as the counter shows them. */
export function wordCount(text) {
  return (text ?? "").trim().split(/\s+/).filter(Boolean).length
}

/** What each entry of the "/" menu turns the current line into, by the key the server gives it. */
export const blocks = {
  paragraph: (c) => c.setParagraph(),
  h2: (c) => c.toggleHeading({level: 2}),
  h3: (c) => c.toggleHeading({level: 3}),
  bulletList: (c) => c.toggleBulletList(),
  orderedList: (c) => c.toggleOrderedList(),
  taskList: (c) => c.toggleTaskList(),
  blockquote: (c) => c.toggleBlockquote(),
  codeBlock: (c) => c.toggleCodeBlock(),
  divider: (c) => c.setHorizontalRule(),
}

/** The entries of a menu whose label holds what was typed, in the order given; an empty query keeps all. */
export function filterItems(items, query) {
  const needle = (query ?? "").trim().toLowerCase()
  return items.filter((item) => item.label.toLowerCase().includes(needle))
}

/** Where the highlight goes in a menu of `length` entries when a key is pressed; `null` when the key is not the menu's. */
export function nextIndex(index, key, length) {
  if (length === 0) return null
  const moves = {
    ArrowDown: (index + 1) % length,
    ArrowUp: (index - 1 + length) % length,
    Home: 0,
    End: length - 1,
  }
  return moves[key] ?? null
}

/** Whether a key press sends a comment: Enter with the command key (or control). */
export function sends(event) {
  return event.key === "Enter" && Boolean(event.metaKey || event.ctrlKey)
}
