import test from "node:test"
import assert from "node:assert/strict"
import {depthAfter, isOver, overText} from "./dropzone_logic.js"

test("the announcement is the caller's text while over, and nothing otherwise", () => {
  assert.equal(overText(1, "Drop to upload"), "Drop to upload")
  assert.equal(overText(0, "Drop to upload"), "")
  assert.equal(overText(2, undefined), "")
})

test("crossing into a child and out of the parent keeps the zone lit", () => {
  const events = ["dragenter", "dragenter", "dragleave"]
  const depth = events.reduce(depthAfter, 0)
  assert.equal(depth, 1)
  assert.equal(isOver(depth), true)
})

test("the last leave, or a drop, puts it out", () => {
  assert.equal(isOver(["dragenter", "dragleave"].reduce(depthAfter, 0)), false)
  assert.equal(isOver(["dragenter", "dragenter", "drop"].reduce(depthAfter, 0)), false)
})

test("a stray leave never goes below zero and other events change nothing", () => {
  assert.equal(depthAfter(0, "dragleave"), 0)
  assert.equal(depthAfter(2, "dragover"), 2)
})
