import test from "node:test"
import assert from "node:assert/strict"
import {chooseSide} from "./popover_logic.js"

test("it opens where asked when there is room", () => {
  assert.equal(chooseSide("bottom", {panel: 200, above: 100, below: 400}), "bottom")
  assert.equal(chooseSide("top", {panel: 200, above: 400, below: 100}), "top")
})

test("it flips when the asked side is too short and the other has more room", () => {
  assert.equal(chooseSide("bottom", {panel: 200, above: 500, below: 100}), "top")
  assert.equal(chooseSide("top", {panel: 200, above: 100, below: 500}), "bottom")
})

test("it stays when both sides are short and the other is no better", () => {
  assert.equal(chooseSide("bottom", {panel: 400, above: 100, below: 150}), "bottom")
})
