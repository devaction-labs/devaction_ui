import test from "node:test"
import assert from "node:assert/strict"
import {fold, matches} from "./text.js"

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
