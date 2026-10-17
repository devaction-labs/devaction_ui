import assert from "node:assert/strict"
import test from "node:test"
import {buttonText, canCreate, fill, keeps, pick, placePanel} from "./listbox_logic.js"

test("fill replaces every marker and leaves nothing as nothing", () => {
  assert.equal(fill("Create “%{term}”", {term: "Design"}), "Create “Design”")
  assert.equal(fill("%{count} of %{count}", {count: 3}), "3 of 3")
  assert.equal(fill(null, {term: "x"}), null)
})

test("the search looks at the label and the keywords, ignoring accents", () => {
  assert.equal(keeps({label: "Infraestrutura", keywords: "devops servidor"}, "servidor"), true)
  assert.equal(keeps({label: "Gestão"}, "gestao"), true)
  assert.equal(keeps({label: "Produto"}, "zz"), false)
  assert.equal(keeps({label: "Produto"}, "  "), true)
})

test("create shows for a new term only", () => {
  assert.equal(canCreate("", ["Fruit"]), false)
  assert.equal(canCreate("fruit ", ["Fruit"]), false)
  assert.equal(canCreate("Design", ["Fruit"]), true)
})

test("a single choice replaces, a multiple one toggles", () => {
  assert.deepEqual(pick(["a"], "b", false), ["b"])
  assert.deepEqual(pick(["a"], "b", true), ["a", "b"])
  assert.deepEqual(pick(["a", "b"], "a", true), ["b"])
})

test("the button shows the placeholder, the label, the count or the labels", () => {
  assert.deepEqual(buttonText({labels: [], multiple: false, placeholder: "Pick"}), {text: "Pick", muted: true})
  assert.deepEqual(buttonText({labels: ["Fruit"], multiple: false, placeholder: "Pick"}), {text: "Fruit", muted: false})
  assert.deepEqual(buttonText({labels: ["A", "B"], multiple: true, placeholder: "Pick", countText: "%{count} chosen"}), {
    text: "2 chosen",
    muted: false,
  })
  assert.deepEqual(buttonText({labels: ["A", "B"], multiple: true, placeholder: "Pick"}), {text: "A, B", muted: false})
})

const screen = {width: 1000, height: 800}
const anchorAt = (top, left = 100, width = 300) => ({top, bottom: top + 44, left, right: left + width, width})
const panel = {width: 300, height: 360}

test("the panel opens below the button when there is room", () => {
  const spot = placePanel({anchor: anchorAt(100), panel, chrome: 44, screen, wanted: "bottom", align: "start"})
  assert.deepEqual([spot.side, spot.top, spot.bottom, spot.left, spot.edge], ["bottom", 150, null, 100, 150])
})

test("the panel flips above when below is short and above has more", () => {
  const spot = placePanel({anchor: anchorAt(600), panel, chrome: 44, screen, wanted: "bottom", align: "start"})
  assert.deepEqual([spot.side, spot.top, spot.bottom, spot.edge], ["top", null, 206, 594])
})

test("the panel stays where it was wanted when the other side is no better", () => {
  const spot = placePanel({anchor: anchorAt(10), panel: {...panel, height: 900}, chrome: 44, screen, wanted: "top", align: "start"})
  assert.equal(spot.side, "bottom")
  const kept = placePanel({anchor: anchorAt(300), panel: {...panel, height: 900}, chrome: 44, screen, wanted: "bottom", align: "start"})
  assert.equal(kept.side, "bottom")
})

test("the list is shortened to the room of the side chosen, never below a least height", () => {
  const spot = placePanel({anchor: anchorAt(100), panel: {...panel, height: 900}, chrome: 50, screen, wanted: "bottom", align: "start"})
  assert.equal(spot.list, 800 - 144 - 6 - 8 - 50)
  const tight = placePanel({anchor: anchorAt(100), panel, chrome: 50, screen: {width: 1000, height: 200}, wanted: "bottom", align: "start"})
  assert.equal(tight.list, 96)
})

test("the panel lines up with the end of the button and stays inside the screen", () => {
  const end = placePanel({anchor: anchorAt(100, 500, 200), panel: {width: 400, height: 200}, chrome: 44, screen, wanted: "bottom", align: "end"})
  assert.equal(end.left, 300)
  const pushed = placePanel({anchor: anchorAt(100, 20, 100), panel: {width: 400, height: 200}, chrome: 44, screen, wanted: "bottom", align: "end"})
  assert.equal(pushed.left, 8)
  const over = placePanel({anchor: anchorAt(100, 900, 80), panel: {width: 300, height: 200}, chrome: 44, screen, wanted: "bottom", align: "start"})
  assert.equal(over.left, 692)
})
