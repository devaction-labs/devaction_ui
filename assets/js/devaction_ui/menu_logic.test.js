import assert from "node:assert/strict"
import test from "node:test"
import {buttonView, closesOnSelect, counts, extendBuffer, isExpanded, isTypeahead, matchIndex, pendingCount, resetAction, selectedStates} from "./menu_logic.js"

const key = (key, extra = {}) => ({key, ctrlKey: false, metaKey: false, altKey: false, ...extra})

test("letters and digits type ahead, shortcuts, Space and named keys do not", () => {
  assert.equal(isTypeahead(key("d")), true)
  assert.equal(isTypeahead(key("7")), true)
  assert.equal(isTypeahead(key(" ")), false)
  assert.equal(isTypeahead(key("Enter")), false)
  assert.equal(isTypeahead(key("d", {metaKey: true})), false)
  assert.equal(isTypeahead(key("d", {ctrlKey: true})), false)
})

test("the letters add up, and a pause starts them over", () => {
  assert.equal(extendBuffer("", "D", 0), "d")
  assert.equal(extendBuffer("d", "e", 200), "de")
  assert.equal(extendBuffer("de", "l", 900), "l")
})

const labels = ["Edit", "Duplicate", "Delete", "Archive", "Download"]

test("one letter goes to the next item that starts with it", () => {
  assert.equal(matchIndex(labels, 0, "d"), 1)
  assert.equal(matchIndex(labels, 1, "d"), 2)
  assert.equal(matchIndex(labels, 4, "d"), 1)
})

test("the same letter again goes round the items that start with it", () => {
  assert.equal(matchIndex(labels, 1, "dd"), 2)
  assert.equal(matchIndex(labels, 2, "ddd"), 4)
})

test("several letters stay on the first item that starts with all of them, the active one included", () => {
  assert.equal(matchIndex(labels, 0, "de"), 2)
  assert.equal(matchIndex(labels, 2, "de"), 2)
  assert.equal(matchIndex(labels, 0, "du"), 1)
})

test("no item, or no items, is -1", () => {
  assert.equal(matchIndex(labels, 0, "z"), -1)
  assert.equal(matchIndex([], -1, "a"), -1)
})

test("a menu closes on select unless it says false", () => {
  assert.equal(closesOnSelect("true"), true)
  assert.equal(closesOnSelect(undefined), true)
  assert.equal(closesOnSelect("false"), false)
})

const option = (group, checked, isDefault = false) => ({group, checked, isDefault})

test("each group counts what is ticked in it and the total counts all", () => {
  const result = counts([option("status", true), option("status", true), option("status", false), option("who", true)])

  assert.deepEqual(result.byGroup, {status: 2, who: 1})
  assert.equal(result.total, 3)
})

test("a ticked default is not a filter", () => {
  const result = counts([option("order", true, true), option("status", true)])

  assert.deepEqual(result.byGroup, {status: 1})
  assert.equal(result.total, 1)
})

test("nothing ticked is nothing counted", () => {
  assert.deepEqual(counts([option("status", false)]), {byGroup: {}, total: 0})
  assert.deepEqual(counts([]), {byGroup: {}, total: 0})
})

const tick = (group, value, checked) => ({group, value, checked})

test("pending is what Apply would change: ticks added and ticks removed", () => {
  const applied = [tick("status", "todo", true), tick("status", "done", false), tick("who", "ca", false)]
  const draft = [tick("status", "todo", false), tick("status", "done", true), tick("who", "ca", true)]

  assert.equal(pendingCount(draft, applied), 3)
})

test("nothing is pending when the draft is what was applied", () => {
  const options = [tick("status", "todo", true), tick("status", "done", false)]

  assert.equal(pendingCount(options, options), 0)
  assert.equal(pendingCount([], []), 0)
})

test("the same value in two groups is two different options", () => {
  const applied = [tick("a", "x", true), tick("b", "x", false)]
  const draft = [tick("a", "x", false), tick("b", "x", true)]

  assert.equal(pendingCount(draft, applied), 2)
})

test("Clear submits only when the menu says so, otherwise it tells the form it changed", () => {
  assert.equal(resetAction("submit"), "submit")
  assert.equal(resetAction("change"), "change")
  assert.equal(resetAction(undefined), "change")
})

test("a chosen option shows its label, not muted", () => {
  assert.deepEqual(buttonView({label: "Hub"}, "Choose"), {text: "Hub", muted: false})
})

test("nothing chosen shows the placeholder, muted", () => {
  assert.deepEqual(buttonView(null, "Choose"), {text: "Choose", muted: true})
  assert.deepEqual(buttonView(undefined, "Choose"), {text: "Choose", muted: true})
})

test("an option with an empty label is still a choice", () => {
  assert.deepEqual(buttonView({label: ""}, "Choose"), {text: "", muted: false})
})

test("the field is expanded only for a visible list that has rows", () => {
  assert.equal(isExpanded({hasList: true, visible: true, options: 3}), true)
  assert.equal(isExpanded({hasList: true, visible: true, options: 0}), false)
  assert.equal(isExpanded({hasList: true, visible: false, options: 3}), false)
  assert.equal(isExpanded({hasList: false, visible: true, options: 3}), false)
})

test("exactly the active row is selected", () => {
  assert.deepEqual(selectedStates(3, 1), ["false", "true", "false"])
  assert.deepEqual(selectedStates(2, -1), ["false", "false"])
  assert.deepEqual(selectedStates(0, 0), [])
})
