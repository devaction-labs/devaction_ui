/**
 * What a group of resizable panels decides without a DOM: the sizes (percentages that add up to 100) after a
 * divider moves, the step of a key, the keys of a divider and the limits it reports to assistive technology.
 */
import {clamp} from "./numbers.js"

const STEP = 2
const LARGE_STEP = 10

const tidy = (value) => Math.round(value * 100) / 100

/**
 * The sizes after the divider that follows panel `index` moves by `delta` percent: panel `index` grows by that
 * much and the next panel shrinks by it (the other panels do not change, and the two together keep their total),
 * and neither goes past its own limits.
 *
 * @param {number[]} sizes
 * @param {number} index the panel before the divider
 * @param {number} delta
 * @param {{min: number, max: number}[]} limits one per panel, in percent
 */
export const moveDivider = (sizes, index, delta, limits) => {
  const total = sizes[index] + sizes[index + 1]
  const low = Math.max(limits[index].min, total - limits[index + 1].max)
  const high = Math.min(limits[index].max, total - limits[index + 1].min)
  const first = tidy(clamp(sizes[index] + delta, low, Math.max(low, high)))
  return sizes.map((size, at) => ({[index]: first, [index + 1]: tidy(total - first)})[at] ?? size)
}

/**
 * The sizes with the two panels around divider `index` set to share their total equally (a double click), held
 * to their limits.
 */
export const resetDivider = (sizes, index, limits) => moveDivider(sizes, index, (sizes[index + 1] - sizes[index]) / 2, limits)

/**
 * How far a pointer that moved `distance` pixels moves a divider, in percent of the room the panels share
 * (the length of the group without its dividers).
 */
export const pixelsToPercent = (distance, room) => (room > 0 ? (distance / room) * 100 : 0)

const ARROWS = {
  horizontal: {ArrowLeft: -1, ArrowRight: 1},
  vertical: {ArrowUp: -1, ArrowDown: 1},
}

/**
 * What a key does to a divider: `{delta}` percent for an arrow of its axis (Shift takes the larger step),
 * `{to: "min" | "max"}` for Home and End, `undefined` for a key it does not use.
 *
 * @param {string} key
 * @param {boolean} shift
 * @param {"horizontal" | "vertical"} orientation
 */
export const dividerKey = (key, shift, orientation) => {
  const direction = ARROWS[orientation][key]
  const ends = {Home: {to: "min"}, End: {to: "max"}}[key]
  return direction === undefined ? ends : {delta: direction * (shift ? LARGE_STEP : STEP)}
}

/** The sizes with divider `index` at its smallest or largest (`to`) as the limits of both panels allow. */
export const dividerEnd = (sizes, index, limits, to) => moveDivider(sizes, index, to === "min" ? -100 : 100, limits)

/**
 * What the divider after panel `index` reports to assistive technology: the size of that panel and the smallest
 * and largest it may be (its own limits, held so that the next panel keeps its own).
 *
 * @returns {{now: number, min: number, max: number}}
 */
export const dividerValues = (sizes, index, limits) => {
  const total = sizes[index] + sizes[index + 1]
  return {
    now: Math.round(sizes[index]),
    min: Math.ceil(Math.max(limits[index].min, total - limits[index + 1].max)),
    max: Math.floor(Math.min(limits[index].max, total - limits[index + 1].min)),
  }
}

/** The sizes as the page gave them (`data-size`), or an equal share when it did not give all of them. */
export const startSizes = (texts) => {
  const given = texts.map((text) => Number.parseFloat(text ?? ""))
  return given.every((size) => Number.isFinite(size)) ? given : texts.map(() => tidy(100 / texts.length))
}

/** A limit read from `data-min` or `data-max`, or `fallback` (the open end of the range) when there is none. */
export const limit = (text, fallback) => {
  const value = Number.parseFloat(text ?? "")
  return Number.isFinite(value) ? value : fallback
}
