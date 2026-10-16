import test from "node:test"
import assert from "node:assert/strict"
import {flip, press} from "./switch_logic.js"

test("flip turns on into off and anything else into on", () => {
  assert.equal(flip("true"), "false")
  assert.equal(flip("false"), "true")
  assert.equal(flip(null), "true")
})

test("a press flips an enabled switch", () => {
  assert.equal(press("false", null), "true")
  assert.equal(press("true", "false"), "false")
})

test("a press leaves a disabled or busy switch as it is", () => {
  assert.equal(press("true", "true"), "true")
  assert.equal(press("false", "true"), "false")
})
