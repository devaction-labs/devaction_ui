import test from "node:test"
import assert from "node:assert/strict"
import DateInput from "./date_input.js"

const field = (dataset = {}, value = "") => ({
  dataset,
  value,
  attrs: {},
  events: [],
  setAttribute(name, content) {
    this.attrs[name] = content
  },
  removeAttribute(name) {
    delete this.attrs[name]
  },
  dispatchEvent(event) {
    this.events.push(event)
    return true
  },
})

const build = ({mode = "single", min = "", order = "dmy", separator = "/", from = "", to = ""} = {}) => {
  const parts = {
    '[data-date-text="from"]': field({dateText: "from"}, from && "x"),
    '[data-date-value="from"]': field({}, from),
    '[data-date-picker]': field(),
    "[data-panel]": {hidden: false},
    "[data-trigger] button": {clicks: 0, click() { this.clicks += 1 }},
  }
  mode === "range" && Object.assign(parts, {
    '[data-date-text="to"]': field({dateText: "to"}),
    '[data-date-value="to"]': field({}, to),
  })
  const listeners = {}
  const hook = {
    ...DateInput,
    el: {
      dataset: {mode, min, order, separator},
      querySelector: (selector) => parts[selector] ?? null,
      addEventListener: (type, fn) => (listeners[type] = fn),
    },
  }
  hook.mounted()
  return {hook, parts, input: (event) => listeners.input(event)}
}

const typing = (target) => ({target, stopped: false, stopPropagation() { this.stopped = true }})

test("typing digits masks the text and a complete date goes into the hidden input as ISO", () => {
  const {parts, input} = build()
  const text = parts['[data-date-text="from"]']

  text.value = "1610"
  input(typing(text))
  assert.equal(text.value, "16/10")
  assert.equal(parts['[data-date-value="from"]'].value, "")
  assert.equal(parts['[data-date-value="from"]'].events.length, 0)

  text.value = "16102026"
  input(typing(text))
  assert.equal(text.value, "16/10/2026")
  assert.equal(parts['[data-date-value="from"]'].value, "2026-10-16")
  assert.equal(parts['[data-date-value="from"]'].events.length, 1)
  assert.equal(parts['[data-date-value="from"]'].events[0].bubbles, true)
})

test("the typed input never reaches the form on its own", () => {
  const {parts, input} = build()
  const text = parts['[data-date-text="from"]']
  const event = typing(text)
  text.value = "1"
  input(event)
  assert.equal(event.stopped, true)
})

test("a date that does not exist is flagged and sends nothing", () => {
  const {parts, input} = build()
  const text = parts['[data-date-text="from"]']

  text.value = "31022026"
  input(typing(text))
  assert.equal(text.attrs["aria-invalid"], "true")
  assert.equal(parts['[data-date-value="from"]'].value, "")

  text.value = "28022026"
  input(typing(text))
  assert.equal(text.attrs["aria-invalid"], undefined)
  assert.equal(parts['[data-date-value="from"]'].value, "2026-02-28")
})

test("a day before the minimum is flagged", () => {
  const {parts, input} = build({min: "2026-10-10"})
  const text = parts['[data-date-text="from"]']
  text.value = "09102026"
  input(typing(text))
  assert.equal(text.attrs["aria-invalid"], "true")
  assert.equal(parts['[data-date-value="from"]'].value, "")
})

test("the calendar is told what was typed", () => {
  const {parts, input} = build()
  const text = parts['[data-date-text="from"]']
  text.value = "16102026"
  input(typing(text))

  const [event] = parts["[data-date-picker]"].events
  assert.equal(event.type, "devaction:date-picker-set")
  assert.deepEqual(event.detail, {from: "2026-10-16", to: null})
})

test("a day picked in the calendar is written in the field and closes the popover", () => {
  const {parts, input} = build({order: "ymd", separator: "-"})
  const picker = field()
  const fromInput = {value: "2026-10-16"}
  picker.querySelector = (selector) => (selector === "[data-from-input]" ? fromInput : null)
  const target = {dataset: {}, matches: () => true, closest: () => picker}

  const event = typing(target)
  input(event)

  assert.equal(event.stopped, true)
  assert.equal(parts['[data-date-text="from"]'].value, "2026-10-16")
  assert.equal(parts['[data-date-value="from"]'].value, "2026-10-16")
  assert.equal(parts['[data-date-value="from"]'].events.length, 1)
  assert.equal(parts["[data-trigger] button"].clicks, 1)
})

test("in a range the popover stays open until both ends are picked", () => {
  const {parts, input} = build({mode: "range"})
  const picker = field()
  const values = {from: "2026-10-13", to: ""}
  picker.querySelector = (selector) => ({value: selector === "[data-from-input]" ? values.from : values.to})
  const target = {dataset: {}, matches: () => true, closest: () => picker}

  input(typing(target))
  assert.equal(parts['[data-date-text="from"]'].value, "13/10/2026")
  assert.equal(parts['[data-date-value="to"]'].value, "")
  assert.equal(parts["[data-trigger] button"].clicks, 0)

  values.to = "2026-10-20"
  input(typing(target))
  assert.equal(parts['[data-date-text="to"]'].value, "20/10/2026")
  assert.equal(parts['[data-date-value="to"]'].value, "2026-10-20")
  assert.equal(parts["[data-trigger] button"].clicks, 1)
})

test("the end of a range cannot be before its start", () => {
  const {parts, input} = build({mode: "range", from: "2026-10-13"})
  const text = parts['[data-date-text="to"]']
  text.value = "12102026"
  input(typing(text))
  assert.equal(text.attrs["aria-invalid"], "true")
  assert.equal(parts['[data-date-value="to"]'].value, "")

  text.value = "13102026"
  input(typing(text))
  assert.equal(parts['[data-date-value="to"]'].value, "2026-10-13")
})

test("a closed popover is not toggled by a pick", () => {
  const {parts, input} = build()
  parts["[data-panel]"].hidden = true
  const picker = field()
  picker.querySelector = (selector) => (selector === "[data-from-input]" ? {value: "2026-10-16"} : null)
  input(typing({dataset: {}, matches: () => true, closest: () => picker}))
  assert.equal(parts["[data-trigger] button"].clicks, 0)
})

test("an update from the server tells the calendar the values it has", () => {
  const {hook, parts} = build({from: "2026-10-13"})
  hook.updated()
  const [event] = parts["[data-date-picker]"].events
  assert.deepEqual(event.detail, {from: "2026-10-13", to: null})
})
