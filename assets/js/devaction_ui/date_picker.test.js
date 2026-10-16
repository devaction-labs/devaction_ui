import test from "node:test"
import assert from "node:assert/strict"
import DatePicker from "./date_picker.js"

const build = (dataset = {}, {range = false} = {}) => {
  const dispatched = []
  const calendar = {innerHTML: ""}
  const from = {value: dataset.from ?? "", dispatchEvent: (event) => dispatched.push(event)}
  const to = {value: dataset.to ?? ""}
  const focused = []
  const listeners = {}
  const parts = {
    "[data-calendar]": calendar,
    "[data-from-input]": from,
    "[data-to-input]": range ? to : null,
  }
  const hook = {
    ...DatePicker,
    el: {
      dataset: {
        mode: range ? "range" : "single",
        today: "2026-10-14",
        locale: "en",
        weekStart: "0",
        previous: "Previous",
        next: "Next",
        inside: "in the range",
        ...dataset,
      },
      querySelector: (selector) => {
        const day = selector.match(/^\[data-day="(.+)"\]$/)
        return day ? {focus: () => focused.push(day[1])} : (parts[selector] ?? null)
      },
      addEventListener: (type, fn) => (listeners[type] = fn),
    },
  }
  hook.mounted()
  return {hook, calendar, from, to, dispatched, focused, listeners}
}

const click = (selector, dataset = {}) => ({
  target: {closest: (candidate) => (candidate === selector ? {dataset, disabled: false} : null)},
})

const key = (name) => ({
  key: name,
  altKey: false,
  metaKey: false,
  ctrlKey: false,
  target: {closest: (selector) => (selector === "[data-day]" ? {} : null)},
  prevented: false,
  preventDefault() {
    this.prevented = true
  },
})

test("it draws the month of the value, or of today, on mount", () => {
  const picked = build({from: "2026-11-03"})
  assert.match(picked.calendar.innerHTML, /November 2026/)

  const none = build()
  assert.match(none.calendar.innerHTML, /October 2026/)
  assert.equal((none.calendar.innerHTML.match(/data-day=/g) ?? []).length, 31)
})

test("the month title is capitalised unless capitalize is off", () => {
  assert.match(build({locale: "pt-BR"}).calendar.innerHTML, /Outubro de 2026/)
  assert.match(build({locale: "pt-BR", capitalize: "false"}).calendar.innerHTML, /outubro de 2026/)
})

test("picking a day writes the hidden input and fires input so phx-change hears it", () => {
  const {listeners, from, dispatched, calendar} = build()
  listeners.click(click("[data-day]", {day: "2026-10-20"}))

  assert.equal(from.value, "2026-10-20")
  assert.equal(dispatched.length, 1)
  assert.equal(dispatched[0].type, "input")
  assert.match(calendar.innerHTML, /data-day="2026-10-20"[^>]*aria-pressed="true"/)
})

test("a day before the minimum cannot be picked", () => {
  const {listeners, from, dispatched} = build({min: "2026-10-10"})
  listeners.click(click("[data-day]", {day: "2026-10-05"}))
  assert.equal(from.value, "")
  assert.equal(dispatched.length, 0)
})

test("a range takes the start, then the end", () => {
  const {listeners, from, to} = build({}, {range: true})
  listeners.click(click("[data-day]", {day: "2026-10-12"}))
  assert.deepEqual([from.value, to.value], ["2026-10-12", ""])
  listeners.click(click("[data-day]", {day: "2026-10-18"}))
  assert.deepEqual([from.value, to.value], ["2026-10-12", "2026-10-18"])
})

test("a shortcut picks its date and jumps to its month", () => {
  const {listeners, from, calendar} = build()
  listeners.click(click("[data-shortcut]", {shortcut: "2026-12-25"}))
  assert.equal(from.value, "2026-12-25")
  assert.match(calendar.innerHTML, /December 2026/)
})

test("the month buttons turn the month without touching the value", () => {
  const {listeners, from, calendar} = build()
  listeners.click(click("[data-nav]", {nav: "1"}))
  assert.match(calendar.innerHTML, /November 2026/)
  assert.equal(from.value, "")
})

test("the arrow keys move the focus a day or a week and draw it focused", () => {
  const {listeners, focused} = build()
  const right = key("ArrowRight")
  listeners.keydown(right)
  assert.equal(right.prevented, true)
  assert.deepEqual(focused, ["2026-10-15"])

  listeners.keydown(key("ArrowDown"))
  assert.deepEqual(focused, ["2026-10-15", "2026-10-22"])
})

test("page keys change the month and a key that is not ours is left alone", () => {
  const {listeners, calendar} = build()
  listeners.keydown(key("PageDown"))
  assert.match(calendar.innerHTML, /November 2026/)

  const letter = key("a")
  listeners.keydown(letter)
  assert.equal(letter.prevented, false)
})

test("the keyboard lands on the minimum when today is before it", () => {
  const {calendar} = build({min: "2026-10-20"})
  assert.match(calendar.innerHTML, /data-day="2026-10-20"[^>]*tabindex="0"/)
  assert.doesNotMatch(calendar.innerHTML, /data-day="2026-10-14"[^>]*tabindex="0"/)
})

test("a set event from outside replaces the selection and shows its month", () => {
  const {listeners, from, to, calendar, dispatched} = build({}, {range: true})
  listeners["devaction:date-picker-set"]({detail: {from: "2026-12-01", to: "2026-12-05"}})

  assert.deepEqual([from.value, to.value], ["2026-12-01", "2026-12-05"])
  assert.match(calendar.innerHTML, /December 2026/)
  assert.match(calendar.innerHTML, /data-day="2026-12-03"[^>]*aria-label="[^"]*in the range/)
  assert.equal(dispatched.length, 0)
})

test("a set event with no date clears the selection", () => {
  const {listeners, from} = build({from: "2026-10-16"})
  listeners["devaction:date-picker-set"]({detail: {from: null, to: null}})
  assert.equal(from.value, "")
})
