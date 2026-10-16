import test from "node:test"
import assert from "node:assert/strict"
import {nextDensity, rangeBetween, selectionState, toggledExpanded} from "./data_table_logic.js"

test("a Shift+click range is inclusive and ignores the direction", () => {
  assert.deepEqual(rangeBetween(1, 3), [1, 2, 3])
  assert.deepEqual(rangeBetween(3, 1), [1, 2, 3])
  assert.deepEqual(rangeBetween(2, 2), [2])
})

test("the chevron opens a closed row and closes an open one", () => {
  assert.equal(toggledExpanded("false"), "true")
  assert.equal(toggledExpanded("true"), "false")
  assert.equal(toggledExpanded(null), "true")
})

test("nothing ticked: no bar, header clear", () => {
  assert.deepEqual(selectionState(0, 4), {all: false, mixed: false, barHidden: true})
})

test("some ticked: the header is mixed and the bar shows", () => {
  assert.deepEqual(selectionState(2, 4), {all: false, mixed: true, barHidden: false})
})

test("all ticked: the header is checked", () => {
  assert.deepEqual(selectionState(4, 4), {all: true, mixed: false, barHidden: false})
})

test("the density toggle goes to the other density", () => {
  assert.equal(nextDensity("comfortable"), "compact")
  assert.equal(nextDensity("compact"), "comfortable")
  assert.equal(nextDensity(undefined), "comfortable")
})

test("an empty table is never all selected", () => {
  assert.deepEqual(selectionState(0, 0), {all: false, mixed: false, barHidden: true})
})
