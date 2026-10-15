import test from "node:test"
import assert from "node:assert/strict"
import {insertionIndex, isFull, parseWip} from "./kanban_logic.js"

test("a column is full only when it has a limit, is at it and the card comes from outside", () => {
  assert.equal(isFull({count: 2, wip: 2, sameColumn: false}), true)
  assert.equal(isFull({count: 1, wip: 2, sameColumn: false}), false)
  assert.equal(isFull({count: 5, wip: 2, sameColumn: true}), false)
  assert.equal(isFull({count: 5, wip: NaN, sameColumn: false}), false)
  assert.equal(isFull({count: 5, wip: 0, sameColumn: false}), false)
})

test("the limit is read from the attribute, and absent means none", () => {
  assert.equal(parseWip("3"), 3)
  assert.ok(Number.isNaN(parseWip(undefined)))
  assert.ok(Number.isNaN(parseWip("")))
})

test("the pointer picks the slot by the middles of the cards", () => {
  const boxes = [{top: 0, height: 40}, {top: 50, height: 40}, {top: 100, height: 40}]
  assert.equal(insertionIndex(boxes, 5), 0)
  assert.equal(insertionIndex(boxes, 30), 1)
  assert.equal(insertionIndex(boxes, 75), 2)
  assert.equal(insertionIndex(boxes, 500), 3)
  assert.equal(insertionIndex([], 10), 0)
})
