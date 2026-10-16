import test from "node:test"
import assert from "node:assert/strict"
import {bandClass, dayClass, escapeHtml, rangeDayClass, renderCalendar, renderRangeMonth} from "./date_picker_view.js"

const text = {
  title: "October 2026",
  weekdays: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"],
  previous: "Previous month",
  next: "Next month",
  dayLabel: (iso) => `day ${iso}`,
}
const state = {view: {year: 2026, month: 9}, from: "2026-10-15", to: "2026-10-18", focus: "2026-10-15", today: "2026-10-14", min: "2026-10-10", weekStart: 0}

test("the month has a button per day, the weekday names and the month buttons", () => {
  const html = renderCalendar(state, text)
  assert.equal((html.match(/data-day=/g) ?? []).length, 31)
  assert.match(html, /data-nav="-1" aria-label="Previous month"/)
  assert.match(html, /data-nav="1" aria-label="Next month"/)
  assert.match(html, /aria-label="October 2026"/)
  assert.equal((html.match(/>(Sun|Mon|Tue|Wed|Thu|Fri|Sat)</g) ?? []).length, 7)
})

test("the first row is padded by the days before the first of the month", () => {
  const sunday = renderCalendar(state, text)
  const monday = renderCalendar({...state, weekStart: 1}, text)
  assert.equal((sunday.match(/<span><\/span>/g) ?? []).length, 4)
  assert.equal((monday.match(/<span><\/span>/g) ?? []).length, 3)
})

test("the ends of the range are pressed, today is marked, days before the minimum are disabled", () => {
  const html = renderCalendar(state, text)
  assert.match(html, /data-day="2026-10-15"[^>]*aria-pressed="true"/)
  assert.match(html, /data-day="2026-10-18"[^>]*aria-pressed="true"/)
  assert.match(html, /data-day="2026-10-16"[^>]*aria-pressed="false"/)
  assert.match(html, /data-day="2026-10-14"[^>]*aria-current="date"/)
  assert.match(html, /data-day="2026-10-09" disabled/)
  assert.doesNotMatch(html, /data-day="2026-10-10" disabled/)
})

test("only the focused day is in the tab order", () => {
  const html = renderCalendar(state, text)
  assert.equal((html.match(/tabindex="0"/g) ?? []).length, 1)
  assert.match(html, /data-day="2026-10-15"[^>]*tabindex="0"/)
})

test("the tab stop lands on the minimum when the focus is before it", () => {
  const html = renderCalendar({...state, focus: "2026-10-03", min: "2026-10-10"}, text)
  assert.equal((html.match(/tabindex="0"/g) ?? []).length, 1)
  assert.match(html, /data-day="2026-10-10"[^>]*tabindex="0"/)
  assert.match(html, /data-day="2026-10-03" disabled[^>]*tabindex="-1"/)
})

test("the days are buttons in a labelled group, not a grid", () => {
  const html = renderCalendar(state, text)
  assert.match(html, /role="group" aria-label="October 2026"/)
  assert.doesNotMatch(html, /role="grid"/)
})

test("the arrows are the icons given, or a typographic arrow", () => {
  assert.match(renderCalendar(state, text), />‹<\/button>/)
  const html = renderCalendar(state, {...text, previousIcon: "<svg>L</svg>", nextIcon: "<svg>R</svg>"})
  assert.match(html, /data-nav="-1"[^>]*><svg>L<\/svg><\/button>/)
  assert.match(html, /data-nav="1"[^>]*><svg>R<\/svg><\/button>/)
})

test("the days between the ends of a range say so to a screen reader", () => {
  const html = renderCalendar(state, {...text, insideLabel: "in the range"})
  assert.match(html, /data-day="2026-10-16"[^>]*aria-label="day 2026-10-16, in the range"/)
  assert.match(html, /data-day="2026-10-15"[^>]*aria-label="day 2026-10-15"/)
  assert.doesNotMatch(renderCalendar(state, text), /in the range/)
})

test("a day's classes follow what it is", () => {
  assert.match(dayClass({edge: true}), /bg-ink/)
  assert.match(dayClass({inside: true}), /bg-wrap/)
  assert.match(dayClass({off: true}), /cursor-not-allowed/)
  assert.match(dayClass({today: true}), /ring-1/)
  assert.doesNotMatch(dayClass({edge: true, today: true}), /ring-1/)
})

test("a label with quotes cannot break out of its attribute", () => {
  const html = renderCalendar(
    state,
    {...text, previous: '" autofocus onfocus="alert(1)', next: "<b>"},
  )

  assert.ok(!html.includes('" autofocus'))
  assert.ok(html.includes("&quot; autofocus"))
  assert.ok(html.includes("&lt;b&gt;"))
})

test("escapeHtml covers the five characters", () => {
  assert.equal(escapeHtml(`<a href="x">&'`), "&lt;a href=&quot;x&quot;&gt;&amp;&#39;")
})

const rangeText = {
  title: "October 2026",
  weekdays: ["S", "M", "T", "W", "T", "F", "S"],
  previousLabel: "Previous",
  nextLabel: "Next",
  dayLabel: (iso) => `day ${iso}`,
}
const rangeState = {view: {year: 2026, month: 9}, from: "2026-10-01", to: "2026-10-15", focus: "2026-10-15", today: "2026-10-15", min: null, weekStart: 0}

test("a range month has a cell per day, the band behind the range and the month button on its outer side", () => {
  const first = renderRangeMonth({...rangeState, previous: true}, rangeText)
  const second = renderRangeMonth({...rangeState, next: true}, rangeText)
  assert.equal((first.match(/data-day=/g) ?? []).length, 31)
  assert.match(first, /data-nav="-1" aria-label="Previous"/)
  assert.doesNotMatch(first, /data-nav="1"/)
  assert.match(second, /data-nav="1" aria-label="Next"/)
  assert.doesNotMatch(second, /data-nav="-1"/)
  assert.equal((first.match(/class="flex h-\[38px\] items-center justify-center bg-wrap/g) ?? []).length, 15)
})

test("the ends of the range are inverted, today has a dot, and the day the keyboard lands on is in the tab order", () => {
  const html = renderRangeMonth(rangeState, rangeText)
  assert.match(html, /data-day="2026-10-01"[^>]*aria-pressed="true"/)
  assert.match(html, /data-day="2026-10-08"[^>]*aria-pressed="false"/)
  assert.match(html, /data-day="2026-10-15"[^>]*tabindex="0"[^>]*aria-current="date"/)
  assert.match(html, /bg-on-primary/)
  assert.equal((html.match(/tabindex="0"/g) ?? []).length, 1)
})

test("days before the minimum are disabled and the classes follow what a day is", () => {
  const html = renderRangeMonth({...rangeState, from: null, to: null, min: "2026-10-10"}, rangeText)
  assert.match(html, /data-day="2026-10-09" disabled/)
  assert.doesNotMatch(html, /data-day="2026-10-10" disabled/)
  assert.match(rangeDayClass({edge: true, off: false}), /bg-ink/)
  assert.match(rangeDayClass({edge: false, off: true}), /cursor-not-allowed/)
  assert.equal(bandClass({paints: true, roundStart: true, roundEnd: false}), "bg-wrap rounded-l-[10px]")
  assert.equal(bandClass({paints: false, roundStart: false, roundEnd: false}), "")
})
