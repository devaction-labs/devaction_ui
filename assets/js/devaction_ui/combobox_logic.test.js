import test from "node:test"
import assert from "node:assert/strict"
import {buttonView} from "./combobox_logic.js"

test("a chosen option shows its label, not muted", () => {
  assert.deepEqual(buttonView({label: "Hub"}, "Choose"), {text: "Hub", muted: false})
})

test("nothing chosen shows the placeholder, muted", () => {
  assert.deepEqual(buttonView(null, "Choose"), {text: "Choose", muted: true})
  assert.deepEqual(buttonView(undefined, "Choose"), {text: "Choose", muted: true})
})

test("an option with an empty label is still a choice", () => {
  assert.deepEqual(buttonView({label: ""}, "Choose"), {text: "", muted: false})
})
