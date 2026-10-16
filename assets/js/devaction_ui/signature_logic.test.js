import test from "node:test"
import assert from "node:assert/strict"
import {round, signaturePath, statusText, strokePath, toPoint, toSvg} from "./signature_logic.js"

test("round keeps one decimal", () => {
  assert.equal(round(12.3456), 12.3)
})

test("toPoint scales a pointer to the drawing", () => {
  const box = {left: 10, top: 20, width: 200, height: 100}
  assert.deepEqual(toPoint({clientX: 110, clientY: 70}, box), [180, 85])
})

test("a stroke is a move and lines; a touch is a dot; nothing is empty", () => {
  assert.equal(strokePath([[1, 2], [3, 4]]), "M1 2 L3 4")
  assert.equal(strokePath([[7, 8]]), "M7 8 L7 8")
  assert.equal(strokePath([]), "")
  assert.equal(signaturePath([[[1, 2], [3, 4]], [[9, 9]]]), "M1 2 L3 4 M9 9 L9 9")
})

test("the svg is the drawing and nothing when there is none", () => {
  assert.equal(toSvg(""), null)
  const svg = toSvg("M1 2 L3 4")
  assert.match(svg, /^<svg xmlns="http:\/\/www.w3.org\/2000\/svg" viewBox="0 0 360 170">/)
  assert.match(svg, /d="M1 2 L3 4"/)
  assert.match(svg, /stroke="#18181B" stroke-width="2.2"/)
})

test("the svg takes the colour the caller asks for", () => {
  assert.match(toSvg("M1 2 L3 4", "#FFFFFF"), /stroke="#FFFFFF"/)
  assert.match(toSvg("M1 2 L3 4", "currentColor"), /stroke="currentColor"/)
})

test("the status says empty until there is a stroke", () => {
  const texts = {empty: "Empty", ready: "Ready"}
  assert.equal(statusText([], texts), "Empty")
  assert.equal(statusText([[[1, 2]]], texts), "Ready")
  assert.equal(statusText([], {}), "")
})
