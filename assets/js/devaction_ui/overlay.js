import {runKey} from "./keys.js"
import {dragOffset, dragStyle, exempt, isTop, lockStyle, release, retain, settleStyle, shouldClose, speed, stackWith, stackWithout} from "./overlay_logic.js"

let stack = []
let inert = new Map()
let saved = null

const watcher = new MutationObserver((records) =>
  records.forEach(({target}) => inert.has(target) && !target.hasAttribute("inert") && target.setAttribute("inert", "")),
)

const around = (el) => {
  const path = []
  for (let node = el; node && node !== document.body; node = node.parentElement) path.push(node)
  return path
    .flatMap((node) => [...node.parentElement.children].filter((sibling) => sibling !== node))
    .filter((node) => !exempt({tag: node.tagName, keep: node.hasAttribute("data-overlay-keep"), live: node.hasAttribute("aria-live")}))
}

const lock = () => {
  const {body, documentElement} = document
  saved = {overflow: body.style.overflow, paddingRight: body.style.paddingRight}
  Object.assign(body.style, lockStyle(window.innerWidth - documentElement.clientWidth))
}

const unlock = () => {
  Object.assign(document.body.style, saved)
  saved = null
}

/**
 * What a modal and a drawer share, on the element that wraps the backdrop and the panel:
 *
 * - while one is open the page behind cannot scroll and everything around it is `inert` (mark what has to stay
 *   usable, such as a toast region, with `data-overlay-keep`);
 * - overlays stack: Esc closes only the one on top, running the command in `data-close`;
 * - a bottom sheet (a `[data-handle]` inside) is closed by dragging the handle down, which respects
 *   `prefers-reduced-motion`.
 */
export default {
  mounted() {
    stack.length === 0 && lock()
    stack = stackWith(stack, this.el.id)
    this.held = around(this.el)
    this.held.forEach((node) => {
      inert = retain(inert, node)
      node.setAttribute("inert", "")
      watcher.observe(node, {attributes: true, attributeFilter: ["inert"]})
    })
    this.onKey = (event) => runKey({Escape: () => isTop(stack, this.el.id) && this.close()}, event)
    document.addEventListener("keydown", this.onKey)
    this.dragging = null
    this.el.addEventListener("pointerdown", (event) => this.grab(event))
    this.el.addEventListener("pointermove", (event) => this.drag(event))
    this.el.addEventListener("pointerup", () => this.drop())
    this.el.addEventListener("pointercancel", () => this.settle())
  },

  destroyed() {
    document.removeEventListener("keydown", this.onKey)
    stack = stackWithout(stack, this.el.id)
    this.held.forEach((node) => {
      inert = release(inert, node)
      inert.has(node) || node.removeAttribute("inert")
    })
    stack.length === 0 && (unlock(), watcher.disconnect())
  },

  close() {
    this.liveSocket.execJS(this.el, this.el.dataset.close)
  },

  panel() {
    return document.getElementById(`${this.el.id}-panel`)
  },

  grab(event) {
    const handle = event.target.closest("[data-handle]")
    const live = handle && handle.offsetParent !== null
    const sample = {y: event.clientY, at: event.timeStamp}
    live && handle.setPointerCapture(event.pointerId)
    this.dragging = live ? {start: sample, prev: sample, last: sample} : null
  },

  drag(event) {
    const state = this.dragging
    state && Object.assign(this.panel().style, dragStyle(dragOffset(state.start.y, event.clientY)))
    state && Object.assign(state, {prev: state.last, last: {y: event.clientY, at: event.timeStamp}})
  },

  drop() {
    const state = this.dragging
    const height = this.panel().getBoundingClientRect().height
    state && (shouldClose(this.outcome(state, height)) ? this.close() : this.settle())
  },

  outcome({start, prev, last}, height) {
    return {offset: dragOffset(start.y, last.y), height, velocity: speed(prev.y, prev.at, last.y, last.at)}
  },

  settle() {
    this.dragging = null
    Object.assign(this.panel().style, settleStyle(window.matchMedia("(prefers-reduced-motion: reduce)").matches))
  },
}
