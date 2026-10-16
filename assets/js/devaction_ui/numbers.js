

/**
 * The arithmetic of the numeric fields: decimal numbers as integers scaled by a power of ten (a number is
 * `{int, scale}`, `0.25` is `{25, 2}`, so a sum never drifts the way `0.1 + 0.2` does), the money mask, the
 * positions of the range sliders and the clock of the timer. Nothing here reads the DOM or the clock.
 */

/** `value` held between `min` and `max`. */
export const clamp = (value, min, max) => Math.min(Math.max(value, min), max)

/** A number read from text, or `null` when the text is not one (or too long to be exact). Text takes a dot or a comma. */
export const scaled = (text) => {
  const found = /^\s*([+-]?)(\d+)(?:[.,](\d+))?\s*$/.exec(text ?? "")
  const decimals = found?.[3] ?? ""
  const int = found === null ? NaN : Number(`${found[1]}${found[2]}${decimals}`)
  return Number.isSafeInteger(int) ? {int, scale: decimals.length} : null
}

const align = (a, b) => {
  const scale = Math.max(a.scale, b.scale)
  return [a.int * 10 ** (scale - a.scale), b.int * 10 ** (scale - b.scale), scale]
}

export const add = (a, b) => {
  const [x, y, scale] = align(a, b)
  return {int: x + y, scale}
}

const times = (a, factor) => ({int: a.int * factor, scale: a.scale})

const minus = (a, b) => add(a, times(b, -1))

/** `-1`, `0` or `1` as `a` is less than, equal to or greater than `b`. */
export const compare = (a, b) => {
  const [x, y] = align(a, b)
  return Math.sign(x - y)
}

const isZero = (a) => a.int === 0

/** `value` inside `min` and `max`; a limit that is `null` does not apply. */
export const clampScaled = (value, min, max) => {
  const low = min !== null && compare(value, min) < 0 ? min : value
  return max !== null && compare(low, max) > 0 ? max : low
}

const away = (int, unit) => {
  const half = Math.abs(int) * 2 + unit
  const whole = (half - (half % (unit * 2))) / (unit * 2)
  return Math.sign(int) * whole
}

const rescale = ({int, scale}, precision) =>
  scale <= precision ? int * 10 ** (precision - scale) : away(int, 10 ** (scale - precision))

/** The number as text with exactly `precision` decimals (rounded half away from zero) and `decimal` between. */
export const render = (number, precision, decimal = ".") => {
  const int = rescale(number, precision)
  const digits = String(Math.abs(int)).padStart(precision + 1, "0")
  const cut = digits.length - precision
  const body = precision === 0 ? digits : `${digits.slice(0, cut)}${decimal}${digits.slice(cut)}`
  return `${int < 0 ? "-" : ""}${body}`
}

const trim = (number) =>
  number.scale > 0 && number.int % 10 === 0 ? trim({int: number.int / 10, scale: number.scale - 1}) : number

/** The number as text with only the decimals it has (`0.25`, `-3`): what is sent to the server. */
export const plain = (number) => render(trim(number), trim(number).scale)

/** A limit read from a `data-*` attribute: nothing when it is absent or empty. */
export const parseLimit = (text) => (text === undefined || text === "" ? null : scaled(text))

/**
 * What each key of a spinbutton asks for: the value it goes to, given where the field is. The arrows move a step,
 * the page keys ten, Home and End go to the limits (and do nothing where there is none).
 */
const TARGETS = {
  ArrowUp: ({current, step}) => add(current, step),
  ArrowDown: ({current, step}) => minus(current, step),
  PageUp: ({current, step}) => add(current, times(step, 10)),
  PageDown: ({current, step}) => minus(current, times(step, 10)),
  Home: ({min}) => min,
  End: ({max}) => max,
}

export const NUMBER_KEYS = Object.keys(TARGETS)

/**
 * The signed amount `key` moves a field showing `raw`, as text for `phx-value-step`, or `null` when it moves
 * nothing: the key is not one of the spinbutton's, the text is not a number, there is no limit for Home or End,
 * or the value is already where the key goes.
 */
export const keyDelta = (key, raw, {step, min, max}) => {
  const current = scaled(raw)
  const target = current === null ? undefined : TARGETS[key]?.({current, step, min, max})
  const next = target === undefined || target === null ? null : clampScaled(target, min, max)
  const delta = next === null ? null : minus(next, current)
  return delta === null || isZero(delta) ? null : plain(delta)
}

/**
 * What was typed, held inside `min` and `max` and shown with `precision` decimals and `decimal` as the
 * separator; text that is not a number is left as it is.
 */
export const clampText = (raw, {min, max, precision = 0, decimal = "."}) => {
  const typed = scaled(raw)
  return typed === null ? raw : render(clampScaled(typed, min, max), precision, decimal)
}

const BRL = {decimal: ",", group: ".", precision: 2, signed: false}

/**
 * Money as typed: digits only in, `1.234,56` out (the currency sign is the add-on beside the field), the last
 * `precision` digits being the minor units. Nothing typed is nothing shown. With `signed`, a `-` anywhere in
 * the text makes the amount negative, and alone it is kept as a sign waiting for its digits. The defaults are the
 * Brazilian real; every option is a `data-*` of the field.
 */
export const formatMoney = (typed, options = {}) => {
  const {decimal, group, precision, signed} = {...BRL, ...options}
  const digits = typed.replace(/\D/g, "")
  const sign = signed && typed.includes("-") ? "-" : ""
  const padded = digits.padStart(precision + 1, "0")
  const cut = padded.length - precision
  const whole = padded.slice(0, cut).replace(/^0+(?=\d)/, "").replace(/\B(?=(\d{3})+(?!\d))/g, () => group)
  const amount = precision === 0 ? whole : `${whole}${decimal}${padded.slice(cut)}`
  return digits === "" ? sign : `${sign}${amount}`
}

/** Brazilian reais as typed: `formatMoney` with its defaults. */
export const formatReais = (typed) => formatMoney(typed)

/** The options of the field, read from its `data-*` attributes; what is absent keeps the default. */
export const moneyOptions = (dataset) => ({
  ...(dataset.decimal === undefined ? {} : {decimal: dataset.decimal}),
  ...(dataset.group === undefined ? {} : {group: dataset.group}),
  ...(dataset.precision === undefined ? {} : {precision: Number(dataset.precision)}),
  signed: dataset.signed === "true",
})

/**
 * Where the caret goes after `before` became `after`: at the end when it was at the end, else after the same
 * number of digits as before, so editing in the middle does not jump to the end.
 */
export const caretAfter = (before, caret, after) => {
  const digitsBefore = before.slice(0, caret).replace(/\D/g, "").length
  const at = [...after].flatMap((char, index) => (/\d/.test(char) ? [index] : []))
  const signed = before.slice(0, caret).includes("-") && after.startsWith("-")
  const inside = digitsBefore === 0 ? Number(signed) : (at[digitsBefore - 1] ?? after.length - 1) + 1
  return caret >= before.length ? after.length : inside
}

export function percent(value, min, max) {
  const span = Number(max) - Number(min)
  return span <= 0 ? 0 : ((Number(value) - Number(min)) / span) * 100
}

/**
 * The pair `[low, high]` after the thumb `moved` (`"low"` or `"high"`) was dragged: that thumb stops at the
 * other one, so the two never cross.
 */
export const clampPair = (low, high, moved) => PAIR[moved](Number(low), Number(high))

const PAIR = {
  low: (a, b) => ({low: Math.min(a, b), high: b}),
  high: (a, b) => ({low: a, high: Math.max(a, b)}),
}

/** The left edge and the width, in percent, of the filled part between two values. */
export function fillBox(low, high, min, max) {
  const from = percent(low, min, max)
  return {left: from, width: percent(high, min, max) - from}
}

/** Where a value sits between `min` and `max` as a fraction, from 0 to 1: the `--f` of a value bubble. */
export const fraction = (value, min, max) => percent(value, min, max) / 100

const FILL = {horizontal: ["left", "width"], vertical: ["bottom", "height"]}

/** The inline style of the filled part of a pair: it grows from the left, or from the bottom when vertical. */
export function fillStyle(orientation, box) {
  const [start, size] = FILL[orientation] ?? FILL.horizontal
  return {[start]: `${box.left}%`, [size]: `${box.width}%`}
}

/** A template with its `%{value}` filled; no template means the number as it is. */
export const valueText = (template, value) => (template ?? "%{value}").replaceAll("%{value}", String(value))

/** The text of the value beside a range slider: both ends, joined by an en dash. */
export const pairText = (template, low, high) => `${valueText(template, low)} – ${valueText(template, high)}`

/** Seconds as `HH:MM:SS`, the same text the server draws. */
export function formatClock(seconds) {
  const whole = Math.max(0, Math.floor(seconds))
  const hours = Math.floor(whole / 3600)
  const minutes = Math.floor((whole % 3600) / 60)
  const pad = (number) => String(number).padStart(2, "0")
  return `${pad(hours)}:${pad(minutes)}:${pad(whole % 60)}`
}

/** Seconds as `HH:MM`, the seconds dropped. */
export function formatShort(seconds) {
  return formatClock(seconds).slice(0, 5)
}

/** The writer of each `data-format` of the element: the whole time, or hours and minutes. */
export const formats = {full: formatClock, short: formatShort}

/** The seconds counted: the base plus, while running, the time since it started (both in seconds). */
export function elapsed({base, startedAt, nowSeconds}) {
  return startedAt === null ? base : base + Math.max(0, nowSeconds - startedAt)
}

/** What the element says: its numbers (or `null` for the start of a paused timer). */
export function readTimer(dataset) {
  const number = (text) => (text === undefined || text === "" ? null : Number(text))
  return {base: number(dataset.base) ?? 0, startedAt: number(dataset.startedAt), serverNow: number(dataset.now)}
}
