import test from "node:test"
import assert from "node:assert/strict"
import {clampPair, fillBox, pairText, percent, valueText} from "./range_logic.js"

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

test("the thumb that moves stops at the other one", () => {
  assert.deepEqual(clampPair(80, 50, "low"), {low: 50, high: 50})
  assert.deepEqual(clampPair(20, 50, "low"), {low: 20, high: 50})
  assert.deepEqual(clampPair(20, 10, "high"), {low: 20, high: 20})
  assert.deepEqual(clampPair("20", "70", "high"), {low: 20, high: 70})
})

test("the filled part runs from the low value to the high one", () => {
  assert.deepEqual(fillBox(20, 70, 0, 100), {left: 20, width: 50})
  assert.deepEqual(fillBox(5, 15, 0, 20), {left: 25, width: 50})
  assert.deepEqual(fillBox(0.5, 1.5, 0, 2), {left: 25, width: 50})
})

test("the value text fills the template, and no template is the number", () => {
  assert.equal(valueText("R$ %{value}k", 40), "R$ 40k")
  assert.equal(valueText(undefined, 40), "40")
  assert.equal(pairText("%{value} h", 2, 8), "2 h – 8 h")
  assert.equal(pairText(undefined, 2.5, 8), "2.5 – 8")
})
