import test from "node:test"
import assert from "node:assert/strict"
import {closesOnSelect, extendBuffer, isTypeahead, matchIndex} from "./dropdown_logic.js"

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
