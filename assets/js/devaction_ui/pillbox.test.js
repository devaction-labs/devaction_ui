import test from "node:test"
import assert from "node:assert/strict"
import Pillbox from "./pillbox.js"

function pillNode(box, text = "") {
  const pill = {
    label: {textContent: text},
    hidden: {value: text},
    button: {
      attrs: {},
      setAttribute(name, value) {
        this.attrs[name] = value
      },
      closest: () => pill,
    },
    querySelector(selector) {
      return {"[data-label]": this.label, 'input[type="hidden"]': this.hidden, "[data-remove]": this.button}[selector]
    },
    cloneNode: () => pillNode(box),
    remove() {
      box.pills = box.pills.filter((item) => item !== pill)
    },
  }
  return pill
}

function build(initial = [], {sentinel = false} = {}) {
  const box = {pills: [], events: [], listeners: {}}
  box.pills = initial.map((text) => pillNode(box, text))
  const input = {
    value: "",
    listeners: {},
    addEventListener(type, handler) {
      this.listeners[type] = handler
    },
    focus() {},
    dispatchEvent(event) {
      box.events.push(event.type)
    },
  }
  const live = {textContent: ""}
  const sentinelInput = {value: ""}
  const el = {
    dataset: {removeLabel: "Remove %{label}", addedLabel: "%{label} added", removedLabel: "%{label} removed"},
    addEventListener(type, handler) {
      box.listeners[type] = handler
    },
    insertBefore(pill) {
      box.pills.push(pill)
    },
    querySelector(selector) {
      const found = {
        'input[type="text"]': input,
        "[data-live]": live,
        "template[data-pill]": {content: {firstElementChild: pillNode(box)}},
      }
      return found[selector]
    },
    querySelectorAll(selector) {
      const all = {
        "[data-pill-item]": box.pills,
        '[data-pill-item] input[type="hidden"]': box.pills.map((pill) => pill.hidden),
        'input[type="hidden"]': [...(sentinel ? [sentinelInput] : []), ...box.pills.map((pill) => pill.hidden)],
      }
      return all[selector]
    },
  }
  const hook = {...Pillbox, el}
  hook.mounted()
  const key = (name) => {
    const event = {key: name, prevented: false, preventDefault() { this.prevented = true }}
    input.listeners.keydown(event)
    return event
  }
  const type = (text) => {
    input.value = text
  }
  return {box, input, live, key, type, texts: () => box.pills.map((pill) => pill.label.textContent)}
}

test("Enter adds the typed text as a pill and tells the form", () => {
  const {box, input, key, type, texts} = build()
  type("Elixir")
  const event = key("Enter")
  assert.deepEqual(texts(), ["Elixir"])
  assert.equal(input.value, "")
  assert.deepEqual(box.events, ["input"])
  assert.equal(event.prevented, true)
})

test("a comma adds it too", () => {
  const {key, type, texts} = build()
  type("Phoenix")
  key(",")
  assert.deepEqual(texts(), ["Phoenix"])
})

test("a repeat is ignored whatever its case", () => {
  const {box, key, type, texts} = build(["Elixir"])
  type("elixir")
  key("Enter")
  assert.deepEqual(texts(), ["Elixir"])
  assert.deepEqual(box.events, [])
})

test("an empty field adds nothing", () => {
  const {box, key, type} = build()
  type("   ")
  key("Enter")
  assert.equal(box.pills.length, 0)
})

test("Backspace on an empty field removes the last pill, with text it leaves the pills", () => {
  const {key, type, texts} = build(["a", "b"])
  key("Backspace")
  assert.deepEqual(texts(), ["a"])
  type("x")
  const event = key("Backspace")
  assert.deepEqual(texts(), ["a"])
  assert.equal(event.prevented, false)
})

test("the × of a pill removes that pill", () => {
  const {box, texts} = build(["a", "b"])
  const target = {closest: (selector) => ({"[data-remove]": box.pills[0].button}[selector])}
  box.listeners.click({target})
  assert.deepEqual(texts(), ["b"])
})

test("each new pill names its × with the pattern and the change is announced", () => {
  const {box, live, key, type} = build()
  type("Elixir")
  key("Enter")
  assert.equal(box.pills[0].button.attrs["aria-label"], "Remove Elixir")
  assert.equal(live.textContent, "Elixir added")
})

test("the blank marker of empty_sentinel is not a pill, so it never counts as a repeat", () => {
  const {key, type, texts} = build([], {sentinel: true})
  type("a")
  key("Enter")
  assert.deepEqual(texts(), ["a"])
  type("")
  key("Enter")
  assert.deepEqual(texts(), ["a"])
})
