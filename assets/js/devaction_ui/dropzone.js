import {depthAfter, isOver} from "./dropzone_logic.js"

/** Lights the drop area (`data-over`) while a file is dragged over it; the upload itself is LiveView's. */
export default {
  mounted() {
    this.depth = 0
    this.area = this.el.querySelector("[phx-drop-target]")
    ;["dragenter", "dragleave", "drop"].forEach((type) => this.el.addEventListener(type, () => this.track(type)))
  },

  track(type) {
    this.depth = depthAfter(this.depth, type)
    this.area.toggleAttribute("data-over", isOver(this.depth))
  },
}
