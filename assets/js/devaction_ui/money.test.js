import test from "node:test"
import assert from "node:assert/strict"
import {caretAfter, formatMoney, formatReais, moneyOptions} from "./money.js"

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
