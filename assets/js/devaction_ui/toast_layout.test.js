import test from "node:test"
import assert from "node:assert/strict"
import {escapeStep, layerStyle, planLayout, stackPadding, styleFor} from "./toast_layout.js"

test("one toast is never a stack, and opening it changes nothing", () => {
  assert.deepEqual(planLayout({count: 1, expanded: true}), {expanded: false, stacked: false, showBar: false, showExpand: false})
  assert.deepEqual(planLayout({count: 0, expanded: false}), {expanded: false, stacked: false, showBar: false, showExpand: false})
})

test("several toasts are a stack until opened", () => {
  assert.deepEqual(planLayout({count: 3, expanded: false}), {expanded: false, stacked: true, showBar: false, showExpand: true})
  assert.deepEqual(planLayout({count: 3, expanded: true}), {expanded: true, stacked: false, showBar: true, showExpand: false})
})

test("each layer sits lower, smaller and fainter, and the fourth is invisible", () => {
  const [one, two, four] = [layerStyle(1), layerStyle(2), layerStyle(4)]
  assert.equal(one.transform, "translateY(8px) scale(0.95)")
  assert.equal(two.transform, "translateY(16px) scale(0.9)")
  assert.ok(Number(one.zIndex) > Number(two.zIndex))
  assert.ok(Number(one.opacity) > Number(two.opacity))
  assert.equal(four.opacity, "0")
  assert.equal(one.pointerEvents, "none")
})

test("a stack leaves room for at most two layers", () => {
  assert.equal(stackPadding(2), "8px")
  assert.equal(stackPadding(3), "16px")
  assert.equal(stackPadding(9), "16px")
})

test("the style follows the toast's place: a layer, the lead of a stack, or a normal one", () => {
  assert.equal(styleFor({index: 2, stacked: true}).position, "absolute")
  assert.equal(styleFor({index: 0, stacked: true}).zIndex, "20")
  assert.equal(styleFor({index: 0, stacked: false}).position, "")
  assert.equal(styleFor({index: 3, stacked: false}).position, "")
})

test("Escape closes an open list first, then the focused toast, else it is left alone", () => {
  assert.equal(escapeStep({expanded: true, focused: true}), "collapse")
  assert.equal(escapeStep({expanded: false, focused: true}), "dismiss")
  assert.equal(escapeStep({expanded: false, focused: false}), null)
})
