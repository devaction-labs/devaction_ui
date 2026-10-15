import test from "node:test"
import assert from "node:assert/strict"
import {target} from "./calendar_logic.js"

const grid = {columns: 7, total: 35}

test("the arrows move a day or a week and stop at the edges", () => {
  assert.equal(target(10, "ArrowRight", grid), 11)
  assert.equal(target(10, "ArrowLeft", grid), 9)
  assert.equal(target(10, "ArrowDown", grid), 17)
  assert.equal(target(10, "ArrowUp", grid), 3)
  assert.equal(target(0, "ArrowLeft", grid), 0)
  assert.equal(target(34, "ArrowRight", grid), 34)
  assert.equal(target(2, "ArrowUp", grid), 0)
  assert.equal(target(33, "ArrowDown", grid), 34)
})

test("Home and End go to the ends of the week", () => {
  assert.equal(target(10, "Home", grid), 7)
  assert.equal(target(10, "End", grid), 13)
  assert.equal(target(0, "Home", grid), 0)
  assert.equal(target(34, "End", grid), 34)
})

test("the page keys ask for another month and other keys are not ours", () => {
  assert.equal(target(10, "PageUp", grid), "prev")
  assert.equal(target(10, "PageDown", grid), "next")
  assert.equal(target(10, "a", grid), null)
  assert.equal(target(10, "Enter", grid), null)
})
