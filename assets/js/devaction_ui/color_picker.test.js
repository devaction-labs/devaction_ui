import test from "node:test"
import assert from "node:assert/strict"
import ColorPicker from "./color_picker.js"

const node = (props = {}) => ({
  listeners: {},
  attrs: {},
  style: {},
  hidden: false,
  value: "",
  textContent: "",
  addEventListener(type, handler) {
    this.listeners[type] = handler
  },
  setAttribute(name, value) {
    this.attrs[name] = value
  },
  getAttribute(name) {
    return this.attrs[name]
  },
  focus() {
    this.focused = true
  },
  dispatchEvent(event) {
    this.events = [...(this.events ?? []), event.type]
  },
  ...props,
})

function build({alpha = false, value = "#2563EB"} = {}) {
  const documentListeners = {}
  globalThis.document = {
    addEventListener: (type, handler) => (documentListeners[type] = handler),
    removeEventListener: (type) => delete documentListeners[type],
  }
  globalThis.window = {}
  const presets = ["#DC2626", "#16A34A"].map((hex) => node({dataset: {preset: hex}}))
  const parts = {
    input: node({value}),
    toggle: node(),
    panel: node({hidden: true}),
    area: node({getBoundingClientRect: () => ({left: 0, top: 0, width: 100, height: 100})}),
    handle: node(),
    hue: node(),
    alpha: alpha ? node() : null,
    "value-text": node(),
    eyedropper: null,
  }
  const el = node({
    dataset: {value, areaText: "%{color} s%{saturation} b%{brightness}"},
    contains: (target) => target === el,
    querySelector: (selector) => parts[/\[data-(.+)\]/.exec(selector)[1]],
    querySelectorAll: () => presets,
  })
  el.style = {props: {}, setProperty(name, value) { this.props[name] = value }}
  const hook = {...ColorPicker, el}
  hook.mounted()
  const press = (target, key, extra = {}) => {
    const event = {key, prevented: false, preventDefault() { this.prevented = true }, ...extra}
    target.listeners.keydown({...event, preventDefault: () => (event.prevented = true)})
    return event
  }
  return {hook, el, parts, presets, press, documentListeners}
}

test("on mount the colour paints the variables, the handle, the spoken value and the text", () => {
  const {el, parts} = build()
  assert.equal(el.style.props["--cp-color"], "#2563EB")
  assert.match(el.style.props["--cp-hue"], /^#[0-9A-F]{6}$/)
  assert.match(parts.handle.style.left, /%$/)
  assert.match(parts.area.attrs["aria-valuetext"], /^#2563EB s\d+ b\d+$/)
  assert.equal(parts["value-text"].textContent, "#2563EB")
})

test("the toggle opens and closes the panel and says so", () => {
  const {el, parts} = build()
  parts.toggle.listeners.click()
  assert.equal(parts.panel.hidden, false)
  assert.equal(parts.toggle.attrs["aria-expanded"], "true")
  assert.equal(el.dataset.open, "true")
  parts.toggle.listeners.click()
  assert.equal(parts.panel.hidden, true)
  assert.equal(parts.toggle.attrs["aria-expanded"], "false")
  assert.equal(el.dataset.open, undefined)
})

test("Esc closes an open panel, gives the focus back to the field and is consumed", () => {
  const {el, parts, press} = build()
  parts.toggle.listeners.click()
  const event = press(el, "Escape")
  assert.equal(parts.panel.hidden, true)
  assert.equal(parts.input.focused, true)
  assert.equal(event.prevented, true)
})

test("Esc with the panel closed is left to the page", () => {
  const {el, press} = build()
  const event = press(el, "Escape")
  assert.equal(event.prevented, false)
})

test("a press outside the picker closes it, one inside does not", () => {
  const {el, parts, documentListeners} = build()
  parts.toggle.listeners.click()
  documentListeners.pointerdown({target: el})
  assert.equal(parts.panel.hidden, false)
  documentListeners.pointerdown({target: {}})
  assert.equal(parts.panel.hidden, true)
})

test("the arrows of the square nudge saturation and brightness and tell the form", () => {
  const {parts, press} = build({value: "#808080"})
  press(parts.area, "ArrowRight")
  assert.notEqual(parts.input.value, "#808080")
  assert.deepEqual(parts.input.events, ["input"])
  const before = parts.input.value
  press(parts.area, "ArrowUp", {shiftKey: true})
  assert.notEqual(parts.input.value, before)
})

test("a preset sets the colour and is the only one marked pressed", () => {
  const {el, parts, presets} = build()
  presets[0].listeners.click()
  assert.equal(parts.input.value, "#DC2626")
  assert.equal(el.style.props["--cp-color"], "#DC2626")
  assert.equal(presets[0].attrs["aria-pressed"], "true")
  assert.equal(presets[1].attrs["aria-pressed"], "false")
})

test("the opacity strip appends the alpha to the written value", () => {
  const {parts} = build({alpha: true})
  parts.alpha.value = "50"
  parts.alpha.listeners.input()
  assert.match(parts.input.value, /^#2563EB80$/)
})

test("without opacity the value is always six digits", () => {
  const {parts, presets} = build()
  presets[1].listeners.click()
  assert.equal(parts.input.value, "#16A34A")
})

test("typing a valid colour moves the picker without rewriting the field", () => {
  const {el, parts} = build()
  parts.input.value = "#FF0000"
  parts.input.listeners.input()
  assert.equal(el.style.props["--cp-color"], "#FF0000")
  assert.equal(parts.input.value, "#FF0000")
})

test("typing something that is not a colour changes nothing", () => {
  const {el, parts} = build()
  parts.input.value = "#12"
  parts.input.listeners.input()
  assert.equal(el.style.props["--cp-color"], "#2563EB")
})

test("destroying the hook takes the document listener off", () => {
  const {hook, documentListeners} = build()
  hook.destroyed()
  assert.equal(documentListeners.pointerdown, undefined)
})
