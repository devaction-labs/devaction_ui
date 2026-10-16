import test from "node:test"
import assert from "node:assert/strict"
import Segmented from "./segmented.js"

function build(states) {
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
  const {buttons} = build([[false], [true], [false]])
  assert.deepEqual(buttons.map((button) => button.tabIndex), [-1, 0, -1])
})

test("with none pressed the first enabled one is", () => {
  const {buttons} = build([[false, true], [false], [false]])
  assert.deepEqual(buttons.map((button) => button.tabIndex), [-1, 0, -1])
})

test("an arrow moves the focus and the tab stop, and is consumed", () => {
  const {buttons, log, press} = build([[true], [false], [false]])
  const event = press(0, "ArrowRight")
  assert.deepEqual(log, ["focus 1"])
  assert.deepEqual(buttons.map((button) => button.tabIndex), [-1, 0, -1])
  assert.equal(event.prevented, true)
})

test("the arrows wrap, Home and End jump, a disabled segment is skipped", () => {
  const {log, press} = build([[true], [false, true], [false]])
  press(0, "ArrowRight")
  press(2, "ArrowRight")
  press(2, "Home")
  press(0, "End")
  assert.deepEqual(log, ["focus 2", "focus 0", "focus 0", "focus 2"])
})

test("moving the focus does not press: aria-pressed is never touched", () => {
  const {buttons, press} = build([[true], [false]])
  press(0, "ArrowRight")
  assert.equal(buttons[1].getAttribute(), "false")
})

test("other keys are left to the browser", () => {
  const {log, press} = build([[true], [false]])
  const event = press(0, "Enter")
  assert.deepEqual(log, [])
  assert.equal(event.prevented, false)
})

test("an update puts the tab stop back on the pressed segment", () => {
  const {hook, buttons, press} = build([[true], [false]])
  press(0, "ArrowRight")
  hook.updated()
  assert.deepEqual(buttons.map((button) => button.tabIndex), [0, -1])
})

test("destroying the hook takes the key listener off", () => {
  const {hook} = build([[true]])
  hook.destroyed()
  assert.equal(hook.el.listeners.keydown, undefined)
})
