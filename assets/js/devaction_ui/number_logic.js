/**
 * Decimal arithmetic on integers scaled by a power of ten: a number is `{int, scale}` (`0.25` is `{25, 2}`), so a
 * sum never drifts the way `0.1 + 0.2` does. Text takes a dot or a comma as the separator.
 */

/** A number read from text, or `null` when the text is not one (or too long to be exact). */
export const scaled = (text) => {
  const found = /^\s*([+-]?)(\d+)(?:[.,](\d+))?\s*$/.exec(text ?? "")
  const fraction = found?.[3] ?? ""
  const int = found === null ? NaN : Number(`${found[1]}${found[2]}${fraction}`)
  return Number.isSafeInteger(int) ? {int, scale: fraction.length} : null
}

const align = (a, b) => {
  const scale = Math.max(a.scale, b.scale)
  return [a.int * 10 ** (scale - a.scale), b.int * 10 ** (scale - b.scale), scale]
}

export const add = (a, b) => {
  const [x, y, scale] = align(a, b)
  return {int: x + y, scale}
}

export const times = (a, factor) => ({int: a.int * factor, scale: a.scale})

export const minus = (a, b) => add(a, times(b, -1))

/** `-1`, `0` or `1` as `a` is less than, equal to or greater than `b`. */
export const compare = (a, b) => {
  const [x, y] = align(a, b)
  return Math.sign(x - y)
}

export const isZero = (a) => a.int === 0

/** `value` inside `min` and `max`; a limit that is `null` does not apply. */
export const clamp = (value, min, max) => {
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
  const next = target === undefined || target === null ? null : clamp(target, min, max)
  const delta = next === null ? null : minus(next, current)
  return delta === null || isZero(delta) ? null : plain(delta)
}

/**
 * What was typed, held inside `min` and `max` and shown with `precision` decimals and `decimal` as the
 * separator; text that is not a number is left as it is.
 */
export const clampText = (raw, {min, max, precision = 0, decimal = "."}) => {
  const typed = scaled(raw)
  return typed === null ? raw : render(clamp(typed, min, max), precision, decimal)
}
