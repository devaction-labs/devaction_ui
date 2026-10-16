import test from "node:test"
import assert from "node:assert/strict"
import {NUMBER_KEYS, add, clamp, clampText, compare, keyDelta, parseLimit, plain, render, scaled} from "./number_logic.js"

const n = (text) => scaled(text)
const whole = {step: n("2"), min: n("1"), max: n("9"), precision: 0, decimal: "."}

test("text is read as an integer scaled by its decimals, with a dot or a comma", () => {
  assert.deepEqual(scaled("0.25"), {int: 25, scale: 2})
  assert.deepEqual(scaled("1,5"), {int: 15, scale: 1})
  assert.deepEqual(scaled("-3"), {int: -3, scale: 0})
  assert.deepEqual(scaled(" 7 "), {int: 7, scale: 0})
  assert.equal(scaled("abc"), null)
  assert.equal(scaled(""), null)
  assert.equal(scaled("1.2.3"), null)
  assert.equal(scaled("99999999999999999999"), null)
})

test("sums do not drift", () => {
  assert.equal(plain(add(n("0.1"), n("0.2"))), "0.3")
  assert.equal(plain(add(n("1.15"), n("0.05"))), "1.2")
  assert.equal(plain(add(n("2.5"), n("-2.5"))), "0")
})

test("numbers compare across scales", () => {
  assert.equal(compare(n("1.50"), n("1.5")), 0)
  assert.equal(compare(n("0.3"), n("0.25")), 1)
  assert.equal(compare(n("-1"), n("0.01")), -1)
})

test("numbers are shown with a fixed precision, rounded half away from zero", () => {
  assert.equal(render(n("2.5"), 2), "2.50")
  assert.equal(render(n("1.005"), 2, ","), "1,01")
  assert.equal(render(n("-1.005"), 2), "-1.01")
  assert.equal(render(n("1.004"), 2), "1.00")
  assert.equal(render(n("0.5"), 0), "1")
  assert.equal(render(n("-0.004"), 2), "0.00")
  assert.equal(render(n("12"), 0), "12")
  assert.equal(render(n("0.05"), 2), "0.05")
})

test("the arrows move a step and the page keys ten", () => {
  assert.equal(keyDelta("ArrowUp", "3", whole), "2")
  assert.equal(keyDelta("ArrowDown", "5", whole), "-2")
  const wide = {step: n("1"), min: n("0"), max: n("100"), precision: 0, decimal: "."}
  assert.equal(keyDelta("PageUp", "1", wide), "10")
  assert.equal(keyDelta("PageDown", "50", wide), "-10")
})

test("a fractional step moves exactly", () => {
  const rate = {step: n("0.1"), min: n("0"), max: n("1"), precision: 1, decimal: "."}
  assert.equal(keyDelta("ArrowUp", "0.2", rate), "0.1")
  assert.equal(keyDelta("ArrowDown", "0,3", rate), "-0.1")
  assert.equal(keyDelta("PageUp", "0.5", rate), "0.5")
})

test("Home and End go to the limits, and do nothing where there is none", () => {
  assert.equal(keyDelta("Home", "5", whole), "-4")
  assert.equal(keyDelta("End", "5", whole), "4")
  assert.equal(keyDelta("Home", "1", whole), null)
  assert.equal(keyDelta("End", "9", whole), null)
  assert.equal(keyDelta("Home", "5", {...whole, min: null}), null)
  assert.equal(keyDelta("End", "5", {...whole, max: null}), null)
})

test("a move that would pass a limit stops at it, and none at the limit moves nothing", () => {
  assert.equal(keyDelta("PageUp", "3", whole), "6")
  assert.equal(keyDelta("PageDown", "3", whole), "-2")
  assert.equal(keyDelta("ArrowUp", "9", whole), null)
  assert.equal(keyDelta("ArrowDown", "1", whole), null)
})

test("other keys and text that is not a number move nothing", () => {
  assert.equal(keyDelta("Enter", "3", whole), null)
  assert.equal(keyDelta("ArrowUp", "", whole), null)
  assert.equal(keyDelta("ArrowUp", "abc", whole), null)
  assert.deepEqual(NUMBER_KEYS, ["ArrowUp", "ArrowDown", "PageUp", "PageDown", "Home", "End"])
})

test("no limit means no clamping", () => {
  const free = {step: n("1"), min: null, max: null}
  assert.equal(keyDelta("ArrowDown", "-5", free), "-1")
  assert.equal(plain(clamp(n("500"), null, null)), "500")
  assert.equal(plain(clamp(n("500"), null, n("9"))), "9")
  assert.equal(plain(clamp(n("-5"), n("0"), null)), "0")
})

test("limits are read from attributes", () => {
  assert.equal(parseLimit(undefined), null)
  assert.equal(parseLimit(""), null)
  assert.deepEqual(parseLimit("12"), {int: 12, scale: 0})
  assert.deepEqual(parseLimit("0"), {int: 0, scale: 0})
  assert.deepEqual(parseLimit("0.5"), {int: 5, scale: 1})
})

test("what is typed is held inside the limits and shown with the precision, and text that is not a number is kept", () => {
  assert.equal(clampText("50", whole), "9")
  assert.equal(clampText("0", whole), "1")
  assert.equal(clampText("5", whole), "5")
  assert.equal(clampText("-3", {min: null, max: n("9")}), "-3")
  assert.equal(clampText("", whole), "")
  assert.equal(clampText("abc", whole), "abc")
  const money = {min: n("0"), max: n("10"), precision: 2, decimal: ","}
  assert.equal(clampText("1.5", money), "1,50")
  assert.equal(clampText("12,345", money), "10,00")
  assert.equal(clampText("0,255", money), "0,26")
})
