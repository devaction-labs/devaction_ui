import assert from "node:assert/strict"
import test from "node:test"
import {add, caretAfter, clamp, clampPair, clampScaled, clampText, compare, elapsed, fillBox, fillStyle, formatClock, formatMoney, formatReais, formats, formatShort, fraction, keyDelta, moneyOptions, NUMBER_KEYS, pairText, parseLimit, percent, plain, readTimer, render, scaled, valueText} from "./numbers.js"

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
  assert.equal(plain(clampScaled(n("500"), null, null)), "500")
  assert.equal(plain(clampScaled(n("500"), null, n("9"))), "9")
  assert.equal(plain(clampScaled(n("-5"), n("0"), null)), "0")
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

test("the digits typed become reais and cents", () => {
  assert.equal(formatReais("1"), "0,01")
  assert.equal(formatReais("12"), "0,12")
  assert.equal(formatReais("123"), "1,23")
  assert.equal(formatReais("1234567"), "12.345,67")
  assert.equal(formatReais("100000000"), "1.000.000,00")
})

test("what is not a digit is dropped, and leading zeros do not stay", () => {
  assert.equal(formatReais("R$ 1.234,56"), "1.234,56")
  assert.equal(formatReais("0005"), "0,05")
  assert.equal(formatReais("abc"), "")
  assert.equal(formatReais(""), "")
})

test("the value the server renders is formatted the same way", () => {
  assert.equal(formatReais("123456"), "1.234,56")
  assert.equal(formatReais("1.234,56"), "1.234,56")
})

test("the caret stays at the end when it was at the end", () => {
  assert.equal(caretAfter("0,011", 5, "0,11"), 4)
  assert.equal(caretAfter("1", 1, "0,01"), 4)
})

test("the caret stays among the same digits when editing in the middle", () => {
  assert.equal(caretAfter("1.2334,56", 5, "12.334,56"), 5)
  assert.equal(caretAfter("1.234,56", 0, "1.234,56"), 0)
  assert.equal(caretAfter("1.234,56", 1, "1.234,56"), 1)
})

test("another currency takes its own separators and precision", () => {
  const usd = {decimal: ".", group: ","}
  assert.equal(formatMoney("123456", usd), "1,234.56")
  assert.equal(formatMoney("1", usd), "0.01")
  assert.equal(formatMoney("1234567", {decimal: ",", group: " "}), "12 345,67")
  assert.equal(formatMoney("1234567", {group: "'", decimal: "."}), "12'345.67")
  assert.equal(formatMoney("1234567", {group: ""}), "12345,67")
  assert.equal(formatMoney("1234567", {group: "$"}), "12$345,67")
})

test("a precision of 0 has no decimals and 3 has three", () => {
  assert.equal(formatMoney("1234567", {precision: 0, group: ","}), "1,234,567")
  assert.equal(formatMoney("0007", {precision: 0}), "7")
  assert.equal(formatMoney("5", {precision: 3}), "0,005")
  assert.equal(formatMoney("1234567", {precision: 3}), "1.234,567")
})

test("the sign counts only when the field is signed, and alone it waits for its digits", () => {
  assert.equal(formatMoney("-1234", {signed: true}), "-12,34")
  assert.equal(formatMoney("-12,34", {signed: true}), "-12,34")
  assert.equal(formatMoney("-", {signed: true}), "-")
  assert.equal(formatMoney("-1234"), "12,34")
  assert.equal(formatMoney("-"), "")
  assert.equal(formatMoney("", {signed: true}), "")
})

test("the reais of the first wave are the defaults", () => {
  assert.equal(formatReais("-1234"), "12,34")
  assert.equal(formatMoney("123456"), formatReais("123456"))
})

test("a value that is already formatted formats to itself", () => {
  assert.equal(formatMoney("1,234.56", {decimal: ".", group: ","}), "1,234.56")
  assert.equal(formatMoney("1 234 567", {precision: 0, group: " "}), "1 234 567")
  assert.equal(formatMoney("-1.234,56", {signed: true}), "-1.234,56")
})

test("the options come from the data attributes and the rest stays the default", () => {
  assert.deepEqual(moneyOptions({}), {signed: false})
  assert.deepEqual(moneyOptions({decimal: ".", group: ",", precision: "0", signed: "true"}), {
    decimal: ".",
    group: ",",
    precision: 0,
    signed: true,
  })
  assert.equal(formatMoney("1234567", moneyOptions({decimal: ".", group: ",", precision: "2"})), "12,345.67")
})

test("the caret stays after the sign when it was just after it", () => {
  assert.equal(caretAfter("-1,234", 1, "-1,234"), 1)
  assert.equal(caretAfter("-1,234", 0, "-1,234"), 0)
})

test("the fraction is the percent over 100, for the bubble", () => {
  assert.equal(fraction(50, 0, 100), 0.5)
  assert.equal(fraction(1, 0, 4), 0.25)
  assert.equal(fraction(5, 5, 5), 0)
})

test("the filled part grows from the left, or from the bottom when vertical", () => {
  const box = {left: 20, width: 50}
  assert.deepEqual(fillStyle("horizontal", box), {left: "20%", width: "50%"})
  assert.deepEqual(fillStyle("vertical", box), {bottom: "20%", height: "50%"})
  assert.deepEqual(fillStyle(undefined, box), {left: "20%", width: "50%"})
})

test("the value is placed between the minimum and the maximum", () => {
  assert.equal(percent(50, 0, 100), 50)
  assert.equal(percent(75, 50, 100), 50)
  assert.equal(percent("3", "1", "5"), 50)
})

test("the ends are 0 and 100", () => {
  assert.equal(percent(0, 0, 100), 0)
  assert.equal(percent(100, 0, 100), 100)
})

test("a range with no width is 0", () => {
  assert.equal(percent(5, 5, 5), 0)
})

test("the thumb that moves stops at the other one", () => {
  assert.deepEqual(clampPair(80, 50, "low"), {low: 50, high: 50})
  assert.deepEqual(clampPair(20, 50, "low"), {low: 20, high: 50})
  assert.deepEqual(clampPair(20, 10, "high"), {low: 20, high: 20})
  assert.deepEqual(clampPair("20", "70", "high"), {low: 20, high: 70})
})

test("the filled part runs from the low value to the high one", () => {
  assert.deepEqual(fillBox(20, 70, 0, 100), {left: 20, width: 50})
  assert.deepEqual(fillBox(5, 15, 0, 20), {left: 25, width: 50})
  assert.deepEqual(fillBox(0.5, 1.5, 0, 2), {left: 25, width: 50})
})

test("the value text fills the template, and no template is the number", () => {
  assert.equal(valueText("R$ %{value}k", 40), "R$ 40k")
  assert.equal(valueText(undefined, 40), "40")
  assert.equal(pairText("%{value} h", 2, 8), "2 h – 8 h")
  assert.equal(pairText(undefined, 2.5, 8), "2.5 – 8")
})

test("formatShort drops the seconds and formats say which writer each data-format picks", () => {
  assert.equal(formatShort(2843), "00:47")
  assert.equal(formatShort(3725), "01:02")
  assert.equal(formatShort(-1), "00:00")
  assert.equal(formats.short(3725), "01:02")
  assert.equal(formats.full(3725), "01:02:05")
})

test("format writes hours, minutes and seconds", () => {
  assert.equal(formatClock(0), "00:00:00")
  assert.equal(formatClock(59), "00:00:59")
  assert.equal(formatClock(3661), "01:01:01")
  assert.equal(formatClock(36000), "10:00:00")
  assert.equal(formatClock(-5), "00:00:00")
  assert.equal(formatClock(12.9), "00:00:12")
})

test("elapsed adds the running time to the base, and only while running", () => {
  assert.equal(elapsed({base: 100, startedAt: null, nowSeconds: 999}), 100)
  assert.equal(elapsed({base: 100, startedAt: 1000, nowSeconds: 1030}), 130)
  assert.equal(elapsed({base: 100, startedAt: 1000, nowSeconds: 990}), 100)
})

test("read takes the numbers of the element", () => {
  assert.deepEqual(readTimer({base: "60", startedAt: "1000", now: "1010"}), {base: 60, startedAt: 1000, serverNow: 1010})
  assert.deepEqual(readTimer({base: "0"}), {base: 0, startedAt: null, serverNow: null})
  assert.deepEqual(readTimer({}), {base: 0, startedAt: null, serverNow: null})
})

test("clamp keeps a number inside its ends", () => {
  assert.equal(clamp(5, 0, 1), 1)
  assert.equal(clamp(-5, 0, 1), 0)
  assert.equal(clamp(0.4, 0, 1), 0.4)
})
