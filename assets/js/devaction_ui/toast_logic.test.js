import assert from "node:assert/strict"
import test from "node:test"
import {
  CLOSE_DELAY_MS, durationFor, EXIT_MS, focusAfter, isForGroup, isHotkey, leftAfter, LINGER_MS, listHeight, plan, roleFor,
  stackPlan, swipeOutcome, timerStep, variantOf,
} from "./toast_logic.js"

test("an error is an alert, the rest are status", () => {
  assert.equal(roleFor("risk"), "alert")
  ;["default", "ok", "warn", "info", "ai", "loading"].forEach((variant) => assert.equal(roleFor(variant), "status"))
})

test("an unknown variant is the default one", () => {
  assert.equal(variantOf("ok"), "ok")
  assert.equal(variantOf("nope"), "default")
  assert.equal(variantOf(undefined), "default")
})

test("loading never leaves by itself; the others take their duration or the group's", () => {
  assert.equal(durationFor({variant: "loading", duration: 10, fallback: 4000}), Infinity)
  assert.equal(durationFor({variant: "ok", duration: 1500, fallback: 4000}), 1500)
  assert.equal(durationFor({variant: "ok", duration: undefined, fallback: 4000}), 4000)
  assert.equal(durationFor({variant: "ok", duration: 0, fallback: 4000}), Infinity)
  assert.equal(durationFor({variant: "ok", duration: undefined, fallback: 0}), Infinity)
})

test("the pile of 52px toasts: 12px peek closed, 12px gap open", () => {
  const pile = stackPlan([52, 52, 52, 52, 52], {visible: 3})
  assert.equal(pile.front, 52)
  assert.equal(listHeight(pile, false), 52 + 2 * 12)
  assert.equal(listHeight(pile, true), 5 * 52 + 4 * 12)
  assert.deepEqual(pile.items.map((item) => item.offset), [0, 64, 128, 192, 256])
  assert.deepEqual(pile.items.map((item) => item.overflow), [false, false, false, true, true])
  assert.deepEqual(pile.items.map((item) => item.front), [true, false, false, false, false])
})

test("toasts of different heights stack by their own height", () => {
  const pile = stackPlan([80, 52], {visible: 3})
  assert.deepEqual(pile.items.map((item) => item.offset), [0, 92])
  assert.equal(listHeight(pile, false), 92)
  assert.equal(listHeight(pile, true), 80 + 12 + 52)
})

test("an empty pile has no height, and a single toast is its own height", () => {
  assert.equal(listHeight(stackPlan([], {visible: 3}), true), 0)
  assert.equal(listHeight(stackPlan([], {visible: 3}), false), 0)
  assert.equal(listHeight(stackPlan([60], {visible: 3}), false), 60)
  assert.equal(listHeight(stackPlan([60], {visible: 3}), true), 60)
})

test("timers pause when the pile is open or the tab hidden, start when it is not, and infinite ones stay out of it", () => {
  assert.equal(timerStep({paused: true, running: true, finite: true}), "pause")
  assert.equal(timerStep({paused: true, running: false, finite: true}), "keep")
  assert.equal(timerStep({paused: false, running: false, finite: true}), "start")
  assert.equal(timerStep({paused: false, running: true, finite: true}), "keep")
  assert.equal(timerStep({paused: false, running: false, finite: false}), "keep")
})

test("a drag past 80px dismisses, a shorter one comes back", () => {
  assert.equal(swipeOutcome(81), "dismiss")
  assert.equal(swipeOutcome(80), "restore")
  assert.equal(swipeOutcome(0), "restore")
})

test("Alt+T is the hotkey, with or without the letter the layout gives it", () => {
  assert.equal(isHotkey({altKey: true, key: "t", code: "KeyT"}), true)
  assert.equal(isHotkey({altKey: true, key: "†", code: "KeyT"}), true)
  assert.equal(isHotkey({altKey: true, key: "T", code: ""}), true)
  assert.equal(isHotkey({altKey: false, key: "t", code: "KeyT"}), false)
  assert.equal(isHotkey({altKey: true, ctrlKey: true, key: "t", code: "KeyT"}), false)
  assert.equal(isHotkey({altKey: true, key: "x", code: "KeyX"}), false)
})

test("when the focused toast leaves, the one that takes its place gets the focus", () => {
  assert.equal(focusAfter(0, 0), null)
  assert.equal(focusAfter(3, 1), 1)
  assert.equal(focusAfter(3, 3), 2)
})

test("an event with a group is only for that group", () => {
  assert.equal(isForGroup({title: "x"}, "toasts"), true)
  assert.equal(isForGroup({group: "toasts"}, "toasts"), true)
  assert.equal(isForGroup({group: "other"}, "toasts"), false)
})

test("the open list waits a moment before closing", () => {
  assert.ok(CLOSE_DELAY_MS > 0 && CLOSE_DELAY_MS < 500)
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
