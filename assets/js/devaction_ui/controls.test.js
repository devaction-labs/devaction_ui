import assert from "node:assert/strict"
import test from "node:test"
import {flip, Indeterminate, press, Range, RangePair, Segmented, Switch} from "./controls.js"

const hook = (dataset) => ({...Indeterminate, el: {dataset, indeterminate: false}})

test("a box marked partial becomes indeterminate on mount", () => {
  const box = hook({partial: "true"})
  box.mounted()
  assert.equal(box.el.indeterminate, true)
})

test("an update that drops the mark clears it", () => {
  const box = hook({partial: "true"})
  box.mounted()
  delete box.el.dataset.partial
  box.updated()
  assert.equal(box.el.indeterminate, false)
})

test("a box without the mark stays plain", () => {
  const box = hook({})
  box.mounted()
  assert.equal(box.el.indeterminate, false)
})

function buildSwitch(attributes) {
  const field = {
    value: attributes["aria-checked"],
    events: [],
    dispatchEvent(event) {
      this.events.push(event)
    },
  }
  const el = {
    id: "s",
    attributes: {...attributes},
    listeners: {},
    ownerDocument: {getElementById: (id) => (id === "s-field" ? field : null)},
    getAttribute(name) {
      return this.attributes[name] ?? null
    },
    setAttribute(name, value) {
      this.attributes[name] = value
    },
    addEventListener(type, handler) {
      this.listeners[type] = handler
    },
    removeEventListener(type) {
      delete this.listeners[type]
    },
  }
  const hook = {...Switch, el}
  hook.mounted()
  return {hook, el, field}
}

test("a click flips the button and the field and tells the form", () => {
  const {el, field} = buildSwitch({"aria-checked": "false"})
  el.listeners.click()
  assert.equal(el.attributes["aria-checked"], "true")
  assert.equal(field.value, "true")
  assert.equal(field.events.length, 1)
  assert.equal(field.events[0].type, "input")
  assert.equal(field.events[0].bubbles, true)
})

test("a second click flips back", () => {
  const {el, field} = buildSwitch({"aria-checked": "true"})
  el.listeners.click()
  assert.equal(el.attributes["aria-checked"], "false")
  assert.equal(field.value, "false")
})

test("a disabled or busy switch does not change nor fire", () => {
  const {el, field} = buildSwitch({"aria-checked": "true", "aria-disabled": "true"})
  el.listeners.click()
  assert.equal(el.attributes["aria-checked"], "true")
  assert.equal(field.value, "true")
  assert.equal(field.events.length, 0)
})

test("destroying the hook takes the listener off", () => {
  const {hook, el} = buildSwitch({"aria-checked": "false"})
  hook.destroyed()
  assert.equal(el.listeners.click, undefined)
})

function buildSegmented(states) {
  const log = []
  const buttons = states.map(([pressed, disabled], index) => ({
    index,
    disabled,
    tabIndex: 0,
    getAttribute: () => String(pressed),
    closest() {
      return this
    },
    focus: () => log.push(`focus ${index}`),
  }))
  const el = {
    listeners: {},
    querySelectorAll: () => buttons,
    addEventListener(type, handler) {
      this.listeners[type] = handler
    },
    removeEventListener(type) {
      delete this.listeners[type]
    },
  }
  const hook = {...Segmented, el}
  hook.mounted()
  const press = (from, key) => {
    const event = {key, target: buttons[from], prevented: false, preventDefault() { this.prevented = true }}
    el.listeners.keydown(event)
    return event
  }
  return {hook, buttons, log, press}
}

test("on mount only the pressed segment is in the Tab order", () => {
  const {buttons} = buildSegmented([[false], [true], [false]])
  assert.deepEqual(buttons.map((button) => button.tabIndex), [-1, 0, -1])
})

test("with none pressed the first enabled one is", () => {
  const {buttons} = buildSegmented([[false, true], [false], [false]])
  assert.deepEqual(buttons.map((button) => button.tabIndex), [-1, 0, -1])
})

test("an arrow moves the focus and the tab stop, and is consumed", () => {
  const {buttons, log, press} = buildSegmented([[true], [false], [false]])
  const event = press(0, "ArrowRight")
  assert.deepEqual(log, ["focus 1"])
  assert.deepEqual(buttons.map((button) => button.tabIndex), [-1, 0, -1])
  assert.equal(event.prevented, true)
})

test("the arrows wrap, Home and End jump, a disabled segment is skipped", () => {
  const {log, press} = buildSegmented([[true], [false, true], [false]])
  press(0, "ArrowRight")
  press(2, "ArrowRight")
  press(2, "Home")
  press(0, "End")
  assert.deepEqual(log, ["focus 2", "focus 0", "focus 0", "focus 2"])
})

test("moving the focus does not press: aria-pressed is never touched", () => {
  const {buttons, press} = buildSegmented([[true], [false]])
  press(0, "ArrowRight")
  assert.equal(buttons[1].getAttribute(), "false")
})

test("other keys are left to the browser", () => {
  const {log, press} = buildSegmented([[true], [false]])
  const event = press(0, "Enter")
  assert.deepEqual(log, [])
  assert.equal(event.prevented, false)
})

test("an update puts the tab stop back on the pressed segment", () => {
  const {hook, buttons, press} = buildSegmented([[true], [false]])
  press(0, "ArrowRight")
  hook.updated()
  assert.deepEqual(buttons.map((button) => button.tabIndex), [0, -1])
})

test("destroying the hook takes the key listener off", () => {
  const {hook} = buildSegmented([[true]])
  hook.destroyed()
  assert.equal(hook.el.listeners.keydown, undefined)
})

function buildRange({template, bubble = true} = {}) {
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
  const {el, props} = buildRange()
  el.value = "100"
  el.listeners.input()
  assert.equal(props["--p"], "50%")
})

test("with a template the value beside the label follows the thumb", () => {
  const {el, output} = buildRange({template: "%{value} h"})
  el.value = "40"
  el.listeners.input()
  assert.equal(output.textContent, "40 h")
})

test("without a template the label's value is left to the server", () => {
  const {el, output} = buildRange()
  el.value = "40"
  el.listeners.input()
  assert.equal(output.textContent, "")
})

test("the bubble follows the thumb with the formatted value", () => {
  const {el, bubbleNode} = buildRange({template: "%{value} h"})
  el.value = "50"
  el.listeners.input()
  assert.equal(bubbleNode.props["--f"], "0.25")
  assert.equal(bubbleNode.textContent, "50 h")
})

test("a bubble with no template shows the number", () => {
  const {el, bubbleNode} = buildRange()
  el.value = "200"
  el.listeners.input()
  assert.equal(bubbleNode.props["--f"], "1")
  assert.equal(bubbleNode.textContent, "200")
})

test("a slider without a bubble just paints", () => {
  const {el, props} = buildRange({bubble: false})
  el.value = "20"
  el.listeners.input()
  assert.equal(props["--p"], "10%")
})

test("destroying the hook takes the listener off", () => {
  const {hook, el} = buildRange()
  hook.destroyed()
  assert.equal(el.listeners.input, undefined)
})

function bubble() {
  const props = {}
  return {textContent: "", props, style: {setProperty: (name, value) => (props[name] = value)}}
}

function buildPair({orientation = "horizontal", template, bubbles = false} = {}) {
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
  const {el, low, high} = buildPair()
  low.value = "90"
  el.listeners.input({target: low})
  assert.equal(low.value, 70)
  assert.equal(high.value, 70)
})

test("the high thumb stops at the low one", () => {
  const {el, low, high} = buildPair()
  high.value = "5"
  el.listeners.input({target: high})
  assert.equal(low.value, 20)
  assert.equal(high.value, 20)
})

test("a horizontal fill is a left and a width", () => {
  const {el, low, fill} = buildPair()
  low.value = "30"
  el.listeners.input({target: low})
  assert.deepEqual(fill.style, {left: "30%", width: "40%"})
})

test("a vertical fill is a bottom and a height", () => {
  const {el, low, fill} = buildPair({orientation: "vertical"})
  low.value = "30"
  el.listeners.input({target: low})
  assert.deepEqual(fill.style, {bottom: "30%", height: "40%"})
})

test("with a template the value of the group follows both thumbs", () => {
  const {el, low, output} = buildPair({template: "R$ %{value}k"})
  low.value = "10"
  el.listeners.input({target: low})
  assert.equal(output.textContent, "R$ 10k – R$ 70k")
})

test("each bubble follows its own thumb with the formatted value", () => {
  const {el, low, low_bubble, high_bubble} = buildPair({template: "%{value} h", bubbles: true})
  low.value = "40"
  el.listeners.input({target: low})
  assert.equal(low_bubble.props["--f"], "0.4")
  assert.equal(low_bubble.textContent, "40 h")
  assert.equal(high_bubble.props["--f"], "0.7")
  assert.equal(high_bubble.textContent, "70 h")
})

test("a pair without bubbles still works", () => {
  const {el, low, fill} = buildPair()
  low.value = "10"
  el.listeners.input({target: low})
  assert.equal(fill.style.left, "10%")
})

test("destroying the hook takes the listener off", () => {
  const {hook, el} = buildPair()
  hook.destroyed()
  assert.equal(el.listeners.input, undefined)
})

test("flip turns on into off and anything else into on", () => {
  assert.equal(flip("true"), "false")
  assert.equal(flip("false"), "true")
  assert.equal(flip(null), "true")
})

test("a press flips an enabled switch", () => {
  assert.equal(press("false", null), "true")
  assert.equal(press("true", "false"), "false")
})

test("a press leaves a disabled or busy switch as it is", () => {
  assert.equal(press("true", "true"), "true")
  assert.equal(press("false", "true"), "false")
})
