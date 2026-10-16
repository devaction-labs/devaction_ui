import test from "node:test"
import assert from "node:assert/strict"
import {afterTimer, dismissesOnTap, isShown, settle, tapOpens, withDescription} from "./tooltip_logic.js"

test("a control with no description gets the tooltip's id", () => {
  assert.equal(withDescription(null, "t-tip"), "t-tip")
  assert.equal(withDescription("", "t-tip"), "t-tip")
})

test("the descriptions it already had are kept", () => {
  assert.equal(withDescription("hint", "t-tip"), "hint t-tip")
  assert.equal(withDescription("  a   b ", "t-tip"), "a b t-tip")
})

test("the id is never added twice", () => {
  assert.equal(withDescription("t-tip", "t-tip"), "t-tip")
  assert.equal(withDescription("a t-tip", "t-tip"), "a t-tip")
})

test("a touch dismisses the hint, a mouse or a pen does not", () => {
  assert.equal(dismissesOnTap("touch"), true)
  assert.equal(dismissesOnTap("mouse"), false)
  assert.equal(dismissesOnTap("pen"), false)
  assert.equal(dismissesOnTap(undefined), false)
})

const held = (phase, pointer, focus, dismissed = false) => settle({phase, pointer, focus, dismissed})

test("the pointer on the trigger starts the delay to open, once", () => {
  assert.deepEqual(held("closed", true, false), {phase: "opening", schedule: "open"})
  assert.deepEqual(held("opening", true, false), {phase: "opening", schedule: "none"})
})

test("the keyboard focus opens the card at once", () => {
  assert.deepEqual(held("closed", false, true), {phase: "open", schedule: "now"})
  assert.deepEqual(held("opening", true, true), {phase: "open", schedule: "now"})
  assert.deepEqual(held("open", false, true), {phase: "open", schedule: "cancel"})
})

test("the pointer leaving starts the delay to close, which the pointer coming back cancels", () => {
  assert.deepEqual(held("open", false, false), {phase: "closing", schedule: "close"})
  assert.deepEqual(held("closing", false, false), {phase: "closing", schedule: "none"})
  assert.deepEqual(held("closing", true, false), {phase: "open", schedule: "cancel"})
})

test("the card stays open while the focus holds it even when the pointer leaves", () => {
  assert.deepEqual(held("open", false, true), {phase: "open", schedule: "cancel"})
})

test("leaving before the delay to open ends never opens it", () => {
  assert.deepEqual(held("opening", false, false), {phase: "closed", schedule: "cancel"})
})

test("Esc closes it whatever holds it", () => {
  assert.deepEqual(held("open", true, true, true), {phase: "closed", schedule: "cancel"})
})

test("a timer that runs out opens an opening card and closes a closing one, and nothing else", () => {
  assert.equal(afterTimer("opening", "open"), "open")
  assert.equal(afterTimer("closing", "close"), "closed")
  assert.equal(afterTimer("open", "close"), "open")
  assert.equal(afterTimer("closed", "open"), "closed")
})

test("the card is shown while open or closing", () => {
  assert.deepEqual(["closed", "opening", "open", "closing"].map(isShown), [false, false, true, true])
})

test("a tap by a finger opens a closed card; a mouse click and a tap on an open card pass through", () => {
  assert.equal(tapOpens("touch", "closed"), true)
  assert.equal(tapOpens("touch", "open"), false)
  assert.equal(tapOpens("mouse", "closed"), false)
})
