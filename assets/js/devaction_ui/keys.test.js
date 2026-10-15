import test from "node:test"
import assert from "node:assert/strict"
import {keyName, runKey, wrap} from "./keys.js"

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
