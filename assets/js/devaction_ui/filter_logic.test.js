import test from "node:test"
import assert from "node:assert/strict"
import {counts, pendingCount, submenuSide} from "./filter_logic.js"

const option = (group, checked, isDefault = false) => ({group, checked, isDefault})

test("each group counts what is ticked in it and the total counts all", () => {
  const result = counts([option("status", true), option("status", true), option("status", false), option("who", true)])

  assert.deepEqual(result.byGroup, {status: 2, who: 1})
  assert.equal(result.total, 3)
})

test("a ticked default is not a filter", () => {
  const result = counts([option("order", true, true), option("status", true)])

  assert.deepEqual(result.byGroup, {status: 1})
  assert.equal(result.total, 1)
})

test("nothing ticked is nothing counted", () => {
  assert.deepEqual(counts([option("status", false)]), {byGroup: {}, total: 0})
  assert.deepEqual(counts([]), {byGroup: {}, total: 0})
})

const tick = (group, value, checked) => ({group, value, checked})

test("pending is what Apply would change: ticks added and ticks removed", () => {
  const applied = [tick("status", "todo", true), tick("status", "done", false), tick("who", "ca", false)]
  const draft = [tick("status", "todo", false), tick("status", "done", true), tick("who", "ca", true)]

  assert.equal(pendingCount(draft, applied), 3)
})

test("nothing is pending when the draft is what was applied", () => {
  const options = [tick("status", "todo", true), tick("status", "done", false)]

  assert.equal(pendingCount(options, options), 0)
  assert.equal(pendingCount([], []), 0)
})

test("the same value in two groups is two different options", () => {
  const applied = [tick("a", "x", true), tick("b", "x", false)]
  const draft = [tick("a", "x", false), tick("b", "x", true)]

  assert.equal(pendingCount(draft, applied), 2)
})

test("a submenu stays on its side when it fits", () => {
  assert.equal(submenuSide("right", {panel: 236, left: 100, right: 400}), "right")
  assert.equal(submenuSide("left", {panel: 236, left: 400, right: 100}), "left")
})

test("a submenu goes to the other side when it does not fit and the other has more room", () => {
  assert.equal(submenuSide("right", {panel: 236, left: 500, right: 100}), "left")
  assert.equal(submenuSide("left", {panel: 236, left: 100, right: 500}), "right")
})

test("a submenu stays when neither side has room", () => {
  assert.equal(submenuSide("right", {panel: 236, left: 50, right: 100}), "right")
})
