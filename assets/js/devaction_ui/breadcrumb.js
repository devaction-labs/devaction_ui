import {closesOnKey, closesOnPress} from "./breadcrumb_logic.js"

/**
 * The `…` of a collapsed `Breadcrumb`, a native `<details>`: Esc closes it and gives the focus back to its
 * summary, and so does a press outside. LiveView is told to leave `open` alone, so a patch does not shut it.
 */
export default {
  mounted() {
    this.summary = this.el.querySelector("summary")
    this.onKey = (event) => closesOnKey(event, this.el.open) && this.close(true)
    this.onPress = (event) => closesOnPress(this.el, event.target, this.el.open) && this.close(false)

    document.addEventListener("keydown", this.onKey)
    document.addEventListener("pointerdown", this.onPress)
  },

  destroyed() {
    document.removeEventListener("keydown", this.onKey)
    document.removeEventListener("pointerdown", this.onPress)
  },

  close(restore) {
    this.el.open = false
    restore && this.summary?.focus()
  },
}
