import test from "node:test"
import assert from "node:assert/strict"
import {selectionState} from "./data_table_logic.js"

test("nothing ticked: no bar, header clear", () => {
  assert.deepEqual(selectionState(0, 4), {all: false, mixed: false, barHidden: true})
})

test("some ticked: the header is mixed and the bar shows", () => {
  assert.deepEqual(selectionState(2, 4), {all: false, mixed: true, barHidden: false})
})

test("all ticked: the header is checked", () => {
  assert.deepEqual(selectionState(4, 4), {all: true, mixed: false, barHidden: false})
})

test("an empty table is never all selected", () => {
  assert.deepEqual(selectionState(0, 0), {all: false, mixed: false, barHidden: true})
})
