import test from "node:test"
import assert from "node:assert/strict"
import {elapsed, format, read} from "./timer_logic.js"

test("format writes hours, minutes and seconds", () => {
  assert.equal(format(0), "00:00:00")
  assert.equal(format(59), "00:00:59")
  assert.equal(format(3661), "01:01:01")
  assert.equal(format(36000), "10:00:00")
  assert.equal(format(-5), "00:00:00")
  assert.equal(format(12.9), "00:00:12")
})

test("elapsed adds the running time to the base, and only while running", () => {
  assert.equal(elapsed({base: 100, startedAt: null, nowSeconds: 999}), 100)
  assert.equal(elapsed({base: 100, startedAt: 1000, nowSeconds: 1030}), 130)
  assert.equal(elapsed({base: 100, startedAt: 1000, nowSeconds: 990}), 100)
})

test("read takes the numbers of the element", () => {
  assert.deepEqual(read({base: "60", startedAt: "1000", now: "1010"}), {base: 60, startedAt: 1000, serverNow: 1010})
  assert.deepEqual(read({base: "0"}), {base: 0, startedAt: null, serverNow: null})
  assert.deepEqual(read({}), {base: 0, startedAt: null, serverNow: null})
})
