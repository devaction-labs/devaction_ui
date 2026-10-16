import assert from "node:assert/strict"
import test from "node:test"
import {completeClock, fromMinutes, hintFor, lengthBetween, lengthText, maskClock, stepClock, suggestions, toMinutes} from "./clock.js"

const patterns = {hours: "%{count} h", minutes: "%{count} min"}

test("a time and its minutes go both ways", () => {
  assert.equal(toMinutes("09:30"), 570)
  assert.equal(fromMinutes(570), "09:30")
  assert.equal(fromMinutes(0), "00:00")
})

test("typing lays digits out as a time", () => {
  assert.equal(maskClock("9"), "9")
  assert.equal(maskClock("093"), "09:3")
  assert.equal(maskClock("09:30"), "09:30")
  assert.equal(maskClock("0930777"), "09:30")
  assert.equal(maskClock("ab"), "")
})

test("a half-typed time is completed, and a time that does not exist is refused", () => {
  assert.equal(completeClock("9"), "09:00")
  assert.equal(completeClock("11"), "11:00")
  assert.equal(completeClock("930"), "09:30")
  assert.equal(completeClock("11:15"), "11:15")
  assert.equal(completeClock("25"), null)
  assert.equal(completeClock("12:75"), null)
  assert.equal(completeClock(""), null)
})

test("a step moves to the next time on the grid and stays inside the day", () => {
  assert.equal(stepClock(675, 1, 15), 690)
  assert.equal(stepClock(677, 1, 15), 690)
  assert.equal(stepClock(677, -1, 15), 675)
  assert.equal(stepClock(675, -1, 15), 660)
  assert.equal(stepClock(0, -1, 15), 0)
  assert.equal(stepClock(1439, 1, 15), 1425)
})

test("the suggestions are the steps around a time, inside the day", () => {
  assert.deepEqual(suggestions(675, 15).map(fromMinutes), ["10:30", "10:45", "11:00", "11:15", "11:30", "11:45", "12:00", "12:15"])
  assert.deepEqual(suggestions(15, 15, {before: 2, after: 1}), [0, 15, 30])
})

test("the length of a suggestion counts from the start, and only after it", () => {
  assert.equal(lengthBetween(540, 675), 135)
  assert.equal(lengthBetween(675, 540), 0)
  assert.equal(hintFor(630, 540), 90)
  assert.equal(hintFor(540, 540), null)
  assert.equal(hintFor(500, 540), null)
})

test("a length is written with the caller's words", () => {
  assert.equal(lengthText(135, patterns), "2 h 15 min")
  assert.equal(lengthText(120, patterns), "2 h")
  assert.equal(lengthText(45, patterns), "45 min")
  assert.equal(lengthText(0, patterns), "0 min")
})
