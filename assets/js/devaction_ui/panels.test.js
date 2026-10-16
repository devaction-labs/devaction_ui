import test from "node:test"
import assert from "node:assert/strict"
import {CookieConsent, focusAfter, NotificationCenter, stepTo, zoneOf} from "./panels.js"

test("the vertical arrows step through the notifications and wrap", () => {
  assert.equal(stepTo("ArrowDown", 0, 3, "vertical"), 1)
  assert.equal(stepTo("ArrowDown", 2, 3, "vertical"), 0)
  assert.equal(stepTo("ArrowUp", 0, 3, "vertical"), 2)
  assert.equal(stepTo("End", 0, 3, "vertical"), 2)
  assert.equal(stepTo("Home", 2, 3, "vertical"), 0)
})

test("the horizontal arrows step through the tabs, the vertical ones do not", () => {
  assert.equal(stepTo("ArrowRight", 0, 3, "horizontal"), 1)
  assert.equal(stepTo("ArrowDown", 0, 3, "horizontal"), null)
  assert.equal(stepTo("ArrowDown", 0, 0, "vertical"), null)
})

test("a target is in the zone of a notification or of a tab, or in none", () => {
  const inside = (hit) => ({closest: (selector) => (selector === hit ? {} : null)})

  assert.equal(zoneOf(inside("[data-notification]"))[0], "[data-notification]")
  assert.equal(zoneOf(inside('[role="tab"]'))[1].orientation, "horizontal")
  assert.equal(zoneOf(inside("nothing")), undefined)
})

test("the focus moves to the first switch when the preferences open from their button", () => {
  assert.equal(focusAfter({was: false, now: true, triggerFocused: true, lost: false}), "first")
  assert.equal(focusAfter({was: false, now: true, triggerFocused: false, lost: false}), null)
})

test("the focus returns to the button when the preferences close and it was lost", () => {
  assert.equal(focusAfter({was: true, now: false, triggerFocused: false, lost: true}), "trigger")
  assert.equal(focusAfter({was: true, now: false, triggerFocused: true, lost: false}), null)
  assert.equal(focusAfter({was: true, now: true, triggerFocused: false, lost: true}), null)
})

test("Esc presses the preferences button only while the categories are open", () => {
  const clicks = []
  const hook = {
    ...CookieConsent,
    el: {dataset: {open: "true"}, querySelector: () => ({click: () => clicks.push("click")})},
  }

  assert.equal(hook.closeCategories(), true)
  hook.el.dataset.open = "false"
  assert.equal(hook.closeCategories(), false)
  assert.deepEqual(clicks, ["click"])
})

test("focusing past the end of the list declines the key", () => {
  const focused = []
  const items = [{focus: () => focused.push(0)}]

  assert.equal(NotificationCenter.focusAt(items, 0), true)
  assert.equal(NotificationCenter.focusAt(items, null), false)
  assert.deepEqual(focused, [0])
})
