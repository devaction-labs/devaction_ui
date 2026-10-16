import {clampMin, daysInMonth, leadingDays, toIso} from "./dates.js"

const ESCAPES = {"&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;"}

/** Text made safe to put in HTML, in an element or in a quoted attribute. */
export const escapeHtml = (text) => String(text).replace(/[&<>"']/g, (char) => ESCAPES[char])

const NAV_BUTTON =
  "flex size-[34px] items-center justify-center rounded-[9px] border border-line bg-card outline-none hover:bg-wrap focus-visible:ring-2 focus-visible:ring-ink/20"

/** The classes of a day, from what it is: an end of the selection, inside it, out of reach, today. */
export const dayClass = ({edge, inside, off, today}) =>
  [
    "h-9 rounded-lg text-[13px] outline-none focus-visible:ring-2 focus-visible:ring-ink/30",
    edge && "bg-ink font-semibold text-on-primary",
    !edge && inside && "rounded-none bg-wrap text-ink",
    !edge && !inside && off && "cursor-not-allowed text-muted-2",
    !edge && !inside && !off && "text-ink hover:bg-wrap",
    today && !edge && "font-semibold ring-1 ring-inset ring-ink",
  ]
    .filter(Boolean)
    .join(" ")

/**
 * The calendar for one month as HTML: the header with the two month buttons, the weekday names and a button
 * per day. Everything that depends on the language comes in `text` (already formatted), so this is a plain
 * function of its arguments.
 *
 * @param {{view: {year: number, month: number}, from: ?string, to: ?string, focus: string, today: string, min: ?string, weekStart: number}} state
 * `previousIcon` and `nextIcon` are trusted HTML from the server (the icon slots); `insideLabel` is added to the
 * name of the days between the ends of a range.
 *
 * @param {{title: string, weekdays: string[], previous: string, next: string, dayLabel: (iso: string) => string, previousIcon?: string, nextIcon?: string, insideLabel?: string}} text
 */
export const renderCalendar = (state, text) => {
  const {view, from, to, today, min, weekStart} = state
  const focus = clampMin(state.focus, min)
  const days = [...Array(daysInMonth(view))].map((_, index) => {
    const iso = toIso(view.year, view.month, index + 1)
    const edge = iso === from || iso === to
    const inside = Boolean(from && to && iso > from && iso < to)
    const off = min !== null && min !== undefined && iso < min
    const classes = dayClass({edge, inside, off, today: iso === today})
    const name = inside && text.insideLabel ? `${text.dayLabel(iso)}, ${text.insideLabel}` : text.dayLabel(iso)

    return (
      `<button type="button" data-day="${iso}" ${off ? "disabled" : ""} aria-pressed="${edge}" ` +
      `aria-label="${escapeHtml(name)}" tabindex="${iso === focus ? 0 : -1}" ` +
      `${iso === today ? 'aria-current="date"' : ""} class="${classes}">${index + 1}</button>`
    )
  })

  return (
    `<div class="flex items-center justify-between">` +
    `<button type="button" data-nav="-1" aria-label="${escapeHtml(text.previous)}" class="${NAV_BUTTON}">${text.previousIcon ?? "‹"}</button>` +
    `<span class="font-semibold" aria-live="polite">${escapeHtml(text.title)}</span>` +
    `<button type="button" data-nav="1" aria-label="${escapeHtml(text.next)}" class="${NAV_BUTTON}">${text.nextIcon ?? "›"}</button></div>` +
    `<div role="group" aria-label="${escapeHtml(text.title)}" class="mt-2 grid grid-cols-7 gap-0.5 text-center">` +
    text.weekdays.map((name) => `<span class="py-1 font-mono text-[11px] text-muted">${escapeHtml(name)}</span>`).join("") +
    "<span></span>".repeat(leadingDays(view, weekStart)) +
    days.join("") +
    "</div>"
  )
}
