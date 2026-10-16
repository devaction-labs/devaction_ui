import {runKey} from "./keys.js"
import {move, tabStop} from "./segmented_logic.js"

/**
 * Arrow keys for a segmented control without changing what it is: the segments stay toggle buttons with
 * `aria-pressed`, and only the keyboard gets easier. One segment is in the Tab order (roving tabindex): the
 * pressed one, or the first enabled one. ← → ↑ ↓ move the focus round the segments, Home and End jump to the
 * ends and disabled ones are skipped; Enter or Space presses the focused one as for any button. Moving the
 * focus does not choose: that stays a press.
 */
export default {
  mounted() {
    this.onKey = (event) => this.key(event)
    this.el.addEventListener("keydown", this.onKey)
    this.sync()
  },

  updated() {
    this.sync()
  },

  destroyed() {
    this.el.removeEventListener("keydown", this.onKey)
  },

  segments() {
    return [...this.el.querySelectorAll("button")]
  },

  items() {
    return this.segments().map((button) => ({
      pressed: button.getAttribute("aria-pressed") === "true",
      disabled: button.disabled,
    }))
  },

  sync() {
    this.rove(tabStop(this.items()))
  },

  rove(stop) {
    this.segments().forEach((button, index) => {
      button.tabIndex = index === stop ? 0 : -1
    })
  },

  key(event) {
    const segments = this.segments()
    const from = segments.indexOf(event.target.closest("button"))
    const target = segments[move(this.items(), from, event.key)]
    const go = () => {
      if (!target) return false
      this.rove(segments.indexOf(target))
      target.focus()
    }

    runKey(Object.fromEntries(["ArrowRight", "ArrowLeft", "ArrowDown", "ArrowUp", "Home", "End"].map((key) => [key, go])), event)
  },
}
