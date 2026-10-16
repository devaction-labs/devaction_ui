import {depthAfter, isOver, overText} from "./dropzone_logic.js"

/**
 * Lights the drop area (`data-over`) while a file is dragged over it and, with `data-over-label` on the root,
 * says that text in the polite `[data-over-status]` region, so the state is not only colour. The upload itself
 * is LiveView's.
 */
export default {
  mounted() {
    this.depth = 0
    this.area = this.el.querySelector("[phx-drop-target]")
    this.status = this.el.querySelector("[data-over-status]")
    ;["dragenter", "dragleave", "drop"].forEach((type) => this.el.addEventListener(type, () => this.track(type)))
  },

  track(type) {
    this.depth = depthAfter(this.depth, type)
    this.area.toggleAttribute("data-over", isOver(this.depth))
    this.status && (this.status.textContent = overText(this.depth, this.el.dataset.overLabel))
  },
}
