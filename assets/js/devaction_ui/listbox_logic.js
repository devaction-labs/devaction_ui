/**
 * What the listbox decides without a DOM: the text of its button, which options a search keeps (by the label
 * and the keywords, ignoring case and accents), whether the "create" row shows, and the values after a choice.
 */
import {clampShift, flipSide, roomAround} from "./placement.js"
import {fold, matches} from "./text.js"

/** The distance between the button and the panel, and the room the panel keeps from the edge of the screen. */
const GAP = 6
const EDGE = 8
/** The shortest the list is squeezed to when the room runs out on both sides. */
const LEAST = 96

/** A text with its `%{name}` markers filled from `values`; nothing stays nothing. */
export const fill = (pattern, values) =>
  pattern == null ? pattern : Object.entries(values).reduce((text, [key, value]) => text.replaceAll(`%{${key}}`, String(value)), pattern)

/** Whether an option is kept by the search `term`: its label or its keywords contain it. */
export const keeps = ({label, keywords = ""}, term) => matches(`${label} ${keywords}`, term)

/** Whether the "create" row shows: something was typed and no option is called exactly that. */
export const canCreate = (term, labels) => term.trim() !== "" && !labels.some((label) => fold(label) === fold(term.trim()))

/**
 * The values after choosing `value`: a single listbox keeps only it, a multiple one adds it or takes it away.
 *
 * @param {string[]} values
 * @param {string} value
 * @param {boolean} multiple
 */
export const pick = (values, value, multiple) =>
  multiple ? (values.includes(value) ? values.filter((known) => known !== value) : [...values, value]) : [value]

/**
 * What the button shows: the placeholder (muted) when nothing is chosen, the label of the choice, and for a
 * multiple listbox the count text (`"%{count} chosen"`) or, without one, the labels joined.
 *
 * @param {{labels: string[], multiple: boolean, placeholder: string, countText?: string | null}} state
 */
export const buttonText = ({labels, multiple, placeholder, countText}) =>
  labels.length === 0
    ? {text: placeholder, muted: true}
    : {text: multiple && countText ? fill(countText, {count: labels.length}) : labels.join(", "), muted: false}

/**
 * Where the panel goes, in `position: fixed` coordinates: on the `wanted` side of the button unless it does not
 * fit there and the other side has more room, lined up with the start or the end of the button and kept inside
 * the screen. `edge` is where the near edge of the panel lands, to check it against the screen. A panel above the button is held by its bottom edge, so it keeps touching the button when a search
 * makes it shorter. `list` is the height the list may take on the side chosen.
 *
 * @param {{anchor: DOMRect, panel: {width: number, height: number}, chrome: number, screen: {width: number, height: number}, wanted: "top" | "bottom", align: "start" | "end"}} spec `chrome` is the height of the panel that is not the list
 * @returns {{side: "top" | "bottom", left: number, top: number | null, bottom: number | null, edge: number, list: number}}
 */
export const placePanel = ({anchor, panel, chrome, screen, wanted, align}) => {
  const room = roomAround(anchor, screen)
  const side = flipSide(wanted, {width: 0, height: panel.height}, room, GAP + EDGE)
  const start = align === "end" ? anchor.right - panel.width : anchor.left
  const below = side === "bottom"
  return {
    side,
    left: start + clampShift(start, panel.width, screen.width, EDGE),
    top: below ? anchor.bottom + GAP : null,
    bottom: below ? null : screen.height - anchor.top + GAP,
    edge: below ? anchor.bottom + GAP : anchor.top - GAP,
    list: Math.max(LEAST, room[side] - GAP - EDGE - chrome),
  }
}
