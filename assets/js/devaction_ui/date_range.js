import {clampMin, countDays, monthOf, moveFocus, pick, previewRange, rangeLabel, sameRange, shiftMonth} from "./dates.js"
import {renderRangeMonth} from "./date_picker_view.js"
import {notify} from "./dom.js"
import {runKey} from "./keys.js"

const UTC = {timeZone: "UTC"}
const SET_EVENT = "devaction:date-range-set"
const MOVES = ["ArrowLeft", "ArrowRight", "ArrowUp", "ArrowDown", "PageUp", "PageDown", "Home", "End"]

const unwrap = (value) => (value === "" || value === undefined ? null : value)

/**
 * A range over two months with a column of ready-made ranges, picked in the panel of a popover and applied with a
 * button. What is picked stays pending (`this.pending`) until Apply writes it into the hidden inputs, fires `input`
 * and writes the trigger's text; Cancel, Esc or a press outside drop it. The band follows the pointer between the
 * first pick and the second (the preview), the two months turn together, and the keys are those of the
 * month calendar (arrows, PageUp/PageDown, Home/End). The dates and the days of a range are `dates.js`; the names
 * of months and days come from the browser's `Intl` in the `data-locale`. The server gives it `data-today`, `data-min`
 * and the texts. A `devaction:date-range-set` event with `{from, to}` in its `detail` replaces the applied range.
 */
export default {
  mounted() {
    const data = this.el.dataset
    this.today = data.today
    this.min = unwrap(data.min)
    this.weekStart = Number.parseInt(data.weekStart, 10)
    this.capitalize = data.capitalize === "true"
    this.committed = {from: unwrap(data.from), to: unwrap(data.to)}
    this.pending = {...this.committed}
    this.hover = null
    this.focus = clampMin(this.committed.from ?? this.today, this.min)
    this.view = monthOf(this.focus)

    this.monthFormat = new Intl.DateTimeFormat(data.locale, {...UTC, month: "long", year: "numeric"})
    this.dayFormat = new Intl.DateTimeFormat(data.locale, {...UTC, dateStyle: "full"})
    this.weekdayFormat = new Intl.DateTimeFormat(data.locale, {...UTC, weekday: "narrow"})
    this.shortFormat = new Intl.DateTimeFormat(data.locale, {...UTC, day: "numeric", month: "short"})

    this.panel = this.el.querySelector("[data-panel]")
    this.months = this.panel.querySelector("[data-range-months]")
    this.panel.addEventListener("click", (event) => this.onClick(event))
    this.panel.addEventListener("keydown", (event) => this.onKey(event))
    this.panel.addEventListener("mouseover", (event) => this.onHover(event))
    this.panel.addEventListener("mouseleave", () => this.hoverOn(null))
    this.el.addEventListener(SET_EVENT, (event) => this.set(event.detail))
    this.watchPanel()
    this.write()
    this.draw()
  },

  destroyed() {
    this.observer?.disconnect()
  },

  watchPanel() {
    this.observer = new MutationObserver(() => this.panel.hidden && this.revert())
    this.observer.observe(this.panel, {attributes: true, attributeFilter: ["hidden"]})
  },

  set({from = null, to = null} = {}) {
    this.committed = {from, to}
    this.pending = {from, to}
    this.focus = clampMin(from ?? this.today, this.min)
    this.view = monthOf(this.focus)
    this.write()
    this.draw()
  },

  revert() {
    this.pending = {...this.committed}
    this.hover = null
    this.view = monthOf(clampMin(this.committed.from ?? this.today, this.min))
    this.draw()
  },

  onClick(event) {
    const target = (selector) => event.target.closest(selector)
    const actions = [
      ["[data-day]", (day) => !day.disabled && this.pick(day.dataset.day)],
      ["[data-nav]", (nav) => this.shift(Number.parseInt(nav.dataset.nav, 10))],
      ["[data-preset]", (preset) => this.preset(preset)],
      ["[data-range-apply]", () => this.apply()],
      ["[data-range-cancel]", () => this.cancel()],
    ]
    const [selector, act] = actions.find(([candidate]) => target(candidate)) ?? []
    selector && act(target(selector))
  },

  onHover(event) {
    this.hoverOn(event.target.closest?.("[data-day]")?.dataset.day ?? null)
  },

  hoverOn(iso) {
    const changed = iso !== this.hover && this.pending.from && !this.pending.to
    this.hover = iso
    changed && this.draw()
  },

  onKey(event) {
    if (!event.target.closest?.("[data-day]")) return
    const goTo = (key) => () => {
      this.focus = clampMin(moveFocus(key, this.focus, this.weekStart), this.min)
      this.view = this.viewHolding(this.focus)
      this.draw({refocus: true})
    }
    runKey(Object.fromEntries(MOVES.map((key) => [key, goTo(key)])), event)
  },

  viewHolding(iso) {
    const month = monthOf(iso)
    const next = shiftMonth(this.view, 1)
    const shown = [this.view, next].some((view) => view.year === month.year && view.month === month.month)
    return shown ? this.view : month
  },

  shift(months) {
    this.view = shiftMonth(this.view, months)
    this.draw()
    this.panel.querySelector(`[data-nav="${months}"]`)?.focus()
  },

  pick(iso) {
    this.pending = pick(this.pending, iso, "range")
    this.focus = iso
    this.hover = null
    this.draw({refocus: true})
  },

  preset(button) {
    const from = unwrap(button.dataset.from)
    const to = unwrap(button.dataset.to)
    const ready = from !== null
    this.pending = ready ? {from, to} : this.pending
    this.view = ready ? monthOf(from) : this.view
    this.focus = ready ? from : this.focus
    this.draw({refocus: !ready})
  },

  apply() {
    const complete = this.pending.from && this.pending.to
    complete && ((this.committed = {...this.pending}), this.write(), this.close(), this.announce())
  },

  cancel() {
    this.revert()
    this.close()
  },

  close() {
    !this.panel.hidden && this.el.querySelector("[data-trigger] button")?.click()
  },

  announce() {
    notify(this.el.querySelector("[data-from-input]"))
  },

  write() {
    const from = this.el.querySelector("[data-from-input]")
    const to = this.el.querySelector("[data-to-input]")
    from.value = this.committed.from ?? ""
    to.value = this.committed.to ?? ""
    this.el.querySelector("[data-range-label]").textContent =
      rangeLabel(this.committed, {day: (iso) => this.shortDay(iso), year: (iso) => String(Number(iso.slice(0, 4)))}) ||
      this.el.dataset.placeholder
  },

  shortDay(iso) {
    return this.shortFormat
      .formatToParts(new Date(`${iso}T00:00:00Z`))
      .filter(({type}) => type === "day" || type === "month")
      .map(({value}) => value.replace(/\.$/, ""))
      .join(" ")
  },

  title(view) {
    const text = this.monthFormat.format(new Date(Date.UTC(view.year, view.month, 1)))
    return this.capitalize ? text.charAt(0).toUpperCase() + text.slice(1) : text
  },

  weekdays() {
    return [...Array(7)].map((_, index) =>
      this.weekdayFormat.format(new Date(Date.UTC(2023, 0, 1 + ((index + this.weekStart) % 7)))),
    )
  },

  icon(name) {
    return this.el.querySelector(`template[data-${name}-icon]`)?.innerHTML.trim() || undefined
  },

  draw({refocus = false} = {}) {
    const data = this.el.dataset
    const shown = previewRange(this.pending, this.hover)
    const text = {
      weekdays: this.weekdays(),
      previousLabel: data.previous,
      nextLabel: data.next,
      previousIcon: this.icon("previous"),
      nextIcon: this.icon("next"),
      dayLabel: (iso) => this.dayFormat.format(new Date(`${iso}T00:00:00Z`)),
    }
    this.months.innerHTML = [this.view, shiftMonth(this.view, 1)]
      .map((view, index) =>
        `<div>${renderRangeMonth(
          {view, ...shown, focus: this.focus, today: this.today, min: this.min, weekStart: this.weekStart, previous: index === 0, next: index === 1},
          {...text, title: this.title(view)},
        )}</div>`,
      )
      .join("")
    this.sync()
    refocus && this.panel.querySelector(`[data-day="${this.focus}"]`)?.focus()
  },

  sync() {
    const days = countDays(this.pending)
    const data = this.el.dataset
    const texts = [
      [days === 0 && this.pending.from, data.pending],
      [days === 1, data.one ?? data.count?.replace("%{count}", "1")],
      [days > 1, data.count?.replace("%{count}", String(days))],
    ]
    this.panel.querySelector("[data-range-count]").textContent = texts.find(([applies]) => applies)?.[1] ?? ""
    this.panel.querySelectorAll("[data-preset]").forEach((button) => {
      const range = {from: unwrap(button.dataset.from), to: unwrap(button.dataset.to)}
      button.setAttribute("aria-pressed", String(range.from ? sameRange(range, this.pending) : !this.matchesAPreset()))
    })
    const apply = this.panel.querySelector("[data-range-apply]")
    apply.disabled = !(this.pending.from && this.pending.to)
  },

  matchesAPreset() {
    return [...this.panel.querySelectorAll("[data-preset][data-from]")].some((button) =>
      sameRange({from: unwrap(button.dataset.from), to: unwrap(button.dataset.to)}, this.pending),
    )
  },
}
