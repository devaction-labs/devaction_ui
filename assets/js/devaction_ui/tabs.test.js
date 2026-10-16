import test from "node:test"
import assert from "node:assert/strict"
import {resolveSelection} from "./tabs.js"

const ids = ["a", "b", "c"]

test("the tab the person chose survives a patch that leaves the server's selection alone", () => {
  assert.deepEqual(resolveSelection({chosen: "c", lastServer: "a", server: "a", ids}), {
    selected: "c",
    chosen: "c",
    lastServer: "a",
  })
})

test("a changed server selection wins over the person's choice", () => {
  assert.deepEqual(resolveSelection({chosen: "c", lastServer: "a", server: "b", ids}), {
    selected: "b",
    chosen: "",
    lastServer: "b",
  })
})

test("with no choice the server's selection stands", () => {
  assert.deepEqual(resolveSelection({chosen: "", lastServer: "a", server: "a", ids}), {
    selected: "a",
    chosen: "",
    lastServer: "a",
  })
})

test("a chosen tab that no longer exists falls back to the server's", () => {
  assert.deepEqual(resolveSelection({chosen: "z", lastServer: "a", server: "a", ids}), {
    selected: "a",
    chosen: "",
    lastServer: "a",
  })
})
