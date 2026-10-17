import test from "node:test"
import assert from "node:assert/strict"
import {choosable, isTypeKey, moveActive, placePanel, readItems, startIndex, typeAhead, typedText} from "./select_logic.js"

const opt = (value, label, extra = {}) => ({tagName: "OPTION", value, label, text: label, disabled: false, selected: false, ...extra})
const group = (label, children, extra = {}) => ({tagName: "OPTGROUP", label, children, disabled: false, ...extra})

const select = {
  children: [
    opt("", "Choose"),
    group("Team", [opt("dev", "Developer", {selected: true}), opt("pm", "Product manager")]),
    group("Client", [opt("owner", "Owner"), opt("ro", "Read only", {disabled: true})]),
  ],
}

test("readItems lists groups and options with the index each option has in the select", () => {
  const items = readItems(select)
  assert.deepEqual(
    items.map((item) => [item.kind, item.label, item.position]),
    [
      ["option", "Choose", 0],
      ["group", "Team", undefined],
      ["option", "Developer", 1],
      ["option", "Product manager", 2],
      ["group", "Client", undefined],
      ["option", "Owner", 3],
      ["option", "Read only", 4],
    ],
  )
  assert.equal(items[2].selected, true)
  assert.equal(items[6].disabled, true)
})

test("an option of a disabled group is disabled", () => {
  const items = readItems({children: [group("Off", [opt("a", "A")], {disabled: true})]})
  assert.equal(items[1].disabled, true)
})

test("choosable skips groups and disabled options", () => {
  assert.deepEqual(choosable(readItems(select)), [0, 2, 3, 5])
})

test("the panel starts on the chosen option, else the first choosable, else nothing", () => {
  const items = readItems(select)
  assert.equal(startIndex(items), 2)
  assert.equal(startIndex(items.map((item) => ({...item, selected: false}))), 0)
  assert.equal(startIndex([]), -1)
})

test("arrows skip groups and disabled options and stop at the ends", () => {
  const items = readItems(select)
  assert.equal(moveActive(items, 3, "ArrowDown"), 5)
  assert.equal(moveActive(items, 5, "ArrowDown"), 5)
  assert.equal(moveActive(items, 5, "ArrowUp"), 3)
  assert.equal(moveActive(items, 0, "ArrowUp"), 0)
  assert.equal(moveActive(items, -1, "ArrowDown"), 0)
  assert.equal(moveActive(items, 3, "Home"), 0)
  assert.equal(moveActive(items, 0, "End"), 5)
  assert.equal(moveActive(items, 3, "x"), 3)
})

test("typed letters continue a word only inside the window", () => {
  assert.deepEqual(typedText({text: "d", at: 1000}, "e", 1300), {text: "de", at: 1300})
  assert.deepEqual(typedText({text: "d", at: 1000}, "o", 2000), {text: "o", at: 2000})
})

test("a space types only inside a word, and modifiers do not type", () => {
  const key = (key, extra = {}) => ({key, ...extra})
  assert.equal(isTypeKey(key("a"), {text: "", at: 0}, 5000), true)
  assert.equal(isTypeKey(key(" "), {text: "", at: 0}, 5000), false)
  assert.equal(isTypeKey(key(" "), {text: "p", at: 4800}, 5000), true)
  assert.equal(isTypeKey(key("a", {ctrlKey: true}), {text: "", at: 0}, 5000), false)
  assert.equal(isTypeKey(key("ArrowDown"), {text: "", at: 0}, 5000), false)
})

test("a word leads to the next label that starts with it, a repeated letter cycles", () => {
  const items = readItems(select)
  assert.equal(typeAhead(items, 2, "pr"), 3)
  assert.equal(typeAhead(items, 2, "o"), 5)
  assert.equal(typeAhead(items, 5, "o"), 5)
  assert.equal(typeAhead(items, 2, "zz"), 2)
  const twins = readItems({children: [opt("1", "Apple"), opt("2", "Avocado")]})
  assert.equal(typeAhead(twins, 0, "aa"), 1)
  assert.equal(typeAhead(twins, 1, "aa"), 0)
})

test("the panel opens under the trigger, as wide as it", () => {
  const anchor = {left: 100, right: 400, top: 100, bottom: 144, width: 300}
  assert.deepEqual(placePanel({anchor, height: 200, screen: {width: 1000, height: 800}}), {
    side: "bottom",
    top: 150,
    left: 100,
    width: 300,
    maxHeight: 320,
  })
})

test("the panel flips above when there is no room below and more above", () => {
  const anchor = {left: 100, right: 400, top: 700, bottom: 744, width: 300}
  const placed = placePanel({anchor, height: 200, screen: {width: 1000, height: 800}})
  assert.equal(placed.side, "top")
  assert.equal(placed.top, 700 - 6 - 200)
})

test("a tall list is capped by the room it has", () => {
  const anchor = {left: 0, right: 300, top: 100, bottom: 144, width: 300}
  assert.equal(placePanel({anchor, height: 600, screen: {width: 1000, height: 1000}}).maxHeight, 320)
  assert.equal(placePanel({anchor, height: 600, screen: {width: 1000, height: 300}}).side, "bottom")
  assert.equal(placePanel({anchor, height: 600, screen: {width: 1000, height: 300}}).maxHeight, 300 - 144 - 6 - 8)
})

test("the panel stays inside the screen sideways", () => {
  const anchor = {left: 800, right: 1100, top: 100, bottom: 144, width: 300}
  assert.equal(placePanel({anchor, height: 100, screen: {width: 1000, height: 800}}).left, 692)
})
