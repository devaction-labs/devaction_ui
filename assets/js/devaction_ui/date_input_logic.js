import {daysInMonth} from "./dates.js"

/**
 * The text of a date field: a mask that takes only digits and puts the separators in, and the reading of the
 * text back into an ISO date (`"2026-10-16"`). `order` is `"dmy"`, `"mdy"` or `"ymd"`; `separator` is the
 * character between the parts. Nothing here reads the clock or the time zone.
 */

const sizes = {dmy: [2, 2, 4], mdy: [2, 2, 4], ymd: [4, 2, 2]}
const keys = {dmy: ["day", "month", "year"], mdy: ["month", "day", "year"], ymd: ["year", "month", "day"]}

const DIGITS = 8

/** The digits of `raw` (at most eight) laid out in the parts of the format: `"1610"` becomes `"16/10"`. */
export const mask = (raw, {order, separator}) => {
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
export const read = (text, format, min = null) => {
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
