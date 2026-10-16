import test from "node:test"
import assert from "node:assert/strict"
import DataTable from "./data_table.js"

const row = (value, checked = false) => {
  const tr = {attrs: {}, setAttribute(name, content) { this.attrs[name] = content }}
  return {value, checked, closest: () => tr, tr}
}

const build = ({rows = 3, density = "comfortable", selected = [], withBulk = true, withToggle = true} = {}) => {
  const boxes = Array.from({length: rows}, (_x, index) => row(String(index + 1), selected.includes(String(index + 1))))
  const all = {checked: false, indeterminate: false, dataset: {}}
  const bar = {hidden: true, count: {textContent: ""}, querySelector: () => bar.count}
  const toggle = {attrs: {}, setAttribute(name, content) { this.attrs[name] = content }}
  const listeners = {}
  const dispatched = []

  const parts = {
    "[data-select-all]": all,
    "[data-bulk]": withBulk ? bar : null,
    "[data-density-toggle]": withToggle ? toggle : null,
  }
  const hook = {
    ...DataTable,
    el: {
      dataset: {selectedLabel: "__COUNT__ selected", density},
      addEventListener: (type, fn) => (listeners[type] = fn),
      querySelector: (selector) => parts[selector] ?? null,
      querySelectorAll: (selector) => (selector === "[data-select-row]" ? boxes : []),
      dispatchEvent: (event) => dispatched.push(event),
    },
  }
  hook.mounted()
  return {hook, boxes, all, bar, toggle, listeners, dispatched}
}

const matching = (selector, extra = {}) => ({target: {matches: (candidate) => candidate === selector, closest: () => null, ...extra}})
const clicking = (selector) => ({target: {closest: (candidate) => (candidate === selector ? {} : null)}})

test("on mount a table with ticked rows shows the mixed header and the bar with the count", () => {
  const {all, bar, boxes} = build({selected: ["1"]})

  assert.equal(all.indeterminate, true)
  assert.equal(all.checked, false)
  assert.equal(all.dataset.partial, "true")
  assert.equal(bar.hidden, false)
  assert.equal(bar.count.textContent, "1 selected")
  assert.equal(boxes[0].tr.attrs["aria-selected"], "true")
  assert.equal(boxes[1].tr.attrs["aria-selected"], "false")
})

test("no ticks: the bar is hidden and the header is clear", () => {
  const {all, bar} = build()

  assert.equal(bar.hidden, true)
  assert.equal(all.indeterminate, false)
  assert.equal(all.dataset.partial, "false")
})

test("the header box ticks every row, says all, and fires input on the table", () => {
  const {listeners, boxes, all, dispatched, bar} = build()

  listeners.change(matching("[data-select-all]", {checked: true}))

  assert.ok(boxes.every((box) => box.checked))
  assert.equal(all.checked, true)
  assert.equal(all.indeterminate, false)
  assert.equal(bar.count.textContent, "3 selected")
  assert.equal(dispatched.length, 1)
  assert.equal(dispatched[0].type, "input")
  assert.equal(dispatched[0].bubbles, true)
})

test("a row box updates the header and fires input", () => {
  const {listeners, boxes, all, dispatched} = build()
  boxes[1].checked = true

  listeners.change(matching("[data-select-row]"))

  assert.equal(all.indeterminate, true)
  assert.equal(dispatched.length, 1)
})

test("a change of something else is ignored", () => {
  const {listeners, dispatched} = build()
  listeners.change(matching("input.search"))
  assert.equal(dispatched.length, 0)
})

test("clear unticks everything and hides the bar", () => {
  const {listeners, boxes, bar, dispatched} = build({selected: ["1", "2"]})

  listeners.click(clicking("[data-clear]"))

  assert.ok(boxes.every((box) => !box.checked))
  assert.equal(bar.hidden, true)
  assert.equal(dispatched.length, 1)
})

test("a redraw puts the ticks back by value", () => {
  const {hook, boxes} = build({selected: ["2"]})

  hook.beforeUpdate()
  boxes.forEach((box) => (box.checked = false))
  hook.updated()

  assert.deepEqual(boxes.map((box) => box.checked), [false, true, false])
})

test("the density toggle switches between the densities and says which is on", () => {
  const {listeners, hook, toggle} = build()

  listeners.click(clicking("[data-density-toggle]"))
  assert.equal(hook.el.dataset.density, "compact")
  assert.equal(toggle.attrs["aria-pressed"], "true")

  listeners.click(clicking("[data-density-toggle]"))
  assert.equal(hook.el.dataset.density, "comfortable")
  assert.equal(toggle.attrs["aria-pressed"], "false")
})

test("the density the person chose survives a redraw that resets the attribute", () => {
  const {listeners, hook} = build()
  listeners.click(clicking("[data-density-toggle]"))

  hook.el.dataset.density = "comfortable"
  hook.beforeUpdate()
  hook.updated()

  assert.equal(hook.el.dataset.density, "compact")
})

test("a density the server sets is left alone while the person has not toggled", () => {
  const {hook} = build({density: "compact"})

  hook.beforeUpdate()
  hook.el.dataset.density = "comfortable"
  hook.updated()

  assert.equal(hook.el.dataset.density, "comfortable")
})

test("a table without a bulk bar or a toggle still works", () => {
  const {listeners, boxes, dispatched} = build({withBulk: false, withToggle: false})

  boxes[0].checked = true
  listeners.change(matching("[data-select-row]"))
  listeners.click(clicking("[data-density-toggle]"))

  assert.equal(dispatched.length, 1)
})
