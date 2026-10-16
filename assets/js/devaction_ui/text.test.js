import assert from "node:assert/strict"
import test from "node:test"
import {clean, fillLabel, fold, isTaken, matches} from "./text.js"

test("folding drops accents and case", () => {
  assert.equal(fold("Pão Quente"), "pao quente")
  assert.equal(fold("Dízimos"), "dizimos")
})

test("a label matches a term in the middle, ignoring accents; blank matches all", () => {
  assert.equal(matches("Padaria Pão Quente", "pao"), true)
  assert.equal(matches("SGE · Igreja Central", "IGREJA"), true)
  assert.equal(matches("Hub", "pao"), false)
  assert.equal(matches("Hub", "  "), true)
})

test("a label pattern is filled with the pill's text", () => {
  assert.equal(fillLabel("Remove %{label}", "docs"), "Remove docs")
  assert.equal(fillLabel("%{label} added", "a b"), "a b added")
  assert.equal(fillLabel("Remove", "docs"), "Remove")
  assert.equal(fillLabel(undefined, "docs"), undefined)
})

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
