import assert from "node:assert/strict"
import test from "node:test"
import {countText, escapeStep, EXIT_MS, GLIDE_MS, glideSteps, HOVER_CLOSE_MS, hoverStep, leftAfter, LINGER_MS, plan, planLayout} from "./toast_logic.js"

test("one toast is never a stack, and opening it changes nothing", () => {
  assert.deepEqual(planLayout({count: 1, expanded: true}), {expanded: false, stacked: false, showBar: false, showExpand: false})
  assert.deepEqual(planLayout({count: 0, expanded: false}), {expanded: false, stacked: false, showBar: false, showExpand: false})
})

test("several toasts are a stack until opened", () => {
  assert.deepEqual(planLayout({count: 3, expanded: false}), {expanded: false, stacked: true, showBar: false, showExpand: true})
  assert.deepEqual(planLayout({count: 3, expanded: true}), {expanded: true, stacked: false, showBar: true, showExpand: false})
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

test("pointing at a collapsed stack opens it, and it closes again only if it opened by itself", () => {
  const stack = {stacked: true, expanded: false, auto: false}
  assert.equal(hoverStep({...stack, event: "enter"}), "open")
  assert.equal(hoverStep({...stack, event: "enter", stacked: false}), null)
  assert.equal(hoverStep({...stack, event: "enter", expanded: true}), null)
  assert.equal(hoverStep({...stack, event: "leave", expanded: true, auto: true}), "close")
  assert.equal(hoverStep({...stack, event: "leave", expanded: true, auto: false}), null)
  assert.equal(HOVER_CLOSE_MS, 250)
})

test("a toast glides from where it was drawn to where the layout puts it, and one that did not move stays put", () => {
  const before = new Map([["a", {x: 10, y: 100}], ["b", {x: 10, y: 90}], ["c", {x: 10, y: 80}]])
  const after = new Map([["a", {x: 10, y: 100}], ["b", {x: 10, y: 40}], ["d", {x: 10, y: 0}]])

  assert.deepEqual(glideSteps(before, after), [{id: "b", dx: 0, dy: 50}])
  assert.equal(GLIDE_MS, 320)
})
