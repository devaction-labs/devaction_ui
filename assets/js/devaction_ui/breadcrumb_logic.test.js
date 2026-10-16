import assert from "node:assert/strict"
import test from "node:test"
import {closesOnKey, closesOnPress} from "./breadcrumb_logic.js"

test("Esc closes the list only while it is open", () => {
  assert.equal(closesOnKey({key: "Escape"}, true), true)
  assert.equal(closesOnKey({key: "Escape"}, false), false)
  assert.equal(closesOnKey({key: "Enter"}, true), false)
})

test("a press outside closes the open list, one inside does not", () => {
  const inside = {}
  const root = {contains: (node) => node === inside}
  assert.equal(closesOnPress(root, {}, true), true)
  assert.equal(closesOnPress(root, inside, true), false)
  assert.equal(closesOnPress(root, {}, false), false)
})
