import test from "node:test"
import assert from "node:assert/strict"
import {exempt, isTop, lockStyle, release, retain, stackWith, stackWithout} from "./overlay_logic.js"

test("the last overlay opened is the one on top, and an id is never repeated", () => {
  const stack = stackWith(stackWith([], "drawer"), "modal")
  assert.deepEqual(stack, ["drawer", "modal"])
  assert.equal(isTop(stack, "modal"), true)
  assert.equal(isTop(stack, "drawer"), false)
  assert.deepEqual(stackWith(stack, "drawer"), ["modal", "drawer"])
})

test("closing the top overlay hands Esc to the one below", () => {
  const stack = stackWithout(["drawer", "modal"], "modal")
  assert.deepEqual(stack, ["drawer"])
  assert.equal(isTop(stack, "drawer"), true)
  assert.equal(isTop([], "drawer"), false)
})

test("an element held inert by two overlays is freed only by the second release", () => {
  const key = {}
  const twice = retain(retain(new Map(), key), key)
  assert.equal(twice.get(key), 2)
  const once = release(twice, key)
  assert.equal(once.get(key), 1)
  assert.equal(release(once, key).has(key), false)
  assert.equal(release(new Map(), key).has(key), false)
})

test("the counts are never changed in place", () => {
  const key = {}
  const before = new Map()
  retain(before, key)
  assert.equal(before.size, 0)
})

test("the scroll lock keeps the width of the scrollbar as padding", () => {
  assert.deepEqual(lockStyle(15), {overflow: "hidden", paddingRight: "15px"})
  assert.deepEqual(lockStyle(0), {overflow: "hidden", paddingRight: ""})
})

test("scripts, styles, live regions and marked elements stay interactive", () => {
  assert.equal(exempt({tag: "SCRIPT", keep: false, live: false}), true)
  assert.equal(exempt({tag: "DIV", keep: true, live: false}), true)
  assert.equal(exempt({tag: "DIV", keep: false, live: true}), true)
  assert.equal(exempt({tag: "MAIN", keep: false, live: false}), false)
})
