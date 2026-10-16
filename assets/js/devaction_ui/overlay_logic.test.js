import assert from "node:assert/strict"
import test from "node:test"
import {dragOffset, dragStyle, exempt, isTop, lockStyle, release, retain, settleStyle, shouldClose, speed, stackWith, stackWithout} from "./overlay_logic.js"

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

test("the sheet follows the finger down and never goes up past its place", () => {
  assert.equal(dragOffset(100, 180), 80)
  assert.equal(dragOffset(100, 60), 0)
})

test("the speed is pixels per millisecond and a zero interval does not divide by zero", () => {
  assert.equal(speed(0, 0, 100, 100), 1)
  assert.equal(speed(0, 5, 10, 5), 10)
})

test("a long drag closes it, a short one does not", () => {
  assert.equal(shouldClose({offset: 300, height: 600, velocity: 0}), true)
  assert.equal(shouldClose({offset: 100, height: 600, velocity: 0.1}), false)
})

test("a fast flick closes it even when short", () => {
  assert.equal(shouldClose({offset: 40, height: 600, velocity: 0.9}), true)
})

test("a sheet with no height never closes", () => {
  assert.equal(shouldClose({offset: 50, height: 0, velocity: 2}), false)
})

test("the drag has no transition and the settle has none for reduced motion", () => {
  assert.deepEqual(dragStyle(24), {transform: "translateY(24px)", transition: "none"})
  assert.equal(settleStyle(true).transition, "none")
  assert.match(settleStyle(false).transition, /transform/)
  assert.equal(settleStyle(false).transform, "")
})
