import test from "node:test"
import assert from "node:assert/strict"
import {LINGER_MS, leftAfter, plan} from "./progress_toast_logic.js"

test("a finished job leaves after the linger time", () => {
  assert.deepEqual(plan({state: "done"}), {wait: LINGER_MS})
})

test("a running job and a failed one stay", () => {
  assert.deepEqual(plan({state: "running"}), {wait: null})
  assert.deepEqual(plan({state: "error"}), {wait: null})
})

test("while the pointer or the focus is on it, it waits", () => {
  assert.deepEqual(plan({state: "done", paused: true}), {wait: null})
})

test("what is left of the wait is kept across a pause", () => {
  assert.equal(leftAfter(1600, 1000, 1400), 1200)
  assert.equal(leftAfter(1200, 5000, 9000), 0)
  assert.deepEqual(plan({state: "done", remaining: 300}), {wait: 300})
})
