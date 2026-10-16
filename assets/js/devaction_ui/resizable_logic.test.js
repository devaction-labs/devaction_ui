import assert from "node:assert/strict"
import test from "node:test"
import {dividerEnd, dividerKey, dividerValues, limit, moveDivider, pixelsToPercent, resetDivider, startSizes} from "./resizable_logic.js"

const open = [
  {min: 0, max: 100},
  {min: 0, max: 100},
]

test("a divider gives what one panel gains to the other, and the total stays", () => {
  assert.deepEqual(moveDivider([58, 42], 0, 10, open), [68, 32])
  assert.deepEqual(moveDivider([58, 42], 0, -8, open), [50, 50])
})

test("a divider stops at the limits of both panels", () => {
  const limits = [
    {min: 20, max: 70},
    {min: 25, max: 100},
  ]
  assert.deepEqual(moveDivider([58, 42], 0, 50, limits), [70, 30])
  assert.deepEqual(moveDivider([58, 42], 0, -50, limits), [20, 80])
  assert.deepEqual(
    moveDivider([30, 70], 0, 60, [
      {min: 0, max: 100},
      {min: 40, max: 100},
    ]),
    [60, 40],
  )
})

test("only the two panels around the divider change", () => {
  const limits = [...open, {min: 0, max: 100}]
  assert.deepEqual(moveDivider([30, 30, 40], 1, 5, limits), [30, 35, 35])
})

test("a double click shares the two panels equally", () => {
  assert.deepEqual(resetDivider([58, 42], 0, open), [50, 50])
  assert.deepEqual(resetDivider([20, 30, 50], 1, [...open, {min: 0, max: 100}]), [20, 40, 40])
})

test("pixels turn into percent of the room the panels share", () => {
  assert.equal(pixelsToPercent(50, 500), 10)
  assert.equal(pixelsToPercent(50, 0), 0)
})

test("the arrows of the axis move by a step, Shift by a larger one, and Home and End go to the ends", () => {
  assert.deepEqual(dividerKey("ArrowRight", false, "horizontal"), {delta: 2})
  assert.deepEqual(dividerKey("ArrowLeft", true, "horizontal"), {delta: -10})
  assert.deepEqual(dividerKey("ArrowDown", false, "vertical"), {delta: 2})
  assert.deepEqual(dividerKey("Home", false, "horizontal"), {to: "min"})
  assert.equal(dividerKey("ArrowUp", false, "horizontal"), undefined)
  assert.equal(dividerKey("a", false, "vertical"), undefined)
})

test("Home and End put the divider at the ends the limits allow", () => {
  const limits = [
    {min: 20, max: 80},
    {min: 10, max: 100},
  ]
  assert.deepEqual(dividerEnd([50, 50], 0, limits, "min"), [20, 80])
  assert.deepEqual(dividerEnd([50, 50], 0, limits, "max"), [80, 20])
})

test("the divider reports its value and the limits the other panel leaves it", () => {
  const limits = [
    {min: 20, max: 80},
    {min: 10, max: 100},
  ]
  assert.deepEqual(dividerValues([58, 42], 0, limits), {now: 58, min: 20, max: 80})
  assert.deepEqual(
    dividerValues([58, 42], 0, [
      {min: 0, max: 100},
      {min: 30, max: 100},
    ]),
    {now: 58, min: 0, max: 70},
  )
})

test("the sizes come from the page, or are shared equally", () => {
  assert.deepEqual(startSizes(["58", "42"]), [58, 42])
  assert.deepEqual(startSizes([undefined, undefined, undefined]), [33.33, 33.33, 33.33])
  assert.equal(limit("15", 0), 15)
  assert.equal(limit(undefined, 100), 100)
})
