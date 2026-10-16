import assert from "node:assert/strict"
import test from "node:test"
import {decide, gridTarget, isTyping, keyName, moveSegment, nextTab, runKey, tabExit, tabStop, treeKey, wrap} from "./keys.js"

const event = (key, mods = {}) => ({key, altKey: false, metaKey: false, ctrlKey: false, prevented: false, preventDefault() { this.prevented = true }, ...mods})

test("a key's name carries its modifiers", () => {
  assert.equal(keyName(event("Enter")), "Enter")
  assert.equal(keyName(event("Enter", {ctrlKey: true})), "Mod+Enter")
  assert.equal(keyName(event("Enter", {metaKey: true})), "Mod+Enter")
  assert.equal(keyName(event("ArrowLeft", {altKey: true})), "Alt+ArrowLeft")
})

test("the table's handler runs and the event is consumed", () => {
  let ran = 0
  const e = event("Enter")
  assert.equal(runKey({Enter: () => ran++}, e), true)
  assert.equal(ran, 1)
  assert.equal(e.prevented, true)
})

test("a key the table does not know is left alone", () => {
  const e = event("x")
  assert.equal(runKey({Enter: () => {}}, e), false)
  assert.equal(e.prevented, false)
})

test("a handler that returns false declines the key", () => {
  const e = event("Enter")
  assert.equal(runKey({Enter: () => false}, e), false)
  assert.equal(e.prevented, false)
})

test("wrap goes round both ways and survives an empty list", () => {
  assert.equal(wrap(2, 1, 3), 0)
  assert.equal(wrap(0, -1, 3), 2)
  assert.equal(wrap(0, 1, 0), -1)
})

test("the first rule whose test passes decides, with the arguments given", () => {
  const rules = [
    [(n) => n < 0, () => "negative"],
    [(n) => n === 0, () => "zero"],
    [() => true, (n) => `positive ${n}`],
  ]
  assert.equal(decide(rules, -3), "negative")
  assert.equal(decide(rules, 0), "zero")
  assert.equal(decide(rules, 7), "positive 7")
})

const grid = {columns: 7, total: 35}

test("the arrows move a day or a week and stop at the edges", () => {
  assert.equal(gridTarget(10, "ArrowRight", grid), 11)
  assert.equal(gridTarget(10, "ArrowLeft", grid), 9)
  assert.equal(gridTarget(10, "ArrowDown", grid), 17)
  assert.equal(gridTarget(10, "ArrowUp", grid), 3)
  assert.equal(gridTarget(0, "ArrowLeft", grid), 0)
  assert.equal(gridTarget(34, "ArrowRight", grid), 34)
  assert.equal(gridTarget(2, "ArrowUp", grid), 0)
  assert.equal(gridTarget(33, "ArrowDown", grid), 34)
})

test("Home and End go to the ends of the week", () => {
  assert.equal(gridTarget(10, "Home", grid), 7)
  assert.equal(gridTarget(10, "End", grid), 13)
  assert.equal(gridTarget(0, "Home", grid), 0)
  assert.equal(gridTarget(34, "End", grid), 34)
})

test("the page keys ask for another month and other keys are not ours", () => {
  assert.equal(gridTarget(10, "PageUp", grid), "prev")
  assert.equal(gridTarget(10, "PageDown", grid), "next")
  assert.equal(gridTarget(10, "a", grid), null)
  assert.equal(gridTarget(10, "Enter", grid), null)
})

const item = (pressed = false, disabled = false) => ({pressed, disabled})

test("the pressed segment is the tab stop", () => {
  assert.equal(tabStop([item(), item(true), item()]), 1)
})

test("with none pressed the first enabled one is the tab stop", () => {
  assert.equal(tabStop([item(false, true), item(), item()]), 1)
})

test("a pressed segment that is disabled does not hold the tab stop", () => {
  assert.equal(tabStop([item(), item(true, true)]), 0)
})

test("with every segment disabled there is no tab stop", () => {
  assert.equal(tabStop([item(false, true), item(false, true)]), -1)
  assert.equal(tabStop([]), -1)
})

test("right and down step forward and wrap", () => {
  const items = [item(), item(), item()]
  assert.equal(moveSegment(items, 0, "ArrowRight"), 1)
  assert.equal(moveSegment(items, 1, "ArrowDown"), 2)
  assert.equal(moveSegment(items, 2, "ArrowRight"), 0)
})

test("left and up step back and wrap", () => {
  const items = [item(), item(), item()]
  assert.equal(moveSegment(items, 2, "ArrowLeft"), 1)
  assert.equal(moveSegment(items, 1, "ArrowUp"), 0)
  assert.equal(moveSegment(items, 0, "ArrowLeft"), 2)
})

test("home and end go to the first and the last enabled segment", () => {
  const items = [item(false, true), item(), item(), item(false, true)]
  assert.equal(moveSegment(items, 2, "Home"), 1)
  assert.equal(moveSegment(items, 1, "End"), 2)
})

test("a disabled segment is skipped", () => {
  const items = [item(), item(false, true), item()]
  assert.equal(moveSegment(items, 0, "ArrowRight"), 2)
  assert.equal(moveSegment(items, 2, "ArrowLeft"), 0)
})

test("a key the control does not use gives nothing", () => {
  assert.equal(moveSegment([item(), item()], 0, "a"), undefined)
  assert.equal(moveSegment([item(), item()], 0, "Enter"), undefined)
})

test("nothing to go to when every segment is disabled", () => {
  assert.equal(moveSegment([item(false, true)], 0, "ArrowRight"), undefined)
  assert.equal(moveSegment([item(false, true)], 0, "Home"), undefined)
})

test("the arrows move one tab and wrap round the list", () => {
  assert.equal(nextTab("ArrowRight", 0, 3), 1)
  assert.equal(nextTab("ArrowRight", 2, 3), 0)
  assert.equal(nextTab("ArrowLeft", 1, 3), 0)
  assert.equal(nextTab("ArrowLeft", 0, 3), 2)
})

test("Home and End jump to the ends", () => {
  assert.equal(nextTab("Home", 2, 4), 0)
  assert.equal(nextTab("End", 0, 4), 3)
})

test("a key that does not move the selection, or an empty list, gives null", () => {
  assert.equal(nextTab("Enter", 1, 3), null)
  assert.equal(nextTab("Alt+ArrowLeft", 1, 3), null)
  assert.equal(nextTab("ArrowRight", 0, 0), null)
})

test("a vertical list moves with up and down and ignores left and right", () => {
  const vertical = {orientation: "vertical"}
  assert.equal(nextTab("ArrowDown", 0, 3, vertical), 1)
  assert.equal(nextTab("ArrowDown", 2, 3, vertical), 0)
  assert.equal(nextTab("ArrowUp", 0, 3, vertical), 2)
  assert.equal(nextTab("Home", 2, 3, vertical), 0)
  assert.equal(nextTab("End", 0, 3, vertical), 2)
  assert.equal(nextTab("ArrowRight", 0, 3, vertical), null)
  assert.equal(nextTab("ArrowLeft", 1, 3, vertical), null)
})

test("a horizontal list ignores up and down", () => {
  assert.equal(nextTab("ArrowDown", 0, 3), null)
  assert.equal(nextTab("ArrowUp", 1, 3, {orientation: "horizontal"}), null)
})

test("on a right-to-left page the horizontal arrows are swapped", () => {
  const rtl = {rtl: true}
  assert.equal(nextTab("ArrowLeft", 0, 3, rtl), 1)
  assert.equal(nextTab("ArrowRight", 0, 3, rtl), 2)
  assert.equal(nextTab("Home", 2, 3, rtl), 0)
})

test("right-to-left does not change a vertical list", () => {
  assert.equal(nextTab("ArrowDown", 0, 3, {orientation: "vertical", rtl: true}), 1)
})

test("an unknown orientation moves nowhere", () => {
  assert.equal(nextTab("ArrowDown", 0, 3, {orientation: "diagonal"}), null)
})

test("Tab at the last control leaves forward, Shift+Tab at the first returns to the trigger", () => {
  const ends = {first: "a", last: "z"}
  assert.equal(tabExit({shift: false, active: "z", ...ends}), "forward")
  assert.equal(tabExit({shift: true, active: "a", ...ends}), "back")
  assert.equal(tabExit({shift: false, active: "m", ...ends}), null)
  assert.equal(tabExit({shift: true, active: "m", ...ends}), null)
})

const tree = [
  {level: 1, expandable: true, expanded: true},
  {level: 2, expandable: true, expanded: false},
  {level: 3, expandable: false, expanded: false},
  {level: 2, expandable: false, expanded: false},
  {level: 1, expandable: true, expanded: false},
]

test("↑ and ↓ move through the visible items and stop at the ends", () => {
  assert.deepEqual(treeKey("ArrowDown", tree, 0), {focus: 1})
  assert.deepEqual(treeKey("ArrowUp", tree, 3), {focus: 2})
  assert.deepEqual(treeKey("ArrowUp", tree, 0), {focus: 0})
  assert.deepEqual(treeKey("ArrowDown", tree, 4), {focus: 4})
})

test("Home and End jump to the first and last item", () => {
  assert.deepEqual(treeKey("Home", tree, 3), {focus: 0})
  assert.deepEqual(treeKey("End", tree, 0), {focus: 4})
})

test("→ opens a closed folder, enters an open one and does nothing on a file", () => {
  assert.deepEqual(treeKey("ArrowRight", tree, 1), {click: 1})
  assert.deepEqual(treeKey("ArrowRight", tree, 0), {focus: 1})
  assert.equal(treeKey("ArrowRight", tree, 3), null)
})

test("→ on an open folder with nothing inside does nothing", () => {
  assert.equal(treeKey("ArrowRight", [{level: 1, expandable: true, expanded: true}], 0), null)
})

test("← closes an open folder, otherwise goes to the parent", () => {
  assert.deepEqual(treeKey("ArrowLeft", tree, 0), {click: 0})
  assert.deepEqual(treeKey("ArrowLeft", tree, 2), {focus: 1})
  assert.deepEqual(treeKey("ArrowLeft", tree, 3), {focus: 0})
  assert.equal(treeKey("ArrowLeft", tree, 4), null)
})

test("an unknown key, an empty tree or no focused item is not ours", () => {
  assert.equal(treeKey("x", tree, 0), null)
  assert.equal(treeKey("ArrowDown", [], 0), null)
  assert.equal(treeKey("ArrowDown", tree, -1), null)
})

test("typing in a field is told from typing on the page", () => {
  assert.equal(isTyping({tagName: "input"}), true)
  assert.equal(isTyping({tagName: "TEXTAREA"}), true)
  assert.equal(isTyping({tagName: "DIV", isContentEditable: true}), true)
  assert.equal(isTyping({tagName: "BUTTON"}), false)
  assert.equal(isTyping(), false)
})
