import test from "node:test"
import assert from "node:assert/strict"
import {percent} from "./range_logic.js"

test("the value is placed between the minimum and the maximum", () => {
  assert.equal(percent(50, 0, 100), 50)
  assert.equal(percent(75, 50, 100), 50)
  assert.equal(percent("3", "1", "5"), 50)
})

test("the ends are 0 and 100", () => {
  assert.equal(percent(0, 0, 100), 0)
  assert.equal(percent(100, 0, 100), 100)
})

test("a range with no width is 0", () => {
  assert.equal(percent(5, 5, 5), 0)
})
