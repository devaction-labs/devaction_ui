import test from "node:test"
import assert from "node:assert/strict"
import Signature from "./signature.js"

function build() {
  const svg = {
    listeners: {},
    captured: [],
    addEventListener(type, handler) {
      this.listeners[type] = handler
    },
    setPointerCapture(id) {
      this.captured.push(id)
    },
    getBoundingClientRect: () => ({left: 0, top: 0, width: 360, height: 170}),
  }
  const path = {attrs: {}, setAttribute(name, value) { this.attrs[name] = value }}
  const input = {value: "", events: [], dispatchEvent(event) { this.events.push(event.type) }}
  const status = {textContent: "", dataset: {empty: "Empty", ready: "Ready"}}
  const clear = {addEventListener(type, handler) { this.handler = handler }}
  const el = {
    querySelector: (selector) =>
      ({svg, path, 'input[type="hidden"]': input, "[data-status]": status, "[data-clear]": clear})[selector],
  }
  const hook = {...Signature, el}
  hook.mounted()
  const down = (x, y) => svg.listeners.pointerdown({clientX: x, clientY: y, pointerId: 1})
  const move = (x, y) => svg.listeners.pointermove({clientX: x, clientY: y})
  return {hook, el, svg, path, input, status, clear, down, move}
}

test("a stroke is written as a path into the hidden input and the form is told", () => {
  const {path, input, down, move} = build()
  down(10, 20)
  move(30, 40)
  assert.equal(path.attrs.d, "M10 20 L30 40")
  assert.equal(input.value, "M10 20 L30 40")
  assert.equal(input.events.length, 2)
})

test("the pointer is captured so a stroke can leave the pad", () => {
  const {svg, down} = build()
  down(1, 1)
  assert.deepEqual(svg.captured, [1])
})

test("a single touch is a dot", () => {
  const {input, down} = build()
  down(5, 6)
  assert.equal(input.value, "M5 6 L5 6")
})

test("moving without a press draws nothing, and letting go ends the stroke", () => {
  const {svg, input, down, move} = build()
  move(10, 10)
  assert.equal(input.value, "")
  down(0, 0)
  svg.listeners.pointerup()
  move(50, 50)
  assert.equal(input.value, "M0 0 L0 0")
})

test("the status says ready with a stroke and empty after clearing", () => {
  const {status, clear, down} = build()
  down(0, 0)
  assert.equal(status.textContent, "Ready")
  clear.handler()
  assert.equal(status.textContent, "Empty")
})

test("clearing empties the path and the field", () => {
  const {path, input, clear, down} = build()
  down(1, 2)
  clear.handler()
  assert.equal(path.attrs.d, "")
  assert.equal(input.value, "")
})

test("exportSvg gives the drawing in a colour, or nothing when it is blank", () => {
  const {el, clear, down} = build()
  assert.equal(el.exportSvg(), null)
  down(1, 2)
  assert.match(el.exportSvg("#FFFFFF"), /stroke="#FFFFFF"/)
  assert.match(el.exportSvg(), /stroke="#18181B"/)
  clear.handler()
  assert.equal(el.exportSvg(), null)
})
