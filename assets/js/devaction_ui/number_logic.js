/** How many steps each key of a spinbutton moves: the arrows one, the page keys ten. */
export const STEP_KEYS = {ArrowUp: 1, ArrowDown: -1, PageUp: 10, PageDown: -10}

/** A limit read from a `data-*` attribute: nothing when it is absent or empty. */
export const parseLimit = (text) => (text === undefined || text === "" ? null : Number(text))

/** `value` inside `min` and `max`; a limit that is `null` does not apply. */
export const clamp = (value, min, max) => Math.min(Math.max(value, min ?? -Infinity), max ?? Infinity)

/**
 * The signed amount `key` moves a field showing `raw`, or `null` when it moves nothing: the key is not one of
 * the spinbutton's, the text is not a whole number, or the value is already at the limit that way.
 */
export const keyDelta = (key, raw, {step, min, max}) => {
  const multiplier = STEP_KEYS[key]
  const current = Number.parseInt(raw, 10)
  const known = multiplier !== undefined && Number.isFinite(current)
  const next = known ? clamp(current + multiplier * step, min, max) : current
  return known && next !== current ? next - current : null
}

/** What was typed, held inside `min` and `max`; text that is not a whole number is left as it is. */
export const clampText = (raw, {min, max}) =>
  /^-?\d+$/.test(raw.trim()) ? String(clamp(Number.parseInt(raw, 10), min, max)) : raw
