import test from "node:test"
import assert from "node:assert/strict"
import {counts} from "./filter_logic.js"

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
