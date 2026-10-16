import {notify} from "./dom.js"
import {signaturePath, statusText, toPoint, toSvg} from "./signature_logic.js"

/**
 * A pad to sign on: `phx-hook="DevactionUI.Signature"` on a box with an `<svg>` holding a `<path>`, a hidden
 * `<input>` that receives the path and an optional `[data-clear]` button. The path goes into the input on every
 * stroke and an `input` event tells the form; `exportSvg(color)` gives the SVG of what was drawn. An optional
 * `[data-status]` says "empty" or "ready" from its `data-empty` and `data-ready`.
 */
export default {
  mounted() {
    this.svg = this.el.querySelector("svg")
    this.path = this.el.querySelector("path")
    this.input = this.el.querySelector('input[type="hidden"]')
    this.status = this.el.querySelector("[data-status]")
    this.strokes = []
    this.drawing = false

    this.svg.addEventListener("pointerdown", (event) => this.start(event))
    this.svg.addEventListener("pointermove", (event) => this.move(event))
    this.svg.addEventListener("pointerup", () => (this.drawing = false))
    this.svg.addEventListener("pointercancel", () => (this.drawing = false))
    this.el.querySelector("[data-clear]")?.addEventListener("click", () => this.clear())
    this.el.exportSvg = (color) => toSvg(signaturePath(this.strokes), color)
  },

  start(event) {
    this.drawing = true
    this.svg.setPointerCapture(event.pointerId)
    this.strokes.push([this.point(event)])
    this.render()
  },

  move(event) {
    if (!this.drawing) return
    this.strokes[this.strokes.length - 1].push(this.point(event))
    this.render()
  },

  clear() {
    this.strokes = []
    this.render()
  },

  point(event) {
    return toPoint(event, this.svg.getBoundingClientRect())
  },

  render() {
    const d = signaturePath(this.strokes)
    this.path.setAttribute("d", d)
    this.input.value = d
    this.status && (this.status.textContent = statusText(this.strokes, this.status.dataset))
    notify(this.input)
  },
}
