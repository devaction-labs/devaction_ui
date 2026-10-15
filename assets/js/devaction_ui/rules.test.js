import test from "node:test"
import assert from "node:assert/strict"
import {decide} from "./rules.js"

test("the first rule whose test passes decides, with the arguments given", () => {
  const rules = [
    [(n) => n < 0, () => "negative"],
    [(n) => n === 0, () => "zero"],
    [() => true, (n) => `positive ${n}`],
  ]
  assert.equal(decide(rules, -3), "negative")
  assert.equal(decide(rules, 0), "zero")
  assert.equal(decide(rules, 7), "positive 7")
})
