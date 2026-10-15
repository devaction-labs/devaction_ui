/**
 * Calendar arithmetic on ISO dates (`"2026-10-14"`), always in UTC so the browser's time zone never moves a
 * day. The server decides what "today" is; nothing here reads the clock.
 */

const parse = (iso) => {
  const [year, month, day] = iso.split("-").map(Number)
  return new Date(Date.UTC(year, month - 1, day))
}

const format = (date) => date.toISOString().slice(0, 10)

export const toIso = (year, month, day) => format(new Date(Date.UTC(year, month, day)))

/** `{year, month}` (month 0-11) of an ISO date. */
export const monthOf = (iso) => {
  const date = parse(iso)
  return {year: date.getUTCFullYear(), month: date.getUTCMonth()}
}

export const dayOf = (iso) => parse(iso).getUTCDate()

export const addDays = (iso, days) => {
  const date = parse(iso)
  date.setUTCDate(date.getUTCDate() + days)
  return format(date)
}

export const addMonths = (iso, months) => {
  const date = parse(iso)
  date.setUTCMonth(date.getUTCMonth() + months)
  return format(date)
}

export const daysInMonth = ({year, month}) => new Date(Date.UTC(year, month + 1, 0)).getUTCDate()

/** The month `months` away from `{year, month}`. */
export const shiftMonth = ({year, month}, months) => {
  const date = new Date(Date.UTC(year, month + months, 1))
  return {year: date.getUTCFullYear(), month: date.getUTCMonth()}
}

/** The same day number in another month, held to that month's last day (31 Jan → 28 Feb). */
export const sameDayIn = (iso, view) => toIso(view.year, view.month, Math.min(dayOf(iso), daysInMonth(view)))

/** How many days of the previous month the first row shows, for a week starting on `weekStart` (0 = Sunday). */
export const leadingDays = ({year, month}, weekStart) =>
  (new Date(Date.UTC(year, month, 1)).getUTCDay() - weekStart + 7) % 7

/** Position of `iso` in its week, 0 for the first day of the week. */
export const weekdayIndex = (iso, weekStart) => (parse(iso).getUTCDay() - weekStart + 7) % 7

/** Where a key moves the focused day, or `undefined` for a key that does not move it. */
const moves = {
  ArrowLeft: (iso) => addDays(iso, -1),
  ArrowRight: (iso) => addDays(iso, 1),
  ArrowUp: (iso) => addDays(iso, -7),
  ArrowDown: (iso) => addDays(iso, 7),
  PageUp: (iso) => addMonths(iso, -1),
  PageDown: (iso) => addMonths(iso, 1),
  Home: (iso, weekStart) => addDays(iso, -weekdayIndex(iso, weekStart)),
  End: (iso, weekStart) => addDays(iso, 6 - weekdayIndex(iso, weekStart)),
}

export const moveFocus = (key, iso, weekStart) => moves[key]?.(iso, weekStart)

import {decide} from "./rules.js"

/** The rules of a range, tried in order: the first whose test passes decides the new range. */
const rangeRules = [
  [({from, to}) => !from || to, (_range, iso) => ({from: iso, to: null})],
  [({from}, iso) => iso < from, (_range, iso) => ({from: iso, to: null})],
  [() => true, ({from}, iso) => ({from, to: iso})],
]

/**
 * The selection after picking `iso`: one day in `single` mode; in `range` mode the first pick starts it,
 * a pick before the start restarts it, the next pick closes it, and one after a closed range starts anew.
 */
export const pick = (selection, iso, mode) =>
  mode === "range" ? decide(rangeRules, selection, iso) : {from: iso, to: null}
