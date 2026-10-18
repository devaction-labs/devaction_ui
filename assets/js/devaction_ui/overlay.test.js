import assert from "node:assert/strict"
import test from "node:test"

globalThis.MutationObserver ??= class {
  observe() {}
  disconnect() {}
}

const listeners = new Map()
const body = {style: {}, tagName: "BODY", children: [], hasAttribute: () => false}
const page = {tagName: "MAIN", hasAttribute: () => false, setAttribute() {}, removeAttribute() {}, attrs: new Set()}
page.setAttribute = (name) => page.attrs.add(name)
page.removeAttribute = (name) => page.attrs.delete(name)

globalThis.window = {innerWidth: 1024}
globalThis.document = {
  body,
  documentElement: {clientWidth: 1024},
  addEventListener: (type, fn) => listeners.set(type, fn),
  removeEventListener: (type) => listeners.delete(type),
}

const {default: Overlay} = await import("./overlay.js")

const overlay = (hidden) => {
  const own = new Map()
  const el = {
    id: "drawer",
    hidden,
    tagName: "DIV",
    parentElement: body,
    hasAttribute: () => false,
    addEventListener: (type, fn) => own.set(type, fn),
    removeEventListener: (type) => own.delete(type),
  }
  body.children = [page, el]
  return {hook: Object.assign(Object.create(Overlay), {el}), own}
}

test("an overlay that is not lazy holds the page from mount to destroy", () => {
  const {hook} = overlay(false)

  hook.mounted()
  assert.equal(body.style.overflow, "hidden")
  assert.ok(page.attrs.has("inert"))

  hook.destroyed()
  assert.equal(page.attrs.has("inert"), false)
  assert.equal(listeners.size, 0)
})

test("a lazy overlay holds nothing until it is opened, and lets go when it is closed", () => {
  const {hook, own} = overlay(true)

  hook.mounted()
  assert.equal(page.attrs.has("inert"), false)
  assert.equal(listeners.size, 0)

  own.get("devaction:overlay-open")()
  assert.ok(page.attrs.has("inert"))
  assert.ok(listeners.has("keydown"))

  own.get("devaction:overlay-close")()
  assert.equal(page.attrs.has("inert"), false)
  assert.equal(listeners.size, 0)

  hook.destroyed()
  assert.equal(own.size, 0)
})

test("opening twice, or closing what is not open, changes nothing", () => {
  const {hook, own} = overlay(true)
  hook.mounted()

  own.get("devaction:overlay-close")()
  assert.equal(page.attrs.has("inert"), false)

  own.get("devaction:overlay-open")()
  own.get("devaction:overlay-open")()
  own.get("devaction:overlay-close")()
  assert.equal(page.attrs.has("inert"), false)
  assert.equal(listeners.size, 0)
})
