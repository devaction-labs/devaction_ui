import test from "node:test"
import assert from "node:assert/strict"
import {move, tabStop} from "./segmented_logic.js"

const item = (pressed = false, disabled = false) => ({pressed, disabled})

test("the pressed segment is the tab stop", () => {
  assert.equal(tabStop([item(), item(true), item()]), 1)
})

test("with none pressed the first enabled one is the tab stop", () => {
  assert.equal(tabStop([item(false, true), item(), item()]), 1)
})

test("a pressed segment that is disabled does not hold the tab stop", () => {
  assert.equal(tabStop([item(), item(true, true)]), 0)
})

test("with every segment disabled there is no tab stop", () => {
  assert.equal(tabStop([item(false, true), item(false, true)]), -1)
  assert.equal(tabStop([]), -1)
})

test("right and down step forward and wrap", () => {
  const items = [item(), item(), item()]
  assert.equal(move(items, 0, "ArrowRight"), 1)
  assert.equal(move(items, 1, "ArrowDown"), 2)
  assert.equal(move(items, 2, "ArrowRight"), 0)
})

test("left and up step back and wrap", () => {
  const items = [item(), item(), item()]
  assert.equal(move(items, 2, "ArrowLeft"), 1)
  assert.equal(move(items, 1, "ArrowUp"), 0)
  assert.equal(move(items, 0, "ArrowLeft"), 2)
})

test("home and end go to the first and the last enabled segment", () => {
  const items = [item(false, true), item(), item(), item(false, true)]
  assert.equal(move(items, 2, "Home"), 1)
  assert.equal(move(items, 1, "End"), 2)
})

test("a disabled segment is skipped", () => {
  const items = [item(), item(false, true), item()]
  assert.equal(move(items, 0, "ArrowRight"), 2)
  assert.equal(move(items, 2, "ArrowLeft"), 0)
})

test("a key the control does not use gives nothing", () => {
  assert.equal(move([item(), item()], 0, "a"), undefined)
  assert.equal(move([item(), item()], 0, "Enter"), undefined)
})

test("nothing to go to when every segment is disabled", () => {
  assert.equal(move([item(false, true)], 0, "ArrowRight"), undefined)
  assert.equal(move([item(false, true)], 0, "Home"), undefined)
})
