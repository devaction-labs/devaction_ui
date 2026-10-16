import test from "node:test"
import assert from "node:assert/strict"
import {dragOffset, dragStyle, settleStyle, shouldClose, speed} from "./sheet_logic.js"

test("the sheet follows the finger down and never goes up past its place", () => {
  assert.equal(dragOffset(100, 180), 80)
  assert.equal(dragOffset(100, 60), 0)
})

test("the speed is pixels per millisecond and a zero interval does not divide by zero", () => {
  assert.equal(speed(0, 0, 100, 100), 1)
  assert.equal(speed(0, 5, 10, 5), 10)
})

test("a long drag closes it, a short one does not", () => {
  assert.equal(shouldClose({offset: 300, height: 600, velocity: 0}), true)
  assert.equal(shouldClose({offset: 100, height: 600, velocity: 0.1}), false)
})

test("a fast flick closes it even when short", () => {
  assert.equal(shouldClose({offset: 40, height: 600, velocity: 0.9}), true)
})

test("a sheet with no height never closes", () => {
  assert.equal(shouldClose({offset: 50, height: 0, velocity: 2}), false)
})

test("the drag has no transition and the settle has none for reduced motion", () => {
  assert.deepEqual(dragStyle(24), {transform: "translateY(24px)", transition: "none"})
  assert.equal(settleStyle(true).transition, "none")
  assert.match(settleStyle(false).transition, /transform/)
  assert.equal(settleStyle(false).transform, "")
})
