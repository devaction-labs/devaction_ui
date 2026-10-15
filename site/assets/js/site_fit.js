import {fitScale} from "./fit_logic.js"

/**
 * Scales a full-size page, shown in an iframe, down to the room the documentation gives it. The frame keeps
 * its proportions through `aspect-ratio`; this only tells the iframe how much to shrink (`--fit-scale`).
 */
export default {
  mounted() {
    this.paint = () => this.el.style.setProperty("--fit-scale", fitScale(this.el.clientWidth, Number(this.el.dataset.width)))
    this.observer = new ResizeObserver(this.paint)
    this.observer.observe(this.el)
    this.paint()
  },
  destroyed() {
    this.observer.disconnect()
  },
}
