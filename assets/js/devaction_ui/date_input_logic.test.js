import test from "node:test"
import assert from "node:assert/strict"
import {formatIso, mask, read} from "./date_input_logic.js"

const dmy = {order: "dmy", separator: "/"}
const ymd = {order: "ymd", separator: "-"}
const mdy = {order: "mdy", separator: "/"}

test("the mask keeps digits only and puts the separators between the parts", () => {
  assert.equal(mask("1", dmy), "1")
  assert.equal(mask("16", dmy), "16")
  assert.equal(mask("161", dmy), "16/1")
  assert.equal(mask("1610", dmy), "16/10")
  assert.equal(mask("16102026", dmy), "16/10/2026")
  assert.equal(mask("16/10/2026", dmy), "16/10/2026")
  assert.equal(mask("ab16x10", dmy), "16/10")
})

test("the mask stops at eight digits and follows the order of the format", () => {
  assert.equal(mask("161020269999", dmy), "16/10/2026")
  assert.equal(mask("20261016", ymd), "2026-10-16")
  assert.equal(mask("202", ymd), "202")
  assert.equal(mask("20261", ymd), "2026-1")
  assert.equal(mask("10162026", mdy), "10/16/2026")
  assert.equal(mask("", dmy), "")
})

test("an ISO date is written in the order and with the separator of the field", () => {
  assert.equal(formatIso("2026-10-16", dmy), "16/10/2026")
  assert.equal(formatIso("2026-10-16", mdy), "10/16/2026")
  assert.equal(formatIso("2026-10-16", ymd), "2026-10-16")
  assert.equal(formatIso(null, dmy), "")
  assert.equal(formatIso("", dmy), "")
})

test("a complete text reads as its ISO date", () => {
  assert.deepEqual(read("16/10/2026", dmy), {iso: "2026-10-16", status: "ok"})
  assert.deepEqual(read("10/16/2026", mdy), {iso: "2026-10-16", status: "ok"})
  assert.deepEqual(read("2026-10-16", ymd), {iso: "2026-10-16", status: "ok"})
  assert.deepEqual(read("29/02/2028", dmy), {iso: "2028-02-29", status: "ok"})
})

test("nothing typed is empty and a text still being typed is partial", () => {
  assert.deepEqual(read("", dmy), {iso: null, status: "empty"})
  assert.deepEqual(read("16/1", dmy), {iso: null, status: "partial"})
  assert.deepEqual(read("16/10/202", dmy), {iso: null, status: "partial"})
})

test("a day that does not exist is invalid", () => {
  assert.equal(read("31/02/2026", dmy).status, "invalid")
  assert.equal(read("29/02/2027", dmy).status, "invalid")
  assert.equal(read("00/10/2026", dmy).status, "invalid")
  assert.equal(read("16/13/2026", dmy).status, "invalid")
  assert.equal(read("16/10/0099", dmy).status, "invalid")
})

test("a day before the minimum is invalid and the minimum itself is fine", () => {
  assert.equal(read("09/10/2026", dmy, "2026-10-10").status, "invalid")
  assert.equal(read("10/10/2026", dmy, "2026-10-10").status, "ok")
  assert.equal(read("11/10/2026", dmy, "2026-10-10").iso, "2026-10-11")
})
