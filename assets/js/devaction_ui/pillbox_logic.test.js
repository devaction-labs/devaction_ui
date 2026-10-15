import test from "node:test"
import assert from "node:assert/strict"
import {clean, isTaken} from "./pillbox_logic.js"

test("cleaning trims and drops the comma that ended the word", () => {
  assert.equal(clean("  docs, "), "docs")
  assert.equal(clean("a,"), "a")
  assert.equal(clean("   "), "")
})

test("a repeat is a repeat whatever its case", () => {
  assert.equal(isTaken(["backend", "Docs"], "docs"), true)
  assert.equal(isTaken(["backend"], "docs"), false)
  assert.equal(isTaken([], "docs"), false)
})
