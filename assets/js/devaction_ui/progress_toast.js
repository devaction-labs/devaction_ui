import {EXIT_MS, leftAfter, LINGER_MS, plan} from "./toast_logic.js"

/**
 * A job's notice that leaves by itself once the job is done: after a short linger (paused while the
 * pointer or the focus is on it) it plays its exit and tells the LiveView (`data-on-dismiss`) to drop it.
 * A failed one never leaves by itself.
 */
export default {
  mounted() {
    this.remaining = LINGER_MS
    this.paused = false
    ;["mouseenter", "focusin"].forEach((name) => this.el.addEventListener(name, () => this.pause(true)))
    ;["mouseleave", "focusout"].forEach((name) => this.el.addEventListener(name, () => this.pause(false)))
    this.schedule()
  },

  updated() {
    this.schedule()
  },

  destroyed() {
    this.stop()
  },

  pause(on) {
    on && this.timer && (this.remaining = leftAfter(this.remaining, this.startedAt, Date.now()))
    this.paused = on
    this.schedule()
  },

  stop() {
    clearTimeout(this.timer)
    clearTimeout(this.leaving)
    this.timer = null
  },

  schedule() {
    this.stop()
    const {wait} = plan({state: this.el.dataset.state, remaining: this.remaining, paused: this.paused})
    this.startedAt = Date.now()
    wait !== null && (this.timer = setTimeout(() => this.leave(), wait))
  },

  leave() {
    this.el.setAttribute("data-leaving", "")
    this.leaving = setTimeout(
      // To the component the toast sits in, when it sits in one, else to the LiveView.
      () => this.pushEventTo(this.el, this.el.dataset.onDismiss, {id: this.el.id}),
      EXIT_MS,
    )
  },
}
