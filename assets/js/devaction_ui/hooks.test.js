import assert from "node:assert/strict"
import test from "node:test"

globalThis.MutationObserver ??= class {
  observe() {}
  disconnect() {}
}

const {hooks} = await import("./index.js")

test("a hook is made of methods only, because LiveView copies a getter by calling it with no element", () => {
  const accessors = Object.entries(hooks).flatMap(([name, hook]) =>
    Object.entries(Object.getOwnPropertyDescriptors(hook))
      .filter(([, descriptor]) => descriptor.get || descriptor.set)
      .map(([property]) => `${name}.${property}`),
  )

  assert.deepEqual(accessors, [])
})
