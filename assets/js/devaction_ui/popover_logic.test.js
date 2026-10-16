import test from "node:test"
import assert from "node:assert/strict"
import {arrowShift, chooseSide, clampShift, fixedCorner, flipSide, tabExit} from "./popover_logic.js"

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

test("Tab at the last control leaves forward, Shift+Tab at the first returns to the trigger", () => {
  const ends = {first: "a", last: "z"}
  assert.equal(tabExit({shift: false, active: "z", ...ends}), "forward")
  assert.equal(tabExit({shift: true, active: "a", ...ends}), "back")
  assert.equal(tabExit({shift: false, active: "m", ...ends}), null)
  assert.equal(tabExit({shift: true, active: "m", ...ends}), null)
})
