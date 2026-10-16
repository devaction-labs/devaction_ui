import {elapsed, formats, readTimer} from "./numbers.js"

/**
 * The seconds of a timer between two updates from the server: `phx-hook="DevactionUI.Timer"` on the box with
 * `data-base`, `data-started-at` (empty while paused) and `data-now` (the server's clock, so a wrong clock in the
 * browser does not shift the time). It writes the time into the `[data-time]` element every second while it runs:
 * as `HH:MM:SS`, or as `HH:MM` when the element says `data-format="short"` (the mini timer).
 */
export default {
  mounted() {
    this.sync()
  },

  updated() {
    this.sync()
  },

  destroyed() {
    clearInterval(this.interval)
  },

  sync() {
    clearInterval(this.interval)
    const {base, startedAt, serverNow} = readTimer(this.el.dataset)
    const offset = serverNow === null ? 0 : serverNow - Date.now() / 1000
    const draw = () =>
      this.write(elapsed({base, startedAt, nowSeconds: Date.now() / 1000 + offset}))

    draw()
    startedAt !== null && (this.interval = setInterval(draw, 1000))
  },

  write(seconds) {
    const target = this.el.querySelector("[data-time]")
    const write = formats[this.el.dataset.format] ?? formats.full
    target && (target.textContent = write(seconds))
  },
}
