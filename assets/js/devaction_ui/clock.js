/**
 * Times of day as `"HH:MM"` text and as minutes since midnight: the mask of a time field, how a half-typed time is
 * completed, the suggestions around a time with the length of each, and the text of a length. Nothing here reads
 * the clock or the time zone, and the words (`h`, `min`) come in as patterns from the caller.
 */

const LAST = 24 * 60 - 1

const pad = (value) => String(value).padStart(2, "0")

const digitsOf = (text) => text.replace(/\D/g, "").slice(0, 4)

/** `"09:30"` as 570 minutes. */
export const toMinutes = (text) => {
  const [hours, minutes] = text.split(":").map(Number)
  return hours * 60 + minutes
}

/** 570 minutes as `"09:30"`. */
export const fromMinutes = (minutes) => `${pad(Math.floor(minutes / 60))}:${pad(minutes % 60)}`

/** What a person types, laid out as a time: only digits, at most four, with the colon after the hour. */
export const maskClock = (raw) => {
  const digits = digitsOf(raw)
  return digits.length > 2 ? `${digits.slice(0, 2)}:${digits.slice(2)}` : digits
}

const COMPLETIONS = {
  1: (digits) => `0${digits}00`,
  2: (digits) => `${digits}00`,
  3: (digits) => `0${digits}`,
  4: (digits) => digits,
}

/** A typed time finished the way a person means it (`9` is 09:00, `930` is 09:30), or `null` when no such time exists. */
export const completeClock = (text) => {
  const full = COMPLETIONS[digitsOf(text).length]?.(digitsOf(text))
  const valid = full !== undefined && Number(full.slice(0, 2)) < 24 && Number(full.slice(2)) < 60
  return valid ? `${full.slice(0, 2)}:${full.slice(2)}` : null
}

/** The time one step later (`direction` 1) or earlier (-1), on the grid of `step` minutes, held inside the day. */
export const stepClock = (minutes, direction, step) =>
  ({
    1: () => Math.min((Math.floor(minutes / step) + 1) * step, Math.floor(LAST / step) * step),
    [-1]: () => Math.max((Math.ceil(minutes / step) - 1) * step, 0),
  })[direction]()

/** The suggestions: `before` steps before `center`, `center` itself and `after` steps after, as minutes, inside the day. */
export const suggestions = (center, step, {before = 3, after = 4} = {}) =>
  Array.from({length: before + after + 1}, (_, index) => center + (index - before) * step).filter(
    (minutes) => minutes >= 0 && minutes <= LAST,
  )

/** How long it is from `start` to `end`, never negative. */
export const lengthBetween = (start, end) => Math.max(0, end - start)

/** The length of a suggestion counted from `start`, or `null` for one that is not after it. */
export const hintFor = (option, start) => (option > start ? option - start : null)

const fill = (pattern, count) => pattern.replaceAll("%{count}", String(count))

/**
 * A length as text from two patterns with `%{count}` (such as `"%{count} h"` and `"%{count} min"`):
 * 135 is `2 h 15 min`, 120 is `2 h`, 45 is `45 min`, 0 is `0 min`.
 */
export const lengthText = (minutes, {hours, minutes: minutePattern}) =>
  [
    Math.floor(minutes / 60) > 0 && fill(hours, Math.floor(minutes / 60)),
    (minutes % 60 > 0 || minutes === 0) && fill(minutePattern, minutes % 60),
  ]
    .filter(Boolean)
    .join(" ")
