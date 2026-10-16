/**
 * Calendar arithmetic on ISO dates (`"2026-10-14"`), always in UTC so the browser's time zone never moves a
 * day, and the text of a date field (its mask and its reading). The server decides what "today" is; nothing
 * here reads the clock.
 */
import {decide} from "./keys.js"

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

const dayOf = (iso) => parse(iso).getUTCDate()

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

/** `iso`, or the minimum when `iso` is before it (a day that cannot be picked cannot be where the keyboard lands). */
export const clampMin = (iso, min) => (min && iso < min ? min : iso)

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

/**
 * The text of a date field: a mask that takes only digits and puts the separators in, and the reading of the
 * text back into an ISO date (`"2026-10-16"`). `order` is `"dmy"`, `"mdy"` or `"ymd"`; `separator` is the
 * character between the parts. Nothing here reads the clock or the time zone.
 */

const sizes = {dmy: [2, 2, 4], mdy: [2, 2, 4], ymd: [4, 2, 2]}
const keys = {dmy: ["day", "month", "year"], mdy: ["month", "day", "year"], ymd: ["year", "month", "day"]}

const DIGITS = 8

/** The digits of `raw` (at most eight) laid out in the parts of the format: `"1610"` becomes `"16/10"`. */
export const maskDate = (raw, {order, separator}) => {
  const digits = raw.replace(/\D/g, "").slice(0, DIGITS)
  const parts = []
  sizes[order].reduce((rest, size) => {
    const part = rest.slice(0, size)
    part && parts.push(part)
    return rest.slice(size)
  }, digits)
  return parts.join(separator)
}

const pad = (value, size) => String(value).padStart(size, "0")

/** An ISO date written in the format of the field, or `""` for no date. */
export const formatIso = (iso, {order, separator}) => {
  const [year, month, day] = (iso ?? "").split("-")
  const parts = {year, month, day}
  return iso ? keys[order].map((key) => parts[key]).join(separator) : ""
}

const toParts = (digits, order) =>
  Object.fromEntries(
    keys[order].map((key, index) => {
      const start = sizes[order].slice(0, index).reduce((sum, size) => sum + size, 0)
      return [key, Number(digits.slice(start, start + sizes[order][index]))]
    }),
  )

const exists = ({year, month, day}) =>
  year >= 1000 && month >= 1 && month <= 12 && day >= 1 && day <= daysInMonth({year, month: month - 1})

/**
 * What the text says: `{iso, status}`, `status` being `"empty"` (nothing typed), `"partial"` (still being
 * typed), `"invalid"` (all eight digits but no such day, or a day before `min`) or `"ok"` (then `iso` is set).
 */
export const readDate = (text, format, min = null) => {
  const digits = text.replace(/\D/g, "")
  const parts = digits.length === DIGITS ? toParts(digits, format.order) : null
  const iso = parts && exists(parts) ? `${pad(parts.year, 4)}-${pad(parts.month, 2)}-${pad(parts.day, 2)}` : null

  const outcomes = [
    [digits === "", {iso: null, status: "empty"}],
    [digits.length < DIGITS, {iso: null, status: "partial"}],
    [iso === null || (min !== null && iso < min), {iso: null, status: "invalid"}],
  ]
  return outcomes.find(([applies]) => applies)?.[1] ?? {iso, status: "ok"}
}
