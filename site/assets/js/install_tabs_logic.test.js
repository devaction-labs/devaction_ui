import test from "node:test"
import assert from "node:assert/strict"
import {nextIndex, tabStates} from "./install_tabs_logic.js"

test("arrows wrap around and Home and End jump to the ends", () => {
  assert.equal(nextIndex(3, 2, "ArrowRight"), 0)
  assert.equal(nextIndex(3, 0, "ArrowLeft"), 2)
  assert.equal(nextIndex(3, 1, "Home"), 0)
  assert.equal(nextIndex(3, 1, "End"), 2)
})

test("any other key moves nowhere", () => {
  assert.equal(nextIndex(3, 1, "a"), null)
})

test("only the active tab is selected and in the tab order", () => {
  assert.deepEqual(tabStates(["mix", "css"], "css"), [
    {id: "mix", selected: false, tabindex: "-1"},
    {id: "css", selected: true, tabindex: "0"},
  ])
})
