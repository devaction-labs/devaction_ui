import assert from "node:assert/strict"
import test from "node:test"
import {canSend, carriesFiles, countView, fieldHeight, intentOf, isOver, joinFiles} from "./composer_logic.js"

const measures = {lineHeight: 20, padding: 10, maxRows: 4}
const key = (key, extra = {}) => ({key, shiftKey: false, isComposing: false, keyCode: 0, ...extra})
const state = (extra = {}) => ({text: "hi", maxLength: 0, busy: false, ...extra})

test("the field grows with the text up to the rows allowed", () => {
  assert.deepEqual(fieldHeight({...measures, scrollHeight: 50}), {height: 50, scrolls: false})
  assert.deepEqual(fieldHeight({...measures, scrollHeight: 90}), {height: 90, scrolls: false})
  assert.deepEqual(fieldHeight({...measures, scrollHeight: 200}), {height: 90, scrolls: true})
})

test("no limit means never over", () => {
  assert.equal(isOver("x".repeat(100), 0), false)
  assert.equal(isOver("x".repeat(11), 10), true)
  assert.equal(isOver("x".repeat(10), 10), false)
})

test("a message goes when it has text within the limit and the AI is not answering", () => {
  assert.equal(canSend(state()), true)
  assert.equal(canSend(state({text: "  \n "})), false)
  assert.equal(canSend(state({text: "x".repeat(11), maxLength: 10})), false)
  assert.equal(canSend(state({busy: true})), false)
})

test("the counter shows from 80% of the limit", () => {
  assert.deepEqual(countView(10, 100, "en"), {hidden: true, text: ""})
  assert.deepEqual(countView(80, 100, "en"), {hidden: false, text: "80 / 100"})
  assert.deepEqual(countView(1200, 4000, "en"), {hidden: true, text: ""})
  assert.deepEqual(countView(3500, 4000, "en"), {hidden: false, text: "3,500 / 4,000"})
  assert.deepEqual(countView(500, 0, "en"), {hidden: true, text: ""})
})

test("Enter sends, Shift+Enter is a new line, and an accent being composed is left alone", () => {
  assert.equal(intentOf(key("Enter"), state()), "send")
  assert.equal(intentOf(key("Enter", {shiftKey: true}), state()), "none")
  assert.equal(intentOf(key("Enter", {isComposing: true}), state()), "none")
  assert.equal(intentOf(key("Enter", {keyCode: 229}), state()), "none")
})

test("Enter with nothing to send, or while the AI answers, sends nothing and adds no line", () => {
  assert.equal(intentOf(key("Enter"), state({text: ""})), "hold")
  assert.equal(intentOf(key("Enter"), state({busy: true})), "hold")
})

test("Esc stops the answer, and only while there is one", () => {
  assert.equal(intentOf(key("Escape"), state({busy: true})), "stop")
  assert.equal(intentOf(key("Escape"), state()), "none")
})

test("↑ in an empty field asks to edit the last message", () => {
  assert.equal(intentOf(key("ArrowUp"), state({text: ""})), "edit-last")
  assert.equal(intentOf(key("ArrowUp"), state()), "none")
})

test("only a drag with files counts", () => {
  assert.equal(carriesFiles(["text/plain", "Files"]), true)
  assert.equal(carriesFiles(["text/plain"]), false)
  assert.equal(carriesFiles(undefined), false)
})

test("the files chosen stay when more arrive", () => {
  assert.deepEqual(joinFiles(["a"], ["b", "c"]), ["a", "b", "c"])
  assert.deepEqual(joinFiles(undefined, ["b"]), ["b"])
})
