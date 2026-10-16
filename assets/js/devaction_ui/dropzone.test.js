import test from "node:test"
import assert from "node:assert/strict"
import Dropzone from "./dropzone.js"

function build({status = true, label = "Drop to upload"} = {}) {
  const area = {
    attrs: new Set(),
    toggleAttribute(name, force) {
      force ? this.attrs.add(name) : this.attrs.delete(name)
    },
  }
  const statusNode = {textContent: ""}
  const el = {
    dataset: label ? {overLabel: label} : {},
    listeners: {},
    querySelector: (selector) => ({"[phx-drop-target]": area, "[data-over-status]": status ? statusNode : null})[selector],
    addEventListener(type, handler) {
      this.listeners[type] = handler
    },
  }
  const hook = {...Dropzone, el}
  hook.mounted()
  return {el, area, statusNode}
}

test("a file over the area lights it and is announced", () => {
  const {el, area, statusNode} = build()
  el.listeners.dragenter()
  assert.equal(area.attrs.has("data-over"), true)
  assert.equal(statusNode.textContent, "Drop to upload")
})

test("leaving a child does not turn the light off, leaving the area does", () => {
  const {el, area, statusNode} = build()
  el.listeners.dragenter()
  el.listeners.dragenter()
  el.listeners.dragleave()
  assert.equal(area.attrs.has("data-over"), true)
  assert.equal(statusNode.textContent, "Drop to upload")
  el.listeners.dragleave()
  assert.equal(area.attrs.has("data-over"), false)
  assert.equal(statusNode.textContent, "")
})

test("a drop puts the light out and clears the announcement", () => {
  const {el, area, statusNode} = build()
  el.listeners.dragenter()
  el.listeners.drop()
  assert.equal(area.attrs.has("data-over"), false)
  assert.equal(statusNode.textContent, "")
})

test("with no announcement region the light still works", () => {
  const {el, area} = build({status: false})
  el.listeners.dragenter()
  assert.equal(area.attrs.has("data-over"), true)
})
