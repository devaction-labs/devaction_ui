import test from "node:test"
import assert from "node:assert/strict"
import {dismissesOnTap, withDescription} from "./tooltip_logic.js"

test("a control with no description gets the tooltip's id", () => {
  assert.equal(withDescription(null, "t-tip"), "t-tip")
  assert.equal(withDescription("", "t-tip"), "t-tip")
})

test("the descriptions it already had are kept", () => {
  assert.equal(withDescription("hint", "t-tip"), "hint t-tip")
  assert.equal(withDescription("  a   b ", "t-tip"), "a b t-tip")
})

test("the id is never added twice", () => {
  assert.equal(withDescription("t-tip", "t-tip"), "t-tip")
  assert.equal(withDescription("a t-tip", "t-tip"), "a t-tip")
})

test("a touch dismisses the hint, a mouse or a pen does not", () => {
  assert.equal(dismissesOnTap("touch"), true)
  assert.equal(dismissesOnTap("mouse"), false)
  assert.equal(dismissesOnTap("pen"), false)
  assert.equal(dismissesOnTap(undefined), false)
})
