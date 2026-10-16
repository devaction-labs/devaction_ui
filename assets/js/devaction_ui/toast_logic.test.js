import assert from "node:assert/strict"
import test from "node:test"
import {countText, escapeStep, EXIT_MS, layerCount, leftAfter, LINGER_MS, plan, planLayout, stackPadding, styleFor} from "./toast_logic.js"

test("one toast is never a stack, and opening it changes nothing", () => {
  assert.deepEqual(planLayout({count: 1, expanded: true}), {expanded: false, stacked: false, showBar: false, showExpand: false})
  assert.deepEqual(planLayout({count: 0, expanded: false}), {expanded: false, stacked: false, showBar: false, showExpand: false})
})

test("several toasts are a stack until opened", () => {
  assert.deepEqual(planLayout({count: 3, expanded: false}), {expanded: false, stacked: true, showBar: false, showExpand: true})
  assert.deepEqual(planLayout({count: 3, expanded: true}), {expanded: true, stacked: false, showBar: true, showExpand: false})
})

test("behind the front toast of a stack nothing is drawn: the blocks of the group stand for it", () => {
  assert.equal(styleFor({index: 1, stacked: true}).display, "none")
  assert.equal(styleFor({index: 4, stacked: true}).display, "none")
})

test("a stack leaves room above for the layers that peek out over it, and a lone toast none", () => {
  assert.equal(stackPadding(2), "16px")
  assert.equal(stackPadding(9), "16px")
  assert.equal(stackPadding(1), "")
})

test("a stack shows one layer per toast behind the front one, at most two", () => {
  assert.deepEqual([0, 1, 2, 3, 9].map(layerCount), [0, 0, 1, 2, 2])
})

test("the style follows the toast's place: hidden, the lead of a stack, or a normal one", () => {
  assert.equal(styleFor({index: 0, stacked: true}).zIndex, "20")
  assert.equal(styleFor({index: 0, stacked: true}).display, "")
  assert.equal(styleFor({index: 0, stacked: false}).position, "")
  assert.equal(styleFor({index: 3, stacked: false}).display, "")
})

test("the bar reads the heading, then the count", () => {
  assert.equal(countText({heading: "AI review", label: "__COUNT__ notices", count: 3}), "AI review \u00b7 3 notices")
  assert.equal(countText({heading: null, label: "__COUNT__ notices", count: 3}), "3 notices")
})

test("Escape closes an open list first, then the focused toast, else it is left alone", () => {
  assert.equal(escapeStep({expanded: true, focused: true}), "collapse")
  assert.equal(escapeStep({expanded: false, focused: true}), "dismiss")
  assert.equal(escapeStep({expanded: false, focused: false}), null)
})

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

test("the exit lasts 400 ms, as long as the toast-out animation", () => {
  assert.equal(EXIT_MS, 400)
})
