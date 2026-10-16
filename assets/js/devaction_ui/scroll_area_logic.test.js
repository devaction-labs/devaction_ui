import assert from "node:assert/strict"
import test from "node:test"
import {ATTRIBUTES, edges} from "./scroll_area_logic.js"

const box = (extra) => ({scrollLeft: 0, scrollTop: 0, scrollWidth: 1000, clientWidth: 400, scrollHeight: 800, clientHeight: 300, ...extra})

test("at the start only the far edges have more", () => {
  assert.deepEqual(edges(box()), {left: false, right: true, top: false, bottom: true})
})

test("in the middle all four have more", () => {
  assert.deepEqual(edges(box({scrollLeft: 100, scrollTop: 100})), {left: true, right: true, top: true, bottom: true})
})

test("at the end only the near edges have more", () => {
  assert.deepEqual(edges(box({scrollLeft: 600, scrollTop: 500})), {left: true, right: false, top: true, bottom: false})
})

test("content that fits has no shadow", () => {
  assert.deepEqual(edges(box({scrollWidth: 400, scrollHeight: 300})), {left: false, right: false, top: false, bottom: false})
})

test("a sub-pixel gap is not a scroll", () => {
  assert.equal(edges(box({scrollLeft: 599.5})).right, false)
  assert.equal(edges(box({scrollLeft: 0.5})).left, false)
})

test("each edge has an attribute", () => {
  assert.deepEqual(Object.keys(ATTRIBUTES), ["left", "right", "top", "bottom"])
})
