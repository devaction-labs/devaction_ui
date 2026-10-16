import {clampMin, monthOf, moveFocus, pick, sameDayIn, shiftMonth} from "./dates.js"
import {renderCalendar} from "./date_picker_view.js"
import {runKey} from "./keys.js"

const UTC = {timeZone: "UTC"}

/**
 * A month calendar for one day or a range. The server gives it what only the server knows (`data-today` in
 * the workspace's time zone, the minimum, the locale, the shortcuts); month and weekday names come from the
 * browser's `Intl`. A pick goes into the hidden inputs as ISO dates and fires `input` so `phx-change` hears
 * it. Keys: ← → a day, ↑ ↓ a week, PageUp/PageDown a month, Home/End the ends of the week, Enter picks.
 * The element is `phx-update="ignore"`: a new `value` from the server is not shown until the element gets a new
 * id. The month title is capitalised unless `data-capitalize="false"`; the arrows come from the `<template>`s
 * of the icon slots.
 */
export default {
  mounted() {
    const data = this.el.dataset
    this.mode = data.mode
    this.today = data.today
    this.min = data.min || null
    this.weekStart = Number.parseInt(data.weekStart, 10)
    this.selection = {from: data.from || null, to: data.to || null}
    this.focus = clampMin(this.selection.from ?? this.today, this.min)
    this.capitalize = data.capitalize !== "false"
    this.view = monthOf(this.focus)

    this.monthFormat = new Intl.DateTimeFormat(data.locale, {...UTC, month: "long", year: "numeric"})
    this.dayFormat = new Intl.DateTimeFormat(data.locale, {...UTC, dateStyle: "full"})
    this.weekdayFormat = new Intl.DateTimeFormat(data.locale, {...UTC, weekday: "short"})

    this.el.addEventListener("click", (event) => this.onClick(event))
    this.el.addEventListener("keydown", (event) => this.onKey(event))
    this.draw()
  },

  onClick(event) {
    const target = (selector) => event.target.closest(selector)
    const actions = [
      ["[data-day]", (day) => !day.disabled && this.pick(day.dataset.day)],
      ["[data-nav]", (nav) => this.shift(Number.parseInt(nav.dataset.nav, 10), nav.dataset.nav)],
      ["[data-shortcut]", (shortcut) => this.pick(shortcut.dataset.shortcut, {jump: true})],
    ]
    const [selector, act] = actions.find(([candidate]) => target(candidate)) ?? []
    selector && act(target(selector))
  },

  onKey(event) {
    if (!event.target.closest("[data-day]")) return
    const goTo = (key) => () => {
      this.focus = moveFocus(key, this.focus, this.weekStart)
      this.view = monthOf(this.focus)
      this.draw({refocus: true})
    }
    const keys = ["ArrowLeft", "ArrowRight", "ArrowUp", "ArrowDown", "PageUp", "PageDown", "Home", "End"]
    runKey(Object.fromEntries(keys.map((key) => [key, goTo(key)])), event)
  },

  shift(months, nav) {
    this.view = shiftMonth(this.view, months)
    // The keyboard needs a day to land on in the month that is showing: keep the same day number.
    this.focus = sameDayIn(this.focus, this.view)
    this.draw()
    nav && this.el.querySelector(`[data-nav="${nav}"]`)?.focus()
  },

  pick(iso, {jump = false} = {}) {
    if (this.min !== null && iso < this.min) return
    this.selection = pick(this.selection, iso, this.mode)
    this.focus = iso
    this.view = jump ? monthOf(iso) : this.view

    const from = this.el.querySelector("[data-from-input]")
    const to = this.el.querySelector("[data-to-input]")
    from.value = this.selection.from ?? ""
    to && (to.value = this.selection.to ?? "")

    this.draw({refocus: true})
    from.dispatchEvent(new Event("input", {bubbles: true}))
  },

  title() {
    const text = this.monthFormat.format(new Date(Date.UTC(this.view.year, this.view.month, 1)))
    return this.capitalize ? text.charAt(0).toUpperCase() + text.slice(1) : text
  },

  weekdays() {
    // 1 Jan 2023 was a Sunday: the names run from the day the week starts on.
    return [...Array(7)].map((_, index) =>
      this.weekdayFormat.format(new Date(Date.UTC(2023, 0, 1 + ((index + this.weekStart) % 7)))),
    )
  },

  icon(name) {
    const html = this.el.querySelector(`template[data-${name}-icon]`)?.innerHTML.trim()
    return html || undefined
  },

  draw({refocus = false} = {}) {
    const data = this.el.dataset
    this.el.querySelector("[data-calendar]").innerHTML = renderCalendar(
      {view: this.view, ...this.selection, focus: this.focus, today: this.today, min: this.min, weekStart: this.weekStart},
      {
        title: this.title(),
        weekdays: this.weekdays(),
        previous: data.previous,
        next: data.next,
        previousIcon: this.icon("previous"),
        nextIcon: this.icon("next"),
        insideLabel: data.inside,
        dayLabel: (iso) => this.dayFormat.format(new Date(`${iso}T00:00:00Z`)),
      },
    )
    refocus && this.el.querySelector(`[data-day="${this.focus}"]`)?.focus()
  },
}

