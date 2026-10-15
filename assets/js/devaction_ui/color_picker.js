import {clamp, fill, hexToHsv, hsvToHex, withAlpha} from "./color_logic.js"
import {runKey} from "./keys.js"

const FALLBACK = "#2563EB"

/**
 * A colour field with a panel: a square for saturation and brightness, a hue strip, an optional opacity
 * strip, a row of presets and, where the browser has one, the eyedropper. It always writes hex into the
 * text field and tells the form with an `input` event. The words (the area's spoken value) come from the
 * server in `data-area-text`; the server's `JS.ignore_attributes` keeps LiveView from closing the panel.
 */
export default {
  mounted() {
    const part = (name) => this.el.querySelector(`[data-${name}]`)
    this.input = part("input")
    this.toggle = part("toggle")
    this.panel = part("panel")
    this.area = part("area")
    this.handle = part("handle")
    this.hue = part("hue")
    this.alpha = part("alpha")
    this.state = hexToHsv(this.input.value) ?? hexToHsv(this.el.dataset.value) ?? hexToHsv(FALLBACK)
    this.bind()
    this.render(false)
  },

  destroyed() {
    document.removeEventListener("pointerdown", this.outside)
  },

  hex() {
    return hsvToHex(this.state.h, this.state.s, this.state.v)
  },

  value() {
    return withAlpha(this.hex(), this.alpha ? this.state.a : 100)
  },

  open() {
    this.panel.hidden = false
    this.toggle.setAttribute("aria-expanded", "true")
    this.el.dataset.open = "true"
  },

  close() {
    this.panel.hidden = true
    this.toggle.setAttribute("aria-expanded", "false")
    delete this.el.dataset.open
  },

  bind() {
    this.toggle.addEventListener("click", () => (this.panel.hidden ? this.open() : this.close()))
    this.input.addEventListener("focus", () => this.open())
    this.input.addEventListener("input", () => this.typed())
    this.outside = (event) => !this.el.contains(event.target) && this.close()
    document.addEventListener("pointerdown", this.outside)
    this.el.addEventListener("keydown", (event) =>
      runKey({Escape: () => (this.panel.hidden ? false : (this.close(), this.input.focus()))}, event),
    )
    this.bindArea()
    this.hue.addEventListener("input", () => this.set({h: Number(this.hue.value)}))
    this.alpha?.addEventListener("input", () => this.set({a: Number(this.alpha.value)}))
    this.el.querySelectorAll("[data-preset]").forEach((button) =>
      button.addEventListener("click", () => this.set({...hexToHsv(button.dataset.preset), a: this.state.a})),
    )
    this.bindEyedropper()
  },

  bindArea() {
    const fromPointer = (event) => {
      const box = this.area.getBoundingClientRect()
      this.set({
        s: clamp((event.clientX - box.left) / box.width, 0, 1),
        v: clamp(1 - (event.clientY - box.top) / box.height, 0, 1),
      })
    }
    this.area.addEventListener("pointerdown", (event) => {
      this.area.setPointerCapture(event.pointerId)
      fromPointer(event)
    })
    this.area.addEventListener("pointermove", (event) => this.area.hasPointerCapture(event.pointerId) && fromPointer(event))
    this.area.addEventListener("keydown", (event) => {
      const step = event.shiftKey ? 0.1 : 0.02
      const nudge = (key, by) => () => this.set({[key]: clamp(this.state[key] + by, 0, 1)})
      runKey(
        {ArrowLeft: nudge("s", -step), ArrowRight: nudge("s", step), ArrowUp: nudge("v", step), ArrowDown: nudge("v", -step)},
        event,
      )
    })
  },

  bindEyedropper() {
    const button = this.el.querySelector("[data-eyedropper]")
    if (!button || !("EyeDropper" in window)) return
    button.hidden = false
    button.addEventListener("click", async () => {
      const picked = await new window.EyeDropper().open().catch(() => null)
      picked && this.set({...hexToHsv(picked.sRGBHex), a: this.state.a})
    })
  },

  typed() {
    if (this.emitting) return
    const typed = hexToHsv(this.input.value)
    typed && this.set({...typed, a: this.alpha ? typed.a : 100}, {keepInput: true})
  },

  set(changes, options) {
    this.state = {...this.state, ...changes}
    this.render(true, options)
  },

  render(emit, {keepInput = false} = {}) {
    const {h, s, v, a} = this.state
    const hex = this.hex()
    this.el.style.setProperty("--cp-hue", hsvToHex(h, 1, 1))
    this.el.style.setProperty("--cp-color", hex)
    this.handle.style.left = `${s * 100}%`
    this.handle.style.top = `${(1 - v) * 100}%`
    this.area.setAttribute(
      "aria-valuetext",
      fill(this.el.dataset.areaText ?? "%{color}", {color: hex, saturation: Math.round(s * 100), brightness: Math.round(v * 100)}),
    )
    this.hue.value = Math.round(h)
    this.alpha && (this.alpha.value = a)
    this.el
      .querySelectorAll("[data-preset]")
      .forEach((button) => button.setAttribute("aria-checked", String(button.dataset.preset.toUpperCase() === hex)))
    keepInput || (this.input.value = this.value())
    emit && this.emit()
  },

  emit() {
    this.emitting = true
    this.input.dispatchEvent(new Event("input", {bubbles: true}))
    this.emitting = false
  },
}
