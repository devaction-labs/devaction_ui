import test from "node:test"
import assert from "node:assert/strict"
import {clamp, clampText, keyDelta, parseLimit} from "./number_logic.js"

const limits = {step: 2, min: 1, max: 9}

test("the arrows move a step and the page keys ten", () => {
  assert.equal(keyDelta("ArrowUp", "3", limits), 2)
  assert.equal(keyDelta("ArrowDown", "5", limits), -2)
  assert.equal(keyDelta("PageUp", "1", {step: 1, min: 0, max: 100}), 10)
  assert.equal(keyDelta("PageDown", "50", {step: 1, min: 0, max: 100}), -10)
})

test("a move that would pass a limit stops at it, and none at the limit moves nothing", () => {
  assert.equal(keyDelta("PageUp", "3", limits), 6)
  assert.equal(keyDelta("PageDown", "3", limits), -2)
  assert.equal(keyDelta("ArrowUp", "9", limits), null)
  assert.equal(keyDelta("ArrowDown", "1", limits), null)
})

test("other keys and text that is not a number move nothing", () => {
  assert.equal(keyDelta("Enter", "3", limits), null)
  assert.equal(keyDelta("ArrowUp", "", limits), null)
  assert.equal(keyDelta("ArrowUp", "abc", limits), null)
})

test("no limit means no clamping", () => {
  assert.equal(keyDelta("ArrowDown", "-5", {step: 1, min: null, max: null}), -1)
  assert.equal(clamp(500, null, null), 500)
  assert.equal(clamp(500, null, 9), 9)
  assert.equal(clamp(-5, 0, null), 0)
})

test("limits are read from attributes", () => {
  assert.equal(parseLimit(undefined), null)
  assert.equal(parseLimit(""), null)
  assert.equal(parseLimit("12"), 12)
  assert.equal(parseLimit("0"), 0)
})

test("what is typed is held inside the limits, and text that is not a number is kept", () => {
  assert.equal(clampText("50", limits), "9")
  assert.equal(clampText("0", limits), "1")
  assert.equal(clampText("5", limits), "5")
  assert.equal(clampText("-3", {min: null, max: 9}), "-3")
  assert.equal(clampText("", limits), "")
  assert.equal(clampText("1.5", limits), "1.5")
})
