import {percent} from "./range_logic.js"

/**
 * Paints the filled part of a single range input as it is dragged: the server sets `--p` for the value it
 * has, and this keeps it up with the thumb between two round trips.
 */
export default {
  mounted() {
    this.paint = () => this.el.style.setProperty("--p", `${percent(this.el.value, this.el.min, this.el.max)}%`)
    this.el.addEventListener("input", this.paint)
  },
  destroyed() {
    this.el.removeEventListener("input", this.paint)
  },
}
