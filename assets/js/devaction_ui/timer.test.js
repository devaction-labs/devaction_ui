import test from "node:test"
import assert from "node:assert/strict"
import Timer from "./timer.js"

const build = (dataset) => {
  const target = {textContent: ""}
  const hook = {...Timer, el: {dataset, querySelector: (selector) => (selector === "[data-time]" ? target : null)}}
  return {hook, target}
}

const withClock = (now, run) => {
  const realNow = Date.now
  Date.now = () => now
  try {
    run()
  } finally {
    Date.now = realNow
  }
}

test("a paused timer writes its base once and keeps no interval", () => {
  const {hook, target} = build({base: "125", startedAt: "", now: "1000"})
  hook.mounted()
  assert.equal(target.textContent, "00:02:05")
  assert.equal(hook.interval, undefined)
})

test("a running timer counts from the server clock, not from the browser's", () => {
  withClock(5_000_000, () => {
    const {hook, target} = build({base: "60", startedAt: "1000", now: "1090"})
    hook.mounted()
    assert.equal(target.textContent, "00:02:30")
    hook.destroyed()
  })
})

test("a running timer keeps an interval that destroyed clears", () => {
  const {hook} = build({base: "0", startedAt: "10", now: "20"})
  hook.mounted()
  assert.notEqual(hook.interval, undefined)
  hook.destroyed()
})

test("an update from the server redraws with the new numbers", () => {
  const {hook, target} = build({base: "0", startedAt: "", now: "1000"})
  hook.mounted()
  assert.equal(target.textContent, "00:00:00")
  hook.el.dataset.base = "3700"
  hook.updated()
  assert.equal(target.textContent, "01:01:40")
})

test("the mini timer writes hours and minutes", () => {
  const {hook, target} = build({base: "3725", startedAt: "", now: "1000", format: "short"})
  hook.mounted()
  assert.equal(target.textContent, "01:02")
})

test("an element without the time target does not break", () => {
  const hook = {...Timer, el: {dataset: {base: "5"}, querySelector: () => null}}
  assert.doesNotThrow(() => hook.mounted())
})
