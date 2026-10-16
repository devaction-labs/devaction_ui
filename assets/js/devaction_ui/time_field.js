import {completeClock, fromMinutes, hintFor, lengthBetween, lengthText, maskClock, stepClock, suggestions, toMinutes} from "./clock.js"
import {notify} from "./dom.js"
import {runKey} from "./keys.js"

const OPTION =
  "group flex h-8 w-full cursor-pointer items-center rounded-[7px] px-2.5 text-left outline-none aria-selected:bg-ink aria-selected:text-on-primary hover:bg-wrap aria-selected:hover:bg-ink"

/**
 * A start and an end time with the suggestions around the one being edited. Typing lays the digits out as
 * `HH:MM` and a half-typed time is completed when the field is left; ↑ and ↓ move the time one step, Enter
 * completes it; a click on a suggestion picks it. The fields are the form's own inputs (they have the names), so
 * `phx-change` hears them. The list and the length are drawn here, in `[data-time-list]` and `[data-time-length]`
 * (`phx-update="ignore"`), from `clock.js`; the words come in the dataset as patterns with `%{count}`.
 */
export default {
  mounted() {
    this.side = "end"
    this.step = Number.parseInt(this.el.dataset.step, 10)
    this.patterns = {hours: this.el.dataset.hours, minutes: this.el.dataset.minutes}
    this.el.addEventListener("focusin", (event) => this.onFocus(event))
    this.el.addEventListener("input", (event) => this.onInput(event))
    this.el.addEventListener("focusout", (event) => this.onBlur(event))
    this.el.addEventListener("keydown", (event) => this.onKey(event))
    this.el.addEventListener("mousedown", (event) => this.onPress(event))
    this.draw()
  },

  updated() {
    this.draw()
  },

  field(side) {
    return this.el.querySelector(`[data-time="${side}"]`)
  },

  minutes(side) {
    const time = completeClock(this.field(side).value)
    return time === null ? null : toMinutes(time)
  },

  sideOf(event) {
    return event.target.closest?.("[data-time]")?.dataset.time
  },

  onFocus(event) {
    const side = this.sideOf(event)
    side && ((this.side = side), event.target.select(), this.draw())
  },

  onInput(event) {
    const side = this.sideOf(event)
    side && ((event.target.value = maskClock(event.target.value)), this.draw())
  },

  onBlur(event) {
    const side = this.sideOf(event)
    const time = side && completeClock(event.target.value)
    side && this.write(side, time || fromMinutes(this.last[side]))
  },

  onKey(event) {
    const side = this.sideOf(event)
    const move = (direction) => () => this.write(side, fromMinutes(stepClock(this.minutes(side) ?? this.last[side], direction, this.step)))
    side &&
      runKey(
        {
          ArrowDown: move(1),
          ArrowUp: move(-1),
          Enter: () => this.write(side, completeClock(event.target.value) ?? fromMinutes(this.last[side])),
        },
        event,
      )
  },

  onPress(event) {
    const option = event.target.closest?.("[data-minutes]")
    option &&
      !this.field(this.side).disabled && (event.preventDefault(), this.write(this.side, fromMinutes(Number(option.dataset.minutes))))
  },

  write(side, time) {
    const field = this.field(side)
    const changed = field.value !== time
    field.value = time
    this.draw()
    changed && notify(field)
  },

  draw() {
    const start = this.minutes("start") ?? this.last?.start ?? 0
    const end = this.minutes("end") ?? this.last?.end ?? 0
    this.last = {start, end}
    const current = this.last[this.side]
    const list = this.el.querySelector("[data-time-list]")
    const options = suggestions(current, this.step).map((minutes) => this.option(minutes, current, start))

    list.replaceChildren(...options)
    this.el.querySelector("[data-time-length]").textContent = lengthText(lengthBetween(start, end), this.patterns)
    this.field(this.side).setAttribute("aria-activedescendant", `${list.id}-${current}`)
  },

  option(minutes, current, start) {
    const button = document.createElement("button")
    const time = document.createElement("span")
    const hint = document.createElement("span")
    const length = this.side === "end" ? hintFor(minutes, start) : null

    button.type = "button"
    button.id = `${this.el.querySelector("[data-time-list]").id}-${minutes}`
    button.className = OPTION
    button.tabIndex = -1
    button.dataset.minutes = String(minutes)
    button.setAttribute("role", "option")
    button.setAttribute("aria-selected", String(minutes === current))
    time.className = "font-mono text-[13px]"
    time.textContent = fromMinutes(minutes)
    hint.className = "ml-auto text-xs text-muted group-aria-selected:text-done"
    hint.textContent = length === null ? "" : lengthText(length, this.patterns)
    button.append(time, hint)
    return button
  },
}
