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

test("a vertical list moves with up and down and ignores left and right", () => {
  const vertical = {orientation: "vertical"}
  assert.equal(nextTab("ArrowDown", 0, 3, vertical), 1)
  assert.equal(nextTab("ArrowDown", 2, 3, vertical), 0)
  assert.equal(nextTab("ArrowUp", 0, 3, vertical), 2)
  assert.equal(nextTab("Home", 2, 3, vertical), 0)
  assert.equal(nextTab("End", 0, 3, vertical), 2)
  assert.equal(nextTab("ArrowRight", 0, 3, vertical), null)
  assert.equal(nextTab("ArrowLeft", 1, 3, vertical), null)
})

test("a horizontal list ignores up and down", () => {
  assert.equal(nextTab("ArrowDown", 0, 3), null)
  assert.equal(nextTab("ArrowUp", 1, 3, {orientation: "horizontal"}), null)
})

test("on a right-to-left page the horizontal arrows are swapped", () => {
  const rtl = {rtl: true}
  assert.equal(nextTab("ArrowLeft", 0, 3, rtl), 1)
  assert.equal(nextTab("ArrowRight", 0, 3, rtl), 2)
  assert.equal(nextTab("Home", 2, 3, rtl), 0)
})

test("right-to-left does not change a vertical list", () => {
  assert.equal(nextTab("ArrowDown", 0, 3, {orientation: "vertical", rtl: true}), 1)
})

test("an unknown orientation moves nowhere", () => {
  assert.equal(nextTab("ArrowDown", 0, 3, {orientation: "diagonal"}), null)
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
