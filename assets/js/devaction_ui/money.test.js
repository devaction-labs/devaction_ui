import test from "node:test"
import assert from "node:assert/strict"
import {caretAfter, formatReais} from "./money.js"

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
