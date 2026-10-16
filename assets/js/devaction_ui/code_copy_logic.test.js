import test from "node:test"
import assert from "node:assert/strict"
import {canCopy, next} from "./code_copy_logic.js"

test("a copy lights the button and the timer puts it out", () => {
  assert.equal(next("idle", "copy"), "copied")
  assert.equal(next("copied", "copy"), "copied")
  assert.equal(next("copied", "reset"), "idle")
})

test("an event the state does not know changes nothing", () => {
  assert.equal(next("idle", "reset"), "idle")
  assert.equal(next("copied", "other"), "copied")
  assert.equal(next("unknown", "copy"), "unknown")
})

test("it can copy only where the clipboard can be written", () => {
  assert.equal(canCopy({clipboard: {writeText: () => {}}}), true)
  assert.equal(canCopy({clipboard: {}}), false)
  assert.equal(canCopy({}), false)
  assert.equal(canCopy(undefined), false)
})
