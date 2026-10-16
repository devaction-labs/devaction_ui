import test from "node:test"
import assert from "node:assert/strict"
import {nextTab, resolveSelection} from "./tabs_logic.js"

test("the arrows move one tab and wrap round the list", () => {
  assert.equal(nextTab("ArrowRight", 0, 3), 1)
  assert.equal(nextTab("ArrowRight", 2, 3), 0)
  assert.equal(nextTab("ArrowLeft", 1, 3), 0)
  assert.equal(nextTab("ArrowLeft", 0, 3), 2)
})

test("Home and End jump to the ends", () => {
  assert.equal(nextTab("Home", 2, 4), 0)
  assert.equal(nextTab("End", 0, 4), 3)
})

test("a key that does not move the selection, or an empty list, gives null", () => {
  assert.equal(nextTab("Enter", 1, 3), null)
  assert.equal(nextTab("Alt+ArrowLeft", 1, 3), null)
  assert.equal(nextTab("ArrowRight", 0, 0), null)
})

const ids = ["a", "b", "c"]

test("the tab the person chose survives a patch that leaves the server's selection alone", () => {
  assert.deepEqual(resolveSelection({chosen: "c", lastServer: "a", server: "a", ids}), {
    selected: "c",
    chosen: "c",
    lastServer: "a",
  })
})

test("a changed server selection wins over the person's choice", () => {
  assert.deepEqual(resolveSelection({chosen: "c", lastServer: "a", server: "b", ids}), {
    selected: "b",
    chosen: "",
    lastServer: "b",
  })
})

test("with no choice the server's selection stands", () => {
  assert.deepEqual(resolveSelection({chosen: "", lastServer: "a", server: "a", ids}), {
    selected: "a",
    chosen: "",
    lastServer: "a",
  })
})

test("a chosen tab that no longer exists falls back to the server's", () => {
  assert.deepEqual(resolveSelection({chosen: "z", lastServer: "a", server: "a", ids}), {
    selected: "a",
    chosen: "",
    lastServer: "a",
  })
})
