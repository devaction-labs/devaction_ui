import assert from "node:assert/strict"
import test from "node:test"
import {expanded, isToggleKey, otherState, pageInert, parseGroups, stateCookie, stateOf, toggleLabel, withGroup} from "./shell_logic.js"

test("toggling goes from open to rail and back", () => {
  assert.equal(otherState("open"), "rail")
  assert.equal(otherState("rail"), "open")
})

test("only rail means rail", () => {
  assert.equal(stateOf("rail"), "rail")
  assert.equal(stateOf("open"), "open")
  assert.equal(stateOf(undefined), "open")
})

test("the cookie lasts a year and is read by the server", () => {
  assert.equal(stateCookie("rail"), "dui_sidebar=rail; path=/; max-age=31536000; samesite=lax")
  assert.equal(stateCookie("open", "x"), "x=open; path=/; max-age=31536000; samesite=lax")
})

test("Cmd+B and Ctrl+B toggle, any other key does not", () => {
  assert.equal(isToggleKey({key: "b", metaKey: true}), true)
  assert.equal(isToggleKey({key: "B", ctrlKey: true}), true)
  assert.equal(isToggleKey({key: "b"}), false)
  assert.equal(isToggleKey({key: "k", ctrlKey: true}), false)
  assert.equal(isToggleKey({key: "b", ctrlKey: true, altKey: true}), false)
})

test("a text area and an editor keep Ctrl+B for bold, unless Shift is held", () => {
  assert.equal(isToggleKey({key: "b", ctrlKey: true}, {tagName: "TEXTAREA"}), false)
  assert.equal(isToggleKey({key: "b", ctrlKey: true}, {isContentEditable: true}), false)
  assert.equal(isToggleKey({key: "b", ctrlKey: true, shiftKey: true}, {tagName: "TEXTAREA"}), true)
  assert.equal(isToggleKey({key: "b", ctrlKey: true}, {tagName: "INPUT"}), true)
})

test("expanded is the drawer on a small screen and the full sidebar on a large one", () => {
  assert.equal(expanded({mobile: true, drawerOpen: true, state: "rail"}), true)
  assert.equal(expanded({mobile: true, drawerOpen: false, state: "open"}), false)
  assert.equal(expanded({mobile: false, drawerOpen: false, state: "open"}), true)
  assert.equal(expanded({mobile: false, drawerOpen: true, state: "rail"}), false)
})

test("the toggle offers to close what is open", () => {
  const labels = {open: "Open menu", close: "Collapse menu"}
  assert.equal(toggleLabel(true, labels), "Collapse menu")
  assert.equal(toggleLabel(false, labels), "Open menu")
})

test("the groups memory survives garbage", () => {
  assert.deepEqual(parseGroups('{"work":false,"team":true}'), {work: false, team: true})
  assert.deepEqual(parseGroups('{"work":"no"}'), {})
  assert.deepEqual(parseGroups("nope"), {})
  assert.deepEqual(parseGroups(null), {})
})

test("setting a group keeps the others", () => {
  assert.deepEqual(withGroup({a: true}, "b", false), {a: true, b: false})
  assert.deepEqual(withGroup({a: true}, "a", false), {a: false})
})

test("the page behind is inert only while the drawer of a small screen is open", () => {
  assert.equal(pageInert({mobile: true, drawerOpen: true}), true)
  assert.equal(pageInert({mobile: true, drawerOpen: false}), false)
  assert.equal(pageInert({mobile: false, drawerOpen: true}), false)
})
