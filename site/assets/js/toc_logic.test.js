import test from "node:test"
import assert from "node:assert/strict"
import {activeId} from "./toc_logic.js"

test("the last section whose top has passed the offset is the active one", () => {
  const tops = [{id: "a", top: -400}, {id: "b", top: -20}, {id: "c", top: 300}]
  assert.equal(activeId(tops), "b")
})

test("before any section has passed, the first one is active", () => {
  assert.equal(activeId([{id: "a", top: 200}, {id: "b", top: 900}]), "a")
})

test("a page with no sections has no active one", () => {
  assert.equal(activeId([]), undefined)
})
