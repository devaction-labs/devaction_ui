/**
 * Keys and decisions by table instead of `if / else if`: a hook lists the keys it cares about and what each
 * does, and `runKey` looks the pressed key up. A key the table does not know is left alone. Beside it, the pure
 * arithmetic of moving between items (roving focus, the tabs, the segments, the grid of days) and of Tab leaving
 * a panel.
 */
import {clamp} from "./numbers.js"

/** The name of a key with its modifier, e.g. `"Enter"`, `"Mod+Enter"` (⌘ or Ctrl), `"Alt+ArrowLeft"`. */
export const keyName = (event) => {
  const prefix = [event.altKey && "Alt", (event.metaKey || event.ctrlKey) && "Mod"].filter(Boolean)
  return [...prefix, event.key].join("+")
}

/**
 * Runs the handler the table has for the key of `event` and says whether there was one. A handler that
 * returns `false` declines the key (the event is not consumed); any other result consumes it with
 * `preventDefault`.
 *
 * @param {Record<string, (event: KeyboardEvent) => unknown>} table
 * @param {KeyboardEvent} event
 */
export const runKey = (table, event) => {
  const handler = table[keyName(event)]
  const result = handler?.(event)
  const consumed = handler !== undefined && result !== false
  consumed && event.preventDefault()
  return consumed
}

/**
 * Decisions as a table, not an `if / else if` chain: each rule is `[test, result]`, the first test that
 * passes decides, and the last rule is usually `[() => true, ...]`. Both receive the same arguments.
 *
 * @template R
 * @param {Array<[(...args: any[]) => boolean, (...args: any[]) => R]>} rules
 * @returns {R}
 */
export const decide = (rules, ...args) => rules.find(([test]) => test(...args))[1](...args)

/** `index + delta` wrapped into `0...count`; `-1` for an empty list. */
export const wrap = (index, delta, count) => (count === 0 ? -1 : (((index + delta) % count) + count) % count)

/** What Tab does at the edge of the panel: `forward` leaves it for what follows the trigger, `back` returns to the trigger. */
export const tabExit = ({shift, active, first, last}) =>
  [
    [shift && active === first, "back"],
    [!shift && active === last, "forward"],
  ].find(([hit]) => hit)?.[1] ?? null

const ENDS = {
  Home: () => 0,
  End: (_at, count) => count - 1,
}

const MOVES = {
  horizontal: {
    ArrowRight: (at, count) => wrap(at, 1, count),
    ArrowLeft: (at, count) => wrap(at, -1, count),
    ...ENDS,
  },
  vertical: {
    ArrowDown: (at, count) => wrap(at, 1, count),
    ArrowUp: (at, count) => wrap(at, -1, count),
    ...ENDS,
  },
}

const FLIPPED = {ArrowRight: "ArrowLeft", ArrowLeft: "ArrowRight"}

/**
 * The index of the tab a key moves to from `current`, or `null` for a key that does not move the selection
 * and for an empty list. Arrows wrap round the list; Home and End jump to its ends. A horizontal list takes
 * ← and → (swapped on a right-to-left page), a vertical one ↑ and ↓.
 *
 * @param {string} key the name of the key (`keyName`)
 * @param {number} current index of the selected tab
 * @param {number} count how many tabs there are
 * @param {{orientation?: "horizontal" | "vertical", rtl?: boolean}} [layout]
 * @returns {number | null}
 */
export const nextTab = (key, current, count, {orientation = "horizontal", rtl = false} = {}) => {
  const name = (rtl && orientation === "horizontal" && FLIPPED[key]) || key
  const target = count > 0 ? MOVES[orientation]?.[name]?.(current, count) : undefined
  return target ?? null
}

const openIndexes = (items) => items.flatMap((item, index) => (item.disabled ? [] : [index]))

/**
 * The index of the one segment in the Tab order (roving tabindex): the pressed one, or the first one that is
 * not disabled when none is. `-1` when every segment is disabled.
 * @param {{pressed: boolean, disabled: boolean}[]} items
 */
export const tabStop = (items) => {
  const open = openIndexes(items)
  return open.find((index) => items[index].pressed) ?? open[0] ?? -1
}

const STEPS = {ArrowRight: 1, ArrowDown: 1, ArrowLeft: -1, ArrowUp: -1}

/**
 * The index the focus goes to from segment `from` on a key (arrows step and wrap, Home and End jump to the
 * ends), skipping the disabled ones; `undefined` for a key the control does not use.
 * @param {{pressed: boolean, disabled: boolean}[]} items
 */
export const moveSegment = (items, from, key) => {
  const open = openIndexes(items)
  const jump = {Home: () => open[0], End: () => open.at(-1)}[key]
  const step = STEPS[key]
  return jump?.() ?? (step === undefined ? undefined : open[wrap(open.indexOf(from), step, open.length)])
}

/**
 * Where the focus goes in a grid of days when a key is pressed, as an index into the cells (row by row):
 * the arrows move a day or a week, Home and End go to the start and the end of the week, and the page keys
 * are not a move inside the grid (they ask for another month, `"prev"` or `"next"`). `null` means the key is not ours.
 */
export function gridTarget(index, key, {columns, total}) {
  const within = (value) => clamp(value, 0, total - 1)
  const row = Math.floor(index / columns) * columns

  const moves = {
    ArrowLeft: () => within(index - 1),
    ArrowRight: () => within(index + 1),
    ArrowUp: () => within(index - columns),
    ArrowDown: () => within(index + columns),
    Home: () => row,
    End: () => within(row + columns - 1),
    PageUp: () => "prev",
    PageDown: () => "next",
  }

  return moves[key]?.() ?? null
}

const parentOf = (items, index) => {
  const level = items[index].level
  const above = items.map((item, at) => [item, at]).slice(0, index).filter(([item]) => item.level < level)
  return above.at(-1)?.[1]
}

const firstChild = (items, index) => (items[index + 1]?.level > items[index].level ? index + 1 : undefined)

const TREE_KEYS = {
  ArrowDown: (items, index) => ({focus: Math.min(index + 1, items.length - 1)}),
  ArrowUp: (items, index) => ({focus: Math.max(index - 1, 0)}),
  Home: () => ({focus: 0}),
  End: (items) => ({focus: items.length - 1}),
  ArrowRight: (items, index) =>
    decide(
      [
        [(list, at) => list[at].expandable && !list[at].expanded, (_list, at) => ({click: at})],
        [(list, at) => list[at].expandable && firstChild(list, at) !== undefined, (list, at) => ({focus: firstChild(list, at)})],
        [() => true, () => null],
      ],
      items,
      index,
    ),
  ArrowLeft: (items, index) =>
    decide(
      [
        [(list, at) => list[at].expandable && list[at].expanded, (_list, at) => ({click: at})],
        [(list, at) => parentOf(list, at) !== undefined, (list, at) => ({focus: parentOf(list, at)})],
        [() => true, () => null],
      ],
      items,
      index,
    ),
}

/**
 * What a key does in a tree of items shown in a flat list: `{focus: index}` moves the focus, `{click: index}`
 * opens or closes the folder at `index`, and `null` is a key the tree does not take (or has nothing to do).
 * ↑ ↓ Home End move; → opens a closed folder or enters an open one; ← closes an open folder or goes to the
 * parent. Each item is `{level, expandable, expanded}`.
 *
 * @param {string} key the name of the key (`keyName`)
 * @param {{level: number, expandable: boolean, expanded: boolean}[]} items the visible items, in order
 * @param {number} index the item that has the focus
 */
export const treeKey = (key, items, index) => (items.length === 0 || index < 0 ? null : (TREE_KEYS[key]?.(items, index) ?? null))

/** Whether a key pressed in `target` is text going into a field (`INPUT`, `TEXTAREA`, `SELECT` or editable content). */
export const isTyping = ({tagName = "", isContentEditable = false} = {}) => isContentEditable || ["INPUT", "TEXTAREA", "SELECT"].includes(tagName.toUpperCase())
