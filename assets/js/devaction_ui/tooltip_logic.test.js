import test from "node:test"
import assert from "node:assert/strict"
import {dismissesOnTap, placeTip, withDescription} from "./tooltip_logic.js"

test("a control with no description gets the tooltip's id", () => {
  assert.equal(withDescription(null, "t-tip"), "t-tip")
  assert.equal(withDescription("", "t-tip"), "t-tip")
})

test("the descriptions it already had are kept", () => {
  assert.equal(withDescription("hint", "t-tip"), "hint t-tip")
  assert.equal(withDescription("  a   b ", "t-tip"), "a b t-tip")
})

test("the id is never added twice", () => {
  assert.equal(withDescription("t-tip", "t-tip"), "t-tip")
  assert.equal(withDescription("a t-tip", "t-tip"), "a t-tip")
})

const viewport = {width: 1000, height: 800}
const at = (left, top, size = 40) => ({left, top, right: left + size, bottom: top + size})
const tip = {width: 100, height: 30}

test("a hint with room stays on the side asked for, centered", () => {
  assert.deepEqual(placeTip("top", {tip, trigger: at(480, 400), viewport}), {side: "top", shift: 0, arrow: 0})
})

test("a hint with no room on its side flips to the opposite one, when that has more", () => {
  assert.equal(placeTip("top", {tip, trigger: at(480, 10), viewport}).side, "bottom")
  assert.equal(placeTip("left", {tip, trigger: at(20, 400), viewport}).side, "right")
  assert.equal(placeTip("bottom", {tip, trigger: at(480, 760), viewport}).side, "top")
  assert.equal(placeTip("right", {tip, trigger: at(940, 400), viewport}).side, "left")
})

test("it does not flip when the other side is no better", () => {
  const short = {width: 1000, height: 40}
  assert.equal(placeTip("top", {tip: {width: 100, height: 60}, trigger: at(480, 10), viewport: short}).side, "top")
})

test("a hint that would leave the screen is pushed back and the arrow goes the other way", () => {
  assert.deepEqual(placeTip("top", {tip, trigger: at(0, 400), viewport}), {side: "top", shift: 38, arrow: -38})
  assert.deepEqual(placeTip("bottom", {tip, trigger: at(960, 400), viewport}), {side: "bottom", shift: -38, arrow: 38})
})

test("on the left and right the hint is pushed along the vertical edge", () => {
  assert.deepEqual(placeTip("left", {tip, trigger: at(500, 0), viewport}), {side: "left", shift: 3, arrow: -3})
})

test("the arrow never leaves the hint", () => {
  assert.equal(placeTip("top", {tip, trigger: at(-200, 400, 10), viewport}).arrow, -38)
})

test("a touch dismisses the hint, a mouse or a pen does not", () => {
  assert.equal(dismissesOnTap("touch"), true)
  assert.equal(dismissesOnTap("mouse"), false)
  assert.equal(dismissesOnTap("pen"), false)
  assert.equal(dismissesOnTap(undefined), false)
})
