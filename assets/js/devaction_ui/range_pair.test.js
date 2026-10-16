import test from "node:test"
import assert from "node:assert/strict"
import RangePair from "./range_pair.js"

function bubble() {
  const props = {}
  return {textContent: "", props, style: {setProperty: (name, value) => (props[name] = value)}}
}

function build({orientation = "horizontal", template, bubbles = false} = {}) {
  const low = {value: "20", min: "0", max: "100"}
  const high = {value: "70", min: "0", max: "100"}
  const fill = {style: {}}
  const output = {textContent: ""}
  const low_bubble = bubbles ? bubble() : null
  const high_bubble = bubbles ? bubble() : null
  globalThis.document = {getElementById: (id) => (id === "p-output" ? output : null)}
  const el = {
    id: "p",
    dataset: template ? {orientation, formatText: template} : {orientation},
    listeners: {},
    querySelector: (selector) =>
      ({
        "[data-low]": low,
        "[data-high]": high,
        "[data-fill]": fill,
        "[data-bubble-low]": low_bubble,
        "[data-bubble-high]": high_bubble,
      })[selector],
    addEventListener(type, handler) {
      this.listeners[type] = handler
    },
    removeEventListener(type) {
      delete this.listeners[type]
    },
  }
  const hook = {...RangePair, el}
  hook.mounted()
  return {hook, el, low, high, fill, output, low_bubble, high_bubble}
}

test("the low thumb stops at the high one", () => {
  const {el, low, high} = build()
  low.value = "90"
  el.listeners.input({target: low})
  assert.equal(low.value, 70)
  assert.equal(high.value, 70)
})

test("the high thumb stops at the low one", () => {
  const {el, low, high} = build()
  high.value = "5"
  el.listeners.input({target: high})
  assert.equal(low.value, 20)
  assert.equal(high.value, 20)
})

test("a horizontal fill is a left and a width", () => {
  const {el, low, fill} = build()
  low.value = "30"
  el.listeners.input({target: low})
  assert.deepEqual(fill.style, {left: "30%", width: "40%"})
})

test("a vertical fill is a bottom and a height", () => {
  const {el, low, fill} = build({orientation: "vertical"})
  low.value = "30"
  el.listeners.input({target: low})
  assert.deepEqual(fill.style, {bottom: "30%", height: "40%"})
})

test("with a template the value of the group follows both thumbs", () => {
  const {el, low, output} = build({template: "R$ %{value}k"})
  low.value = "10"
  el.listeners.input({target: low})
  assert.equal(output.textContent, "R$ 10k – R$ 70k")
})

test("each bubble follows its own thumb with the formatted value", () => {
  const {el, low, low_bubble, high_bubble} = build({template: "%{value} h", bubbles: true})
  low.value = "40"
  el.listeners.input({target: low})
  assert.equal(low_bubble.props["--f"], "0.4")
  assert.equal(low_bubble.textContent, "40 h")
  assert.equal(high_bubble.props["--f"], "0.7")
  assert.equal(high_bubble.textContent, "70 h")
})

test("a pair without bubbles still works", () => {
  const {el, low, fill} = build()
  low.value = "10"
  el.listeners.input({target: low})
  assert.equal(fill.style.left, "10%")
})

test("destroying the hook takes the listener off", () => {
  const {hook, el} = build()
  hook.destroyed()
  assert.equal(el.listeners.input, undefined)
})
