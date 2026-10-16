import test from "node:test"
import assert from "node:assert/strict"
import {
  stepZoom,
  clampZoom,
  clampPage,
  pageSize,
  fieldBox,
  renderScale,
  thumbScrollTarget,
  keyAction,
  handleKey,
} from "./pdf_viewer_logic.js"

test("zoom steps in and out and stops at the ends", () => {
  assert.equal(stepZoom(100, 1), 125)
  assert.equal(stepZoom(100, -1), 75)
  assert.equal(stepZoom(300, 1), 300)
  assert.equal(stepZoom(50, -1), 50)
})

test("a zoom between two steps goes to the next one in the direction", () => {
  assert.equal(stepZoom(110, 1), 125)
  assert.equal(stepZoom(110, -1), 100)
})

test("zoom and page are held to their range", () => {
  assert.equal(clampZoom(10), 50)
  assert.equal(clampZoom(900), 300)
  assert.equal(clampPage(0, 4), 1)
  assert.equal(clampPage(9, 4), 4)
  assert.equal(clampPage(3, 0), 1)
})

test("a page is sized by the zoom", () => {
  assert.deepEqual(pageSize({width: 420, height: 560}, 125), {width: 525, height: 700})
})

test("a field in percent becomes a box in px", () => {
  assert.deepEqual(fieldBox({x: 8, y: 80, w: 40, h: 10}, {width: 420, height: 560}), {
    left: 34,
    top: 448,
    width: 168,
    height: 56,
  })
})

test("the render scale follows the page width and the zoom", () => {
  assert.equal(renderScale({pageWidth: 420, naturalWidth: 595, zoom: 100}), 420 / 595)
  assert.equal(renderScale({pageWidth: 400, naturalWidth: 200, zoom: 50}), 1)
})

test("the thumbnail scroll target is null in view, and brings the thumbnail in from either side", () => {
  const view = {height: 100, viewHeight: 300, margin: 8}
  assert.equal(thumbScrollTarget({...view, top: 50, scrollTop: 0}), null)
  assert.equal(thumbScrollTarget({...view, top: 400, scrollTop: 0}), 208)
  assert.equal(thumbScrollTarget({...view, top: 100, scrollTop: 300}), 92)
  assert.equal(thumbScrollTarget({...view, top: 2, scrollTop: 300}), 0)
})

const state = {page: 2, total: 4, zoom: 100}

test("keys zoom, turn pages and jump to the ends", () => {
  assert.deepEqual(keyAction("+", state), {type: "zoom", value: 125})
  assert.deepEqual(keyAction("-", state), {type: "zoom", value: 75})
  assert.deepEqual(keyAction("0", {...state, zoom: 150}), {type: "zoom", value: 100})
  assert.deepEqual(keyAction("PageDown", state), {type: "page", value: 3})
  assert.deepEqual(keyAction("PageUp", state), {type: "page", value: 1})
  assert.deepEqual(keyAction("Home", state), {type: "page", value: 1})
  assert.deepEqual(keyAction("End", state), {type: "page", value: 4})
})

test("a key that changes nothing or is not ours gives null", () => {
  assert.equal(keyAction("0", state), null)
  assert.equal(keyAction("End", {...state, page: 4}), null)
  assert.equal(keyAction("x", state), null)
})

test("the arrows are the rail's own", () => {
  assert.equal(keyAction("ArrowDown", state), null)
  assert.deepEqual(keyAction("ArrowDown", state, {rail: true}), {type: "page", value: 3})
  assert.deepEqual(keyAction("ArrowUp", state, {rail: true}), {type: "page", value: 1})
})

const press = (key, extra = {}) => {
  const event = {key, altKey: false, metaKey: false, ctrlKey: false, prevented: false, ...extra}
  event.preventDefault = () => (event.prevented = true)
  return event
}

test("a key with an action is sent and consumed, one without is left alone", () => {
  const sent = []
  const send = (action) => sent.push(action)
  const consumed = press("PageDown")
  const ignored = press("End")

  handleKey(consumed, state, send)
  handleKey(ignored, {...state, page: 4}, send)
  handleKey(press("+", {ctrlKey: true}), state, send)

  assert.deepEqual(sent, [{type: "page", value: 3}])
  assert.equal(consumed.prevented, true)
  assert.equal(ignored.prevented, false)
})
