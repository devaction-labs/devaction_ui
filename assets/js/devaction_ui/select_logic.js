/**
 * What the styled panel of `DevactionUI.Select` decides, without a DOM of its own: the items read from the
 * native `<select>`, which row is active after a key, what a typed word finds and where the panel goes.
 */
import {clampShift, flipSide, roomAround} from "./placement.js"

/** The tallest the panel gets before it scrolls, the distance from the trigger and the room kept from the screen edge. */
const MAX_HEIGHT = 320
const GAP = 6
const EDGE = 8
/** How long a typed letter still belongs to the same word. */
const TYPE_WINDOW = 700

const option = (node, disabled, position) => ({
  kind: "option",
  value: node.value,
  label: node.label || node.text,
  disabled: disabled || node.disabled,
  selected: node.selected,
  position,
})

/**
 * The rows of a `<select>`: `{kind: "group", label}` for an `<optgroup>` and `{kind: "option", value, label,
 * disabled, selected, position}` for an `<option>` (`position` is its index in `select.options`, and an option
 * of a disabled group is disabled).
 *
 * @param {{children: ArrayLike<any>}} select
 */
export const readItems = (select) => {
  const kinds = {
    OPTION: (node, position) => [option(node, false, position)],
    OPTGROUP: (node, position) => [
      {kind: "group", label: node.label},
      ...[...node.children].map((child, at) => option(child, node.disabled, position + at)),
    ],
  }
  const widths = {OPTION: () => 1, OPTGROUP: (node) => node.children.length}
  return [...select.children].reduce(
    (state, node) => ({
      items: [...state.items, ...(kinds[node.tagName]?.(node, state.position) ?? [])],
      position: state.position + (widths[node.tagName]?.(node) ?? 0),
    }),
    {items: [], position: 0},
  ).items
}

/** The indexes of the rows a person can choose. */
export const choosable = (items) => items.flatMap((item, index) => (item.kind === "option" && !item.disabled ? [index] : []))

/** The row that is active when the panel opens: the chosen one, else the first that can be chosen, else `-1`. */
export const startIndex = (items) => {
  const rows = choosable(items)
  return rows.find((index) => items[index].selected) ?? rows[0] ?? -1
}

const MOVES = {
  ArrowDown: (rows, from) => rows.find((index) => index > from),
  ArrowUp: (rows, from) => rows.findLast((index) => index < from),
  Home: (rows) => rows[0],
  End: (rows) => rows.at(-1),
}

/** The row after a navigation key (`ArrowDown`, `ArrowUp`, `Home`, `End`), skipping what cannot be chosen; it stays on the same row at the ends. */
export const moveActive = (items, from, key) => MOVES[key]?.(choosable(items), from) ?? from

/**
 * The typed text, as the native select builds it: a new letter continues the word when it comes soon enough.
 *
 * @param {{text: string, at: number}} previous
 */
export const typedText = (previous, key, now) => ({
  text: now - previous.at < TYPE_WINDOW ? previous.text + key : key,
  at: now,
})

/** Whether a key adds to the typed word: a printable character, and a space only inside a word. */
export const isTypeKey = (event, typed, now) =>
  event.key.length === 1 &&
  !event.ctrlKey &&
  !event.metaKey &&
  !event.altKey &&
  (event.key !== " " || (typed.text !== "" && now - typed.at < TYPE_WINDOW))

/** The row a typed word leads to: the next whose label starts with it (a repeated letter walks through those with that letter), else `from`. */
export const typeAhead = (items, from, text) => {
  const repeated = [...text].every((char) => char === text[0])
  const needle = (repeated ? text[0] : text).toLowerCase()
  const hits = choosable(items).filter((index) => items[index].label.toLowerCase().startsWith(needle))
  const after = repeated ? (index) => index > from : (index) => index >= from
  return hits.find(after) ?? hits[0] ?? from
}

/**
 * Where the panel goes: under the trigger, as wide as it, or above when there is no room below and more above,
 * kept inside the screen and no taller than the room it has.
 *
 * @param {{anchor: DOMRect, height: number, screen: {width: number, height: number}}} spec `height` is the natural height of the panel
 * @returns {{side: "top" | "bottom", top: number, left: number, width: number, maxHeight: number}}
 */
export const placePanel = ({anchor, height, screen}) => {
  const room = roomAround(anchor, screen)
  const side = flipSide("bottom", {width: 0, height: Math.min(height, MAX_HEIGHT)}, room)
  const maxHeight = Math.max(0, Math.min(MAX_HEIGHT, room[side] - GAP - EDGE))
  const used = Math.min(height, maxHeight)
  const top = side === "bottom" ? anchor.bottom + GAP : anchor.top - GAP - used
  return {side, top, left: anchor.left + clampShift(anchor.left, anchor.width, screen.width), width: anchor.width, maxHeight}
}
