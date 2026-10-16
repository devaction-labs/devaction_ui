import assert from "node:assert/strict"
import test from "node:test"
import {addDays, addMonths, clampMin, daysInMonth, formatIso, leadingDays, maskDate, monthOf, moveFocus, pick, readDate, sameDayIn, shiftMonth, weekdayIndex} from "./dates.js"

test("adding days and months crosses month and year ends", () => {
  assert.equal(addDays("2026-10-31", 1), "2026-11-01")
  assert.equal(addDays("2026-01-01", -1), "2025-12-31")
  assert.equal(addMonths("2026-12-15", 1), "2027-01-15")
  assert.equal(addMonths("2026-01-31", 1), "2026-03-03")
})

test("a month's size and the days before its first", () => {
  assert.equal(daysInMonth({year: 2026, month: 1}), 28)
  assert.equal(daysInMonth({year: 2028, month: 1}), 29)
  assert.equal(leadingDays({year: 2026, month: 9}, 0), 4) // 1 Oct 2026 is a Thursday
  assert.equal(leadingDays({year: 2026, month: 9}, 1), 3) // with Monday first
})

test("shifting a month wraps the year", () => {
  assert.deepEqual(shiftMonth({year: 2026, month: 11}, 1), {year: 2027, month: 0})
  assert.deepEqual(shiftMonth({year: 2026, month: 0}, -1), {year: 2025, month: 11})
  assert.deepEqual(monthOf("2026-10-14"), {year: 2026, month: 9})
})

test("the same day in a shorter month is held to its last day", () => {
  assert.equal(sameDayIn("2026-01-31", {year: 2026, month: 1}), "2026-02-28")
  assert.equal(sameDayIn("2026-10-14", {year: 2026, month: 10}), "2026-11-14")
})

test("keys move the focused day, and unknown keys do not", () => {
  assert.equal(moveFocus("ArrowRight", "2026-10-14", 0), "2026-10-15")
  assert.equal(moveFocus("ArrowDown", "2026-10-14", 0), "2026-10-21")
  assert.equal(moveFocus("PageDown", "2026-10-14", 0), "2026-11-14")
  assert.equal(moveFocus("a", "2026-10-14", 0), undefined)
})

test("Home and End go to the edges of the week, whatever day it starts on", () => {
  assert.equal(weekdayIndex("2026-10-14", 0), 3) // Wednesday, Sunday first
  assert.equal(moveFocus("Home", "2026-10-14", 0), "2026-10-11")
  assert.equal(moveFocus("End", "2026-10-14", 0), "2026-10-17")
  assert.equal(moveFocus("Home", "2026-10-14", 1), "2026-10-12")
  assert.equal(moveFocus("End", "2026-10-14", 1), "2026-10-18")
})

test("single mode keeps the last pick", () => {
  assert.deepEqual(pick({from: "2026-10-01", to: null}, "2026-10-05", "single"), {from: "2026-10-05", to: null})
})

test("a range starts, closes, restarts earlier and starts anew", () => {
  const start = pick({from: null, to: null}, "2026-10-12", "range")
  assert.deepEqual(start, {from: "2026-10-12", to: null})

  const closed = pick(start, "2026-10-20", "range")
  assert.deepEqual(closed, {from: "2026-10-12", to: "2026-10-20"})

  assert.deepEqual(pick(start, "2026-10-11", "range"), {from: "2026-10-11", to: null})
  assert.deepEqual(pick(closed, "2026-10-25", "range"), {from: "2026-10-25", to: null})
})

test("clampMin holds a day to the minimum", () => {
  assert.equal(clampMin("2026-10-03", "2026-10-10"), "2026-10-10")
  assert.equal(clampMin("2026-10-12", "2026-10-10"), "2026-10-12")
  assert.equal(clampMin("2026-10-03", null), "2026-10-03")
})

const dmy = {order: "dmy", separator: "/"}
const ymd = {order: "ymd", separator: "-"}
const mdy = {order: "mdy", separator: "/"}

test("the mask keeps digits only and puts the separators between the parts", () => {
  assert.equal(maskDate("1", dmy), "1")
  assert.equal(maskDate("16", dmy), "16")
  assert.equal(maskDate("161", dmy), "16/1")
  assert.equal(maskDate("1610", dmy), "16/10")
  assert.equal(maskDate("16102026", dmy), "16/10/2026")
  assert.equal(maskDate("16/10/2026", dmy), "16/10/2026")
  assert.equal(maskDate("ab16x10", dmy), "16/10")
})

test("the mask stops at eight digits and follows the order of the format", () => {
  assert.equal(maskDate("161020269999", dmy), "16/10/2026")
  assert.equal(maskDate("20261016", ymd), "2026-10-16")
  assert.equal(maskDate("202", ymd), "202")
  assert.equal(maskDate("20261", ymd), "2026-1")
  assert.equal(maskDate("10162026", mdy), "10/16/2026")
  assert.equal(maskDate("", dmy), "")
})

test("an ISO date is written in the order and with the separator of the field", () => {
  assert.equal(formatIso("2026-10-16", dmy), "16/10/2026")
  assert.equal(formatIso("2026-10-16", mdy), "10/16/2026")
  assert.equal(formatIso("2026-10-16", ymd), "2026-10-16")
  assert.equal(formatIso(null, dmy), "")
  assert.equal(formatIso("", dmy), "")
})

test("a complete text reads as its ISO date", () => {
  assert.deepEqual(readDate("16/10/2026", dmy), {iso: "2026-10-16", status: "ok"})
  assert.deepEqual(readDate("10/16/2026", mdy), {iso: "2026-10-16", status: "ok"})
  assert.deepEqual(readDate("2026-10-16", ymd), {iso: "2026-10-16", status: "ok"})
  assert.deepEqual(readDate("29/02/2028", dmy), {iso: "2028-02-29", status: "ok"})
})

test("nothing typed is empty and a text still being typed is partial", () => {
  assert.deepEqual(readDate("", dmy), {iso: null, status: "empty"})
  assert.deepEqual(readDate("16/1", dmy), {iso: null, status: "partial"})
  assert.deepEqual(readDate("16/10/202", dmy), {iso: null, status: "partial"})
})

test("a day that does not exist is invalid", () => {
  assert.equal(readDate("31/02/2026", dmy).status, "invalid")
  assert.equal(readDate("29/02/2027", dmy).status, "invalid")
  assert.equal(readDate("00/10/2026", dmy).status, "invalid")
  assert.equal(readDate("16/13/2026", dmy).status, "invalid")
  assert.equal(readDate("16/10/0099", dmy).status, "invalid")
})

test("a day before the minimum is invalid and the minimum itself is fine", () => {
  assert.equal(readDate("09/10/2026", dmy, "2026-10-10").status, "invalid")
  assert.equal(readDate("10/10/2026", dmy, "2026-10-10").status, "ok")
  assert.equal(readDate("11/10/2026", dmy, "2026-10-10").iso, "2026-10-11")
})
