import assert from "node:assert/strict"
import test from "node:test"
import {activatesButton, applyPick, canSend, carriesFiles, countView, fieldHeight, intentOf, isOver, joinFiles, moveActive, triggerOf} from "./composer_logic.js"

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

test("an open suggestion list owns the arrows, Enter, Tab and Esc", () => {
  const open = state({text: "/re", suggesting: true})
  assert.equal(intentOf(key("ArrowDown"), open), "next")
  assert.equal(intentOf(key("ArrowUp"), open), "previous")
  assert.equal(intentOf(key("Enter"), open), "pick")
  assert.equal(intentOf(key("Tab"), open), "pick")
  assert.equal(intentOf(key("Escape"), open), "close")
  assert.equal(intentOf(key("Escape"), {...open, busy: true}), "close")
})

test("Enter that confirms an accent does not pick a suggestion", () => {
  const open = state({suggesting: true})
  assert.equal(intentOf(key("Enter", {isComposing: true}), open), "none")
  assert.equal(intentOf(key("ArrowDown", {keyCode: 229}), open), "none")
})

test("a closed list leaves the keys to the field", () => {
  assert.equal(intentOf(key("Enter"), state({suggesting: false})), "send")
  assert.equal(intentOf(key("ArrowDown"), state()), "none")
})

test("a / at the start of the text opens the commands", () => {
  assert.deepEqual(triggerOf("/", 1), {trigger: "/", query: "", start: 0, end: 1})
  assert.deepEqual(triggerOf("/rev", 4), {trigger: "/", query: "rev", start: 0, end: 4})
  assert.equal(triggerOf("see /rev", 8), null)
  assert.equal(triggerOf("/rev now", 8), null)
})

test("an @ at the start of a word opens the mentions, wherever the word is", () => {
  assert.deepEqual(triggerOf("@", 1), {trigger: "@", query: "", start: 0, end: 1})
  assert.deepEqual(triggerOf("ask @ca", 7), {trigger: "@", query: "ca", start: 4, end: 7})
  assert.deepEqual(triggerOf("ask\n@ca", 7), {trigger: "@", query: "ca", start: 4, end: 7})
  assert.equal(triggerOf("mail a@b", 8), null)
  assert.equal(triggerOf("ask @ca done", 12), null)
})

test("only the text before the caret counts", () => {
  assert.deepEqual(triggerOf("@carlos and more", 3), {trigger: "@", query: "ca", start: 0, end: 3})
  assert.equal(triggerOf("", 0), null)
})

test("choosing a suggestion replaces the typed word and leaves the caret after it", () => {
  const token = triggerOf("ask @ca please", 7)
  assert.deepEqual(applyPick("ask @ca please", token, "@carlos"), {text: "ask @carlos  please", caret: 12})
  assert.deepEqual(applyPick("/re", triggerOf("/re", 3), "/review"), {text: "/review ", caret: 8})
})

test("the arrows move the highlight round the list and other keys leave it", () => {
  assert.equal(moveActive(0, "ArrowDown", 3), 1)
  assert.equal(moveActive(2, "ArrowDown", 3), 0)
  assert.equal(moveActive(0, "ArrowUp", 3), 2)
  assert.equal(moveActive(1, "a", 3), 1)
  assert.equal(moveActive(0, "ArrowDown", 0), 0)
})

test("Enter and Space activate a label drawn as a button, other keys do not", () => {
  assert.equal(activatesButton({key: "Enter"}), true)
  assert.equal(activatesButton({key: " "}), true)
  assert.equal(activatesButton({key: "a"}), false)
  assert.equal(activatesButton({key: "Tab"}), false)
})
