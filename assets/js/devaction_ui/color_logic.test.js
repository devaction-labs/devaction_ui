import test from "node:test"
import assert from "node:assert/strict"
import {clamp, fill, hexToHsv, hsvToHex, nudged, pointToSv, withAlpha} from "./color_logic.js"

test("a hex colour goes to hsv and back unchanged", () => {
  for (const hex of ["#2563EB", "#DC2626", "#16A34A", "#FFFFFF", "#000000", "#D29A1E"]) {
    const {h, s, v} = hexToHsv(hex)
    assert.equal(hsvToHex(h, s, v), hex)
  }
})

test("the primaries have their hue", () => {
  assert.equal(hexToHsv("#FF0000").h, 0)
  assert.equal(Math.round(hexToHsv("#00FF00").h), 120)
  assert.equal(Math.round(hexToHsv("#0000FF").h), 240)
})

test("grey has no saturation and black has no value", () => {
  assert.equal(hexToHsv("#808080").s, 0)
  assert.equal(hexToHsv("#000000").v, 0)
})

test("the hash is optional and the case does not matter", () => {
  assert.deepEqual(hexToHsv("2563eb"), hexToHsv("#2563EB"))
})

test("what is not a colour is null", () => {
  assert.equal(hexToHsv("blue"), null)
  assert.equal(hexToHsv("#12345"), null)
  assert.equal(hexToHsv(""), null)
})

test("the alpha is read from the last two digits", () => {
  assert.equal(hexToHsv("#2563EB").a, 100)
  assert.equal(hexToHsv("#2563EB80").a, 50)
  assert.equal(hexToHsv("#2563EB00").a, 0)
})

test("an opaque colour keeps its six digits and a translucent one gets two more", () => {
  assert.equal(withAlpha("#2563EB", 100), "#2563EB")
  assert.equal(withAlpha("#2563EB", 50), "#2563EB80")
  assert.equal(withAlpha("#2563EB", 0), "#2563EB00")
})

test("clamp keeps a number inside its ends", () => {
  assert.equal(clamp(5, 0, 1), 1)
  assert.equal(clamp(-5, 0, 1), 0)
  assert.equal(clamp(0.4, 0, 1), 0.4)
})

test("a template is filled by name and an unknown name is empty", () => {
  assert.equal(fill("%{color}, saturation %{saturation}%", {color: "#FFF", saturation: 40}), "#FFF, saturation 40%")
  assert.equal(fill("a %{missing} b", {}), "a  b")
})

test("a pointer in the square gives saturation to the right and value to the top, kept inside the box", () => {
  const box = {left: 100, top: 50, width: 200, height: 100}
  assert.deepEqual(pointToSv({clientX: 100, clientY: 150}, box), {s: 0, v: 0})
  assert.deepEqual(pointToSv({clientX: 300, clientY: 50}, box), {s: 1, v: 1})
  assert.deepEqual(pointToSv({clientX: 200, clientY: 100}, box), {s: 0.5, v: 0.5})
  assert.deepEqual(pointToSv({clientX: -50, clientY: 900}, box), {s: 0, v: 0})
})

test("an arrow moves one channel and stops at the edge", () => {
  assert.deepEqual(nudged({s: 0.5, v: 0.5}, "s", 0.1), {s: 0.6})
  assert.deepEqual(nudged({s: 0.99, v: 0.5}, "s", 0.1), {s: 1})
  assert.deepEqual(nudged({s: 0.5, v: 0.01}, "v", -0.1), {v: 0})
})
