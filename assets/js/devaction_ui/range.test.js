import test from "node:test"
import assert from "node:assert/strict"
import Range from "./range.js"

function build({template, bubble = true} = {}) {
  const props = {}
  const bubbleProps = {}
  const bubbleNode = {
    textContent: "",
    props: bubbleProps,
    style: {setProperty: (name, value) => (bubbleProps[name] = value)},
  }
  const output = {textContent: ""}
  const root = {
    querySelector: (selector) => ({'output[for="s"]': output, "[data-bubble]": bubble ? bubbleNode : null}[selector]),
  }
  const el = {
    id: "s",
    value: "50",
    min: "0",
    max: "200",
    dataset: template ? {formatText: template} : {},
    listeners: {},
    style: {setProperty: (name, value) => (props[name] = value)},
    closest: () => root,
    addEventListener(type, handler) {
      this.listeners[type] = handler
    },
    removeEventListener(type) {
      delete this.listeners[type]
    },
  }
  const hook = {...Range, el}
  hook.mounted()
  return {hook, el, props, output, bubbleNode}
}

test("dragging paints the filled part", () => {
  const {el, props} = build()
  el.value = "100"
  el.listeners.input()
  assert.equal(props["--p"], "50%")
})

test("with a template the value beside the label follows the thumb", () => {
  const {el, output} = build({template: "%{value} h"})
  el.value = "40"
  el.listeners.input()
  assert.equal(output.textContent, "40 h")
})

test("without a template the label's value is left to the server", () => {
  const {el, output} = build()
  el.value = "40"
  el.listeners.input()
  assert.equal(output.textContent, "")
})

test("the bubble follows the thumb with the formatted value", () => {
  const {el, bubbleNode} = build({template: "%{value} h"})
  el.value = "50"
  el.listeners.input()
  assert.equal(bubbleNode.props["--f"], "0.25")
  assert.equal(bubbleNode.textContent, "50 h")
})

test("a bubble with no template shows the number", () => {
  const {el, bubbleNode} = build()
  el.value = "200"
  el.listeners.input()
  assert.equal(bubbleNode.props["--f"], "1")
  assert.equal(bubbleNode.textContent, "200")
})

test("a slider without a bubble just paints", () => {
  const {el, props} = build({bubble: false})
  el.value = "20"
  el.listeners.input()
  assert.equal(props["--p"], "10%")
})

test("destroying the hook takes the listener off", () => {
  const {hook, el} = build()
  hook.destroyed()
  assert.equal(el.listeners.input, undefined)
})
