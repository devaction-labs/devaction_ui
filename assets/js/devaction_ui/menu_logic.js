/**
 * What the menus and lists decide without a DOM: the letters typed ahead in a dropdown, the counts of the filter
 * menu, what the combobox button shows and the ARIA state of the autocomplete list.
 */
import {chooseSide, fixedCorner} from "./placement.js"

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

/**
 * How many options of each group are ticked, and how many in all, not counting the ones that are the
 * default (a default is what the filter already means before anyone picks anything).
 *
 * @param {{group: string, checked: boolean, isDefault: boolean}[]} options
 */
export function counts(options) {
  const ticked = options.filter((option) => option.checked && !option.isDefault)
  const byGroup = ticked.reduce((all, option) => ({...all, [option.group]: (all[option.group] ?? 0) + 1}), {})
  return {byGroup, total: ticked.length}
}

const keyOf = (option) => `${option.group}\u0000${option.value}`

/**
 * How many options are ticked differently in the draft than in what was applied: the changes that Apply
 * would send.
 *
 * @param {{group: string, value: string, checked: boolean}[]} draft
 * @param {{group: string, value: string, checked: boolean}[]} applied
 */
export function pendingCount(draft, applied) {
  const ticked = (options) => new Set(options.filter((option) => option.checked).map(keyOf))
  const now = ticked(draft)
  const before = ticked(applied)
  return [...now].filter((key) => !before.has(key)).length + [...before].filter((key) => !now.has(key)).length
}

/**
 * What Clear does after it unticks everything: `"submit"` sends the form (the empty filters are applied), and
 * anything else only tells the form it changed, as a tick does.
 *
 * @param {string | undefined} mode the `data-reset` of the menu
 * @returns {"submit" | "change"}
 */
export const resetAction = (mode) => (mode === "submit" ? "submit" : "change")

/**
 * What the button shows: the label of the chosen option, or the placeholder (muted) when nothing is chosen.
 *
 * @param {{label: string} | null | undefined} option
 * @param {string} placeholder
 * @returns {{text: string, muted: boolean}}
 */
export const buttonView = (option, placeholder) => ({text: option?.label ?? placeholder, muted: !option})

/**
 * Whether the field should say its list is open: there is a list, it is showing, and it has a row to move
 * to (a list that only says "nothing found" is not open as far as the keys go).
 *
 * @param {{hasList: boolean, visible: boolean, options: number}} state
 */
export const isExpanded = ({hasList, visible, options}) => hasList && visible && options > 0

/**
 * The `aria-selected` of each of `count` rows when row `active` is the active one (`-1` for none).
 *
 * @param {number} count
 * @param {number} active
 * @returns {string[]}
 */
export const selectedStates = (count, active) => Array.from({length: count}, (_, index) => String(index === active))

/** Whether a key press asks for the context menu: the menu key, or Shift + F10. */
export const asksForContextMenu = (event) => event.key === "ContextMenu" || (event.key === "F10" && event.shiftKey)

/**
 * The point a context menu opens at when the keyboard asks for it: near the start of the focused element and a
 * little above its lower edge, so the menu hangs from the element and not from the middle of the screen.
 *
 * @param {{left: number, top: number, width: number, height: number}} rect the focused element
 */
export const keyboardAnchor = (rect) => ({x: rect.left + Math.min(rect.width / 2, 32), y: rect.top + rect.height - 4})

/**
 * Where a menu with `position: fixed` goes under (or over) its button: the side that has room, the corner
 * aligned to the start or the end of the button, kept inside the screen. This is what lets a menu in a table or a
 * scroll area open without being cut by the `overflow` of its parents.
 *
 * @param {"start" | "end"} align
 * @param {DOMRect} anchor the button
 * @param {{width: number, height: number}} panel the menu
 * @param {{width: number, height: number}} screen
 * @returns {{side: "top" | "bottom", top: number, left: number}}
 */
export const placeFixed = (align, anchor, panel, screen) => {
  const side = chooseSide("bottom", {panel: panel.height, above: anchor.top, below: screen.height - anchor.bottom})
  const {top, left} = fixedCorner({side, align, anchor, panel, screen})
  return {side, top: Math.round(top), left: Math.round(left)}
}
