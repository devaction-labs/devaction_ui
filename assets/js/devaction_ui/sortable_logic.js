/**
 * What a sortable list decides without a DOM: the order of ids after a move, which buttons are at an end, the
 * keys of a picked-up row and the text the live region says. The list in the page is only drawn from these answers;
 * the server keeps the real order.
 */
import {clamp} from "./numbers.js"

/**
 * `order` with `id` at position `index` among the others, held between the first and the last place. An id that is
 * not in the list leaves it as it was.
 *
 * @param {string[]} order
 * @param {string} id
 * @param {number} index
 */
export const placeAt = (order, id, index) => {
  const others = order.filter((other) => other !== id)
  const at = clamp(index, 0, others.length)
  return order.includes(id) ? [...others.slice(0, at), id, ...others.slice(at)] : order
}

/**
 * `order` with `id` moved `delta` places (never past an end).
 *
 * @param {string[]} order
 * @param {string} id
 * @param {number} delta
 */
export const moveBy = (order, id, delta) => placeAt(order, id, order.indexOf(id) + delta)

/** Whether two orders are the same. */
export const sameOrder = (a, b) => a.length === b.length && a.every((id, index) => id === b[index])

/**
 * Which of the up and down buttons of the row at `index` are off: the first row cannot go up and the last cannot go down.
 *
 * @param {number} index
 * @param {number} count
 */
export const atEnds = (index, count) => ({up: index <= 0, down: index >= count - 1})

/**
 * Where a key sends a picked-up row: `step` moves it by that many places, `to` puts it at an end (`"first"` or `"last"`);
 * `undefined` for a key that does not move it.
 */
export const heldMove = (key) =>
  ({
    ArrowUp: {step: -1},
    ArrowDown: {step: 1},
    Home: {to: "first"},
    End: {to: "last"},
  })[key]

/** The index a picked-up row goes to for a `heldMove`, from where it is, among `count` rows. */
export const targetIndex = (move, from, count) => ({first: 0, last: count - 1})[move.to] ?? clamp(from + (move.step ?? 0), 0, count - 1)

/**
 * A text of the page with `__ITEM__`, `__POS__` and `__TOTAL__` replaced: the name of the row and its place.
 *
 * @param {string} template
 * @param {{item: string, pos: number, total: number}} facts
 */
export const say = (template, {item, pos, total}) =>
  template.replaceAll("__ITEM__", item).replaceAll("__POS__", String(pos)).replaceAll("__TOTAL__", String(total))
