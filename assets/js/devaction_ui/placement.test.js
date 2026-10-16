import test from "node:test"
import assert from "node:assert/strict"
import {arrowShift, chooseSide, clampShift, fixedCorner, flipSide, placeAtPoint, placeTip, submenuSide} from "./placement.js"

test("it opens where asked when there is room", () => {
  assert.equal(chooseSide("bottom", {panel: 200, above: 100, below: 400}), "bottom")
  assert.equal(chooseSide("top", {panel: 200, above: 400, below: 100}), "top")
})

test("it flips when the asked side is too short and the other has more room", () => {
  assert.equal(chooseSide("bottom", {panel: 200, above: 500, below: 100}), "top")
  assert.equal(chooseSide("top", {panel: 200, above: 100, below: 500}), "bottom")
})

test("it stays when both sides are short and the other is no better", () => {
  assert.equal(chooseSide("bottom", {panel: 400, above: 100, below: 150}), "bottom")
})

const room = (top, bottom, left, right) => ({top, bottom, left, right})
const panel = {width: 320, height: 200}

test("a side placement flips by the width of the panel", () => {
  assert.equal(flipSide("right", panel, room(0, 0, 100, 600)), "right")
  assert.equal(flipSide("right", panel, room(0, 0, 600, 100)), "left")
  assert.equal(flipSide("left", panel, room(0, 0, 100, 600)), "right")
  assert.equal(flipSide("left", panel, room(0, 0, 100, 90)), "left")
})

test("a panel inside the screen is not shifted", () => {
  assert.equal(clampShift(100, 320, 1000), 0)
})

test("a panel past the right edge is pulled back with a margin", () => {
  assert.equal(clampShift(800, 320, 1000), -128)
})

test("a panel past the left edge is pushed in, and the start wins when it is wider than the screen", () => {
  assert.equal(clampShift(-40, 320, 1000), 48)
  assert.equal(clampShift(10, 600, 400), -2)
})

test("the arrow moves back so it still points at the trigger", () => {
  assert.equal(arrowShift(-100, {center: 40, size: 320}), 100)
  assert.equal(arrowShift(0, {center: 40, size: 320}), 0)
})

test("the arrow never leaves the panel", () => {
  assert.equal(arrowShift(-400, {center: 40, size: 320}), 264)
  assert.equal(arrowShift(100, {center: 40, size: 320}), -24)
})

test("a fixed panel sits under the trigger, aligned to its start or its end", () => {
  const anchor = {left: 100, right: 180, top: 50, bottom: 90}
  const screen = {width: 1000, height: 800}
  assert.deepEqual(fixedCorner({side: "bottom", align: "start", anchor, panel, screen}), {top: 96, left: 100, shiftX: 0, shiftY: 0})
  assert.deepEqual(fixedCorner({side: "bottom", align: "end", anchor, panel, screen}), {top: 96, left: 8, shiftX: 148, shiftY: 0})
})

test("a fixed panel above the trigger rises by its own height", () => {
  const anchor = {left: 100, right: 180, top: 400, bottom: 440}
  const corner = fixedCorner({side: "top", align: "start", anchor, panel, screen: {width: 1000, height: 800}})
  assert.equal(corner.top, 400 - 6 - 200)
})

test("a fixed panel beside the trigger is shifted vertically, never horizontally", () => {
  const anchor = {left: 100, right: 180, top: 700, bottom: 740}
  const corner = fixedCorner({side: "right", align: "start", anchor, panel, screen: {width: 1000, height: 800}})
  assert.equal(corner.left, 186)
  assert.equal(corner.shiftX, 0)
  assert.equal(corner.shiftY, 800 - 8 - (700 + 200))
  assert.equal(corner.top, 700 + corner.shiftY)
})

test("a fixed panel wider than the room right of the trigger is pulled back inside", () => {
  const anchor = {left: 800, right: 980, top: 50, bottom: 90}
  const corner = fixedCorner({side: "bottom", align: "start", anchor, panel, screen: {width: 1000, height: 800}})
  assert.equal(corner.left + panel.width, 1000 - 8)
  assert.equal(corner.shiftX, -128)
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

test("a submenu stays on its side when it fits", () => {
  assert.equal(submenuSide("right", {panel: 236, left: 100, right: 400}), "right")
  assert.equal(submenuSide("left", {panel: 236, left: 400, right: 100}), "left")
})

test("a submenu goes to the other side when it does not fit and the other has more room", () => {
  assert.equal(submenuSide("right", {panel: 236, left: 500, right: 100}), "left")
  assert.equal(submenuSide("left", {panel: 236, left: 100, right: 500}), "right")
})

test("a submenu stays when neither side has room", () => {
  assert.equal(submenuSide("right", {panel: 236, left: 50, right: 100}), "right")
})


test("placeAtPoint opens at the point when the panel fits", () => {
  assert.deepEqual(placeAtPoint({x: 100, y: 50}, {width: 200, height: 300}, {width: 1000, height: 800}), {left: 100, top: 50})
})

test("placeAtPoint opens to the left and upwards when the panel would leave the screen", () => {
  assert.deepEqual(placeAtPoint({x: 900, y: 700}, {width: 200, height: 300}, {width: 1000, height: 800}), {left: 700, top: 400})
})

test("placeAtPoint never leaves the screen, even when the panel is larger than it", () => {
  assert.deepEqual(placeAtPoint({x: 20, y: 20}, {width: 2000, height: 2000}, {width: 1000, height: 800}), {left: 8, top: 8})
  assert.deepEqual(placeAtPoint({x: 5, y: 790}, {width: 200, height: 2000}, {width: 1000, height: 800}), {left: 8, top: 8})
})
