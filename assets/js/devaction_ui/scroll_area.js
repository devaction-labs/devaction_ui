import {ATTRIBUTES, edges} from "./scroll_area_logic.js"

/**
 * A scroll area: a thin bar and a shadow only at the edges that still have content. The root gets
 * `data-more-left`, `data-more-right`, `data-more-top` and `data-more-bottom` as it scrolls or resizes, and
 * `data-scrolled-y` once the content has moved under a sticky header; the CSS draws the shadows from them.
 */
export default {
  mounted() {
    this.viewport = this.el.querySelector("[data-viewport]") ?? this.el
    this.sync = () => this.mark()
    this.viewport.addEventListener("scroll", this.sync, {passive: true})
    this.observer = typeof ResizeObserver === "undefined" ? null : new ResizeObserver(this.sync)
    this.observer?.observe(this.viewport)
    this.viewport.firstElementChild && this.observer?.observe(this.viewport.firstElementChild)
    this.mark()
  },

  updated() {
    this.mark()
  },

  destroyed() {
    this.viewport.removeEventListener("scroll", this.sync)
    this.observer?.disconnect()
  },

  mark() {
    const found = edges(this.viewport)
    Object.entries(ATTRIBUTES).forEach(([edge, name]) => this.el.toggleAttribute(name, found[edge]))
    this.el.toggleAttribute("data-scrolled-y", found.top)
  },
}
