import test from "node:test"
import assert from "node:assert/strict"
import Switch from "./switch.js"

function build(attributes) {
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
  const {el, field} = build({"aria-checked": "false"})
  el.listeners.click()
  assert.equal(el.attributes["aria-checked"], "true")
  assert.equal(field.value, "true")
  assert.equal(field.events.length, 1)
  assert.equal(field.events[0].type, "input")
  assert.equal(field.events[0].bubbles, true)
})

test("a second click flips back", () => {
  const {el, field} = build({"aria-checked": "true"})
  el.listeners.click()
  assert.equal(el.attributes["aria-checked"], "false")
  assert.equal(field.value, "false")
})

test("a disabled or busy switch does not change nor fire", () => {
  const {el, field} = build({"aria-checked": "true", "aria-disabled": "true"})
  el.listeners.click()
  assert.equal(el.attributes["aria-checked"], "true")
  assert.equal(field.value, "true")
  assert.equal(field.events.length, 0)
})

test("destroying the hook takes the listener off", () => {
  const {hook, el} = build({"aria-checked": "false"})
  hook.destroyed()
  assert.equal(el.listeners.click, undefined)
})
