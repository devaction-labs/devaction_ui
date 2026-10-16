import test from "node:test"
import assert from "node:assert/strict"
import {commands, styles, currentStyle, names, rowParts, safeHref, textboxAttributes, wordCount} from "./editor_logic.js"

const chain = () => {
  const calls = []
  const proxy = new Proxy({}, {get: (_t, name) => (...args) => { calls.push([name, ...args]); return proxy }})
  return {proxy, calls}
}

test("every command runs one command of the chain and says whether it is on", () => {
  for (const name of names) {
    const {proxy, calls} = chain()
    commands[name].run(proxy)
    assert.equal(calls.length, 1, name)
    assert.equal(typeof commands[name].active({isActive: () => true}), "boolean", name)
  }
})

test("the marks and blocks ask the editor whether they are active", () => {
  const editor = {isActive: (name) => name === "bold"}
  assert.equal(commands.bold.active(editor), true)
  assert.equal(commands.italic.active(editor), false)
  assert.equal(commands.undo.active(editor), false)
})

test("the style of the cursor is the heading it is in, or paragraph", () => {
  const inside = (level) => ({isActive: (name, attrs) => name === "heading" && attrs.level === level})
  assert.equal(currentStyle(inside(2)), "h2")
  assert.equal(currentStyle(inside(3)), "h3")
  assert.equal(currentStyle(inside(1)), "paragraph")
  const {proxy, calls} = chain()
  styles.h3(proxy)
  assert.deepEqual(calls, [["toggleHeading", {level: 3}]])
})

test("a link keeps http, https and mailto, adds https to a bare address and drops the rest", () => {
  assert.equal(safeHref("https://a.example/x"), "https://a.example/x")
  assert.equal(safeHref("  a.example  "), "https://a.example")
  assert.equal(safeHref("mailto:a@b.example"), "mailto:a@b.example")
  assert.equal(safeHref("javascript:alert(1)"), null)
  assert.equal(safeHref("data:text/html,x"), null)
  assert.equal(safeHref(""), null)
  assert.equal(safeHref(null), null)
})

test("the words are counted by their spaces", () => {
  assert.equal(wordCount("one  two\nthree"), 3)
  assert.equal(wordCount("   "), 0)
  assert.equal(wordCount(null), 0)
})

import {blocks, filterItems, nextIndex, sends, imageProblem, uploadError} from "./editor_logic.js"

test("every block of the slash menu runs one command", () => {
  for (const [name, run] of Object.entries(blocks)) {
    const {proxy, calls} = chain()
    run(proxy)
    assert.equal(calls.length, 1, name)
  }
})

test("a menu is filtered by what was typed, ignoring case, and keeps its order", () => {
  const items = [{label: "Heading 2"}, {label: "Bulleted list"}, {label: "Heading 3"}]
  assert.deepEqual(filterItems(items, "head").map((i) => i.label), ["Heading 2", "Heading 3"])
  assert.equal(filterItems(items, "").length, 3)
  assert.equal(filterItems(items, null).length, 3)
  assert.equal(filterItems(items, "zzz").length, 0)
})

test("the highlight goes around the menu and the other keys are not its", () => {
  assert.equal(nextIndex(0, "ArrowDown", 3), 1)
  assert.equal(nextIndex(2, "ArrowDown", 3), 0)
  assert.equal(nextIndex(0, "ArrowUp", 3), 2)
  assert.equal(nextIndex(1, "Home", 3), 0)
  assert.equal(nextIndex(1, "End", 3), 2)
  assert.equal(nextIndex(1, "a", 3), null)
  assert.equal(nextIndex(0, "ArrowDown", 0), null)
})

test("an image is refused by its type before its size, and a good one passes", () => {
  const max = 1000
  assert.equal(imageProblem({type: "image/png", size: 10}, max), null)
  assert.equal(imageProblem({type: "image/webp", size: 1000}, max), null)
  assert.equal(imageProblem({type: "image/svg+xml", size: 10}, max), "unsupported")
  assert.equal(imageProblem({type: "application/pdf", size: 2000}, max), "unsupported")
  assert.equal(imageProblem({type: "image/jpeg", size: 1001}, max), "too_large")
})

test("the answer of an upload is a known key or failed", () => {
  assert.equal(uploadError({error: "too_large"}), "too_large")
  assert.equal(uploadError({error: "unsupported"}), "unsupported")
  assert.equal(uploadError({error: "boom"}), "failed")
  assert.equal(uploadError(null), "failed")
})

test("a comment is sent by command or control with enter, and by nothing else", () => {
  assert.equal(sends({key: "Enter", metaKey: true}), true)
  assert.equal(sends({key: "Enter", ctrlKey: true}), true)
  assert.equal(sends({key: "Enter"}), false)
  assert.equal(sends({key: "a", metaKey: true}), false)
})

test("the toolbar keys move round the tools, Home and End go to the ends, other keys are left alone", async () => {
  const {toolbarTarget} = await import("./editor_logic.js")
  assert.equal(toolbarTarget("ArrowRight", 2, 3), 0)
  assert.equal(toolbarTarget("ArrowLeft", 0, 3), 2)
  assert.equal(toolbarTarget("Home", 2, 3), 0)
  assert.equal(toolbarTarget("End", 0, 3), 2)
  assert.equal(toolbarTarget("a", 0, 3), null)
})

test("the text area is named by its label, or by the visible label when there is one", () => {
  const plain = textboxAttributes({label: "Notes", invalid: false, disabled: false})
  assert.equal(plain["aria-label"], "Notes")
  assert.equal(plain["aria-labelledby"], null)
  assert.equal(plain["aria-invalid"], null)

  const labelled = textboxAttributes({label: "Notes", labelledby: "e-label", describedby: "e-error", invalid: true, disabled: true})
  assert.equal(labelled["aria-label"], null)
  assert.equal(labelled["aria-labelledby"], "e-label")
  assert.equal(labelled["aria-describedby"], "e-error")
  assert.equal(labelled["aria-invalid"], "true")
  assert.equal(labelled["aria-disabled"], "true")
})

test("a menu row has the label, and the icon and the hint when the item has them", () => {
  assert.deepEqual(rowParts({label: "Heading"}).map((part) => part.text), ["Heading"])
  assert.deepEqual(rowParts({label: "Heading", icon: "H", hint: "#"}).map((part) => part.text), ["H", "Heading", "#"])
})
