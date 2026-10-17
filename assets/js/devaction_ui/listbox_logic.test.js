import assert from "node:assert/strict"
import test from "node:test"
import {buttonText, canCreate, fill, keeps, pick} from "./listbox_logic.js"

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
