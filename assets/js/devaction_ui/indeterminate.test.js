import test from "node:test"
import assert from "node:assert/strict"
import Indeterminate from "./indeterminate.js"

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
