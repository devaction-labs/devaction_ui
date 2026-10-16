import test from "node:test"
import assert from "node:assert/strict"
import {isExpanded, selectedStates} from "./autocomplete_logic.js"

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
