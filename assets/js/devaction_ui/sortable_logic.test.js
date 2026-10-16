import assert from "node:assert/strict"
import test from "node:test"
import {atEnds, heldMove, moveBy, placeAt, sameOrder, say, targetIndex} from "./sortable_logic.js"

const order = ["m1", "m2", "m3", "m4"]

test("a row moves up and down by one place", () => {
  assert.deepEqual(moveBy(order, "m2", 1), ["m1", "m3", "m2", "m4"])
  assert.deepEqual(moveBy(order, "m3", -1), ["m1", "m3", "m2", "m4"])
})

test("a row does not move past either end", () => {
  assert.deepEqual(moveBy(order, "m1", -1), order)
  assert.deepEqual(moveBy(order, "m4", 1), order)
  assert.deepEqual(moveBy(order, "m1", 99), ["m2", "m3", "m4", "m1"])
})

test("placeAt puts the row among the others and ignores an unknown id", () => {
  assert.deepEqual(placeAt(order, "m4", 0), ["m4", "m1", "m2", "m3"])
  assert.deepEqual(placeAt(order, "m1", 2), ["m2", "m3", "m1", "m4"])
  assert.deepEqual(placeAt(order, "zz", 1), order)
})

test("sameOrder compares ids in place", () => {
  assert.equal(sameOrder(order, [...order]), true)
  assert.equal(sameOrder(order, ["m2", "m1", "m3", "m4"]), false)
  assert.equal(sameOrder(order, ["m1"]), false)
})

test("the first row has no up and the last has no down", () => {
  assert.deepEqual(atEnds(0, 3), {up: true, down: false})
  assert.deepEqual(atEnds(1, 3), {up: false, down: false})
  assert.deepEqual(atEnds(2, 3), {up: false, down: true})
  assert.deepEqual(atEnds(0, 1), {up: true, down: true})
})

test("a picked-up row answers the arrows, Home and End and no other key", () => {
  assert.equal(targetIndex(heldMove("ArrowDown"), 1, 4), 2)
  assert.equal(targetIndex(heldMove("ArrowUp"), 0, 4), 0)
  assert.equal(targetIndex(heldMove("Home"), 2, 4), 0)
  assert.equal(targetIndex(heldMove("End"), 1, 4), 3)
  assert.equal(heldMove("a"), undefined)
})

test("the text of the live region carries the name and the place", () => {
  assert.equal(say("__ITEM__: __POS__ of __TOTAL__", {item: "Agenda", pos: 2, total: 5}), "Agenda: 2 of 5")
  assert.equal(say("moved", {item: "x", pos: 1, total: 1}), "moved")
})
