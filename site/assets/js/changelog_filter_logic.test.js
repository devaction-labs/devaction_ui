import test from "node:test"
import assert from "node:assert/strict"
import {matches, plan} from "./changelog_filter_logic.js"

test("all matches every kind and a kind matches only itself", () => {
  assert.equal(matches("all", "new"), true)
  assert.equal(matches("new", "new"), true)
  assert.equal(matches("new", "planned"), false)
})

test("a group shows the count of the rows that match and hides when none does", () => {
  const releases = [[["planned", "planned"]], [["new", "new", "new"], ["new"]]]
  const [next, current] = plan("planned", releases)
  assert.deepEqual(next.groups, [{count: 2, visible: true}])
  assert.equal(next.empty, false)
  assert.deepEqual(current.groups, [{count: 0, visible: false}, {count: 0, visible: false}])
  assert.equal(current.empty, true)
})

test("all keeps every group and no release is empty", () => {
  const [release] = plan("all", [[["new"], ["fixed", "new"]]])
  assert.deepEqual(release.groups.map((g) => g.count), [1, 2])
  assert.equal(release.empty, false)
})

test("a release with no groups is empty", () => {
  assert.equal(plan("all", [[]])[0].empty, true)
})
