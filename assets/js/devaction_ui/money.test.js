import test from "node:test"
import assert from "node:assert/strict"
import {formatReais} from "./money.js"

test("the digits typed become reais and cents", () => {
  assert.equal(formatReais("1"), "R$ 0,01")
  assert.equal(formatReais("12"), "R$ 0,12")
  assert.equal(formatReais("123"), "R$ 1,23")
  assert.equal(formatReais("1234567"), "R$ 12.345,67")
  assert.equal(formatReais("100000000"), "R$ 1.000.000,00")
})

test("what is not a digit is dropped, and leading zeros do not stay", () => {
  assert.equal(formatReais("R$ 1.234,56"), "R$ 1.234,56")
  assert.equal(formatReais("0005"), "R$ 0,05")
  assert.equal(formatReais("abc"), "")
  assert.equal(formatReais(""), "")
})
