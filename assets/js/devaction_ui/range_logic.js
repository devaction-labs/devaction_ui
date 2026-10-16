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

/** A template with its `%{value}` filled; no template means the number as it is. */
export const valueText = (template, value) => (template ?? "%{value}").replaceAll("%{value}", String(value))

/** The text of the value beside a range slider: both ends, joined by an en dash. */
export const pairText = (template, low, high) => `${valueText(template, low)} – ${valueText(template, high)}`
