import test from "node:test"
import assert from "node:assert/strict"
import {fitScale} from "./fit_logic.js"

test("a screen wider than the room shrinks in proportion", () => {
  assert.equal(fitScale(720, 1440), 0.5)
  assert.equal(fitScale(360, 1440), 0.25)
})

test("a screen that already fits is not enlarged", () => {
  assert.equal(fitScale(2000, 1440), 1)
  assert.equal(fitScale(1440, 1440), 1)
})

test("a design with no width is left alone", () => {
  assert.equal(fitScale(500, 0), 1)
})
