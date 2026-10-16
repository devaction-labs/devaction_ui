/** How long a pause ends the letters typed so far, in milliseconds. */
const PAUSE = 500

/** @param {KeyboardEvent} event whether the key is a letter or digit that types ahead (not a shortcut, not Space) */
export const isTypeahead = (event) =>
  event.key.length === 1 && event.key !== " " && !event.ctrlKey && !event.metaKey && !event.altKey

/**
 * The letters typed so far with `key` added; a pause longer than `PAUSE` starts them over.
 *
 * @param {string} buffer
 * @param {string} key
 * @param {number} elapsed milliseconds since the last key
 */
export const extendBuffer = (buffer, key, elapsed) => (elapsed > PAUSE ? "" : buffer) + key.toLowerCase()

/**
 * The index of the item the letters jump to, or `-1`. One letter (or the same letter again and again) goes
 * round the items that start with it, from the one after the active; more letters stay on the first item that
 * starts with all of them, the active one included.
 *
 * @param {string[]} labels the text of each item
 * @param {number} active the index of the focused item, `-1` for none
 * @param {string} buffer the letters typed, lower case
 */
export const matchIndex = (labels, active, buffer) => {
  const repeated = [...buffer].every((letter) => letter === buffer[0])
  const needle = repeated ? buffer[0] : buffer
  const from = repeated ? active + 1 : Math.max(active, 0)
  const order = labels.map((_, offset) => (from + offset) % labels.length)
  return order.find((index) => labels[index].trim().toLowerCase().startsWith(needle)) ?? -1
}

/** Whether choosing an item closes the menu: `data-close-on-select` is `"false"` for a menu that stays open. */
export const closesOnSelect = (value) => value !== "false"
