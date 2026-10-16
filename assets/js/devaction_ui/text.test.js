import assert from "node:assert/strict"
import test from "node:test"
import {backspaceAt, boxesOf, clean, codeChars, deleteAt, enterChars, fillLabel, firstEmpty, fold, isComplete, isTaken, joinCode, matches, moveBox} from "./text.js"

test("folding drops accents and case", () => {
  assert.equal(fold("Pão Quente"), "pao quente")
  assert.equal(fold("Dízimos"), "dizimos")
})

test("a label matches a term in the middle, ignoring accents; blank matches all", () => {
  assert.equal(matches("Padaria Pão Quente", "pao"), true)
  assert.equal(matches("SGE · Igreja Central", "IGREJA"), true)
  assert.equal(matches("Hub", "pao"), false)
  assert.equal(matches("Hub", "  "), true)
})

test("a label pattern is filled with the pill's text", () => {
  assert.equal(fillLabel("Remove %{label}", "docs"), "Remove docs")
  assert.equal(fillLabel("%{label} added", "a b"), "a b added")
  assert.equal(fillLabel("Remove", "docs"), "Remove")
  assert.equal(fillLabel(undefined, "docs"), undefined)
})

test("cleaning trims and drops the comma that ended the word", () => {
  assert.equal(clean("  docs, "), "docs")
  assert.equal(clean("a,"), "a")
  assert.equal(clean("   "), "")
})

test("a repeat is a repeat whatever its case", () => {
  assert.equal(isTaken(["backend", "Docs"], "docs"), true)
  assert.equal(isTaken(["backend"], "docs"), false)
  assert.equal(isTaken([], "docs"), false)
})

const code = {numeric: true}

test("a code takes only digits and at most as many as it has boxes", () => {
  assert.deepEqual(codeChars("482 913-77", {length: 6, numeric: true}), ["4", "8", "2", "9", "1", "3"])
  assert.deepEqual(codeChars("a1-b2", {length: 6, numeric: false}), ["a", "1", "b", "2"])
  assert.deepEqual(boxesOf("48", 4), ["4", "8", "", ""])
  assert.equal(joinCode(["4", "8", "", ""]), "48")
})

test("typing a character fills the box and moves on, and the last box keeps the focus", () => {
  assert.deepEqual(enterChars(["", "", ""], 0, "4", code), {boxes: ["4", "", ""], focus: 1})
  assert.deepEqual(enterChars(["4", "8", ""], 2, "2", code), {boxes: ["4", "8", "2"], focus: 2})
  assert.deepEqual(enterChars(["4", "", ""], 0, "x", code), {boxes: ["4", "", ""], focus: 0})
})

test("pasting the whole code fills every box; pasting in the middle fills the rest", () => {
  assert.deepEqual(enterChars(Array(6).fill(""), 0, "482913", code), {boxes: ["4", "8", "2", "9", "1", "3"], focus: 5})
  assert.deepEqual(enterChars(Array(6).fill(""), 3, "4829", code), {boxes: ["", "", "", "4", "8", "2"], focus: 5})
  assert.deepEqual(enterChars(["", "", "", ""], 1, "12", code), {boxes: ["", "1", "2", ""], focus: 3})
})

test("Backspace clears the box, or steps back when it is empty", () => {
  assert.deepEqual(backspaceAt(["4", "8", ""], 1), {boxes: ["4", "", ""], focus: 1})
  assert.deepEqual(backspaceAt(["4", "8", ""], 2), {boxes: ["4", "", ""], focus: 1})
  assert.deepEqual(backspaceAt(["", "8"], 0), {boxes: ["", "8"], focus: 0})
  assert.deepEqual(deleteAt(["4", "8"], 0), {boxes: ["", "8"], focus: 0})
})

test("arrows move between boxes without leaving the code", () => {
  assert.equal(moveBox("ArrowLeft", 0, 6), 0)
  assert.equal(moveBox("ArrowRight", 2, 6), 3)
  assert.equal(moveBox("ArrowRight", 5, 6), 5)
  assert.equal(moveBox("Home", 3, 6), 0)
  assert.equal(moveBox("End", 3, 6), 5)
  assert.equal(moveBox("a", 3, 6), undefined)
})

test("a code is complete when no box is empty, and the first empty box is where typing goes", () => {
  assert.equal(isComplete(["4", "8"]), true)
  assert.equal(isComplete(["4", ""]), false)
  assert.equal(firstEmpty(["4", "", ""]), 1)
  assert.equal(firstEmpty(["4", "8"]), 1)
})
