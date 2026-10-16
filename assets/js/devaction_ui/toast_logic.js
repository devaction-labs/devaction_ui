/**
 * The toasts without a DOM: how a group of them is laid out, what Escape does in it, and when the notice of a
 * finished job leaves by itself.
 */
import {decide} from "./keys.js"

/**
 * How a group of toasts is laid out. With more than one it is either a stack of layers (collapsed) or a
 * list (expanded); a single toast is always itself.
 *
 * @param {{count: number, expanded: boolean}} state
 */
export const planLayout = ({count, expanded}) => {
  const many = count > 1
  const open = many && expanded
  return {expanded: open, stacked: many && !expanded, showBar: open, showExpand: many && !expanded}
}

/**
 * How far each toast has to travel when the pile opens or closes: from where it was drawn to where the new
 * layout puts it. `before` and `after` map a toast's id to `{x, y}`; a toast that did not move, or that was not
 * there before, has no step.
 */
export const glideSteps = (before, after) =>
  [...after]
    .filter(([id]) => before.has(id))
    .map(([id, to]) => ({id, dx: before.get(id).x - to.x, dy: before.get(id).y - to.y}))
    .filter(({dx, dy}) => dx !== 0 || dy !== 0)

/** How long a toast takes to glide between the pile and the list. */
export const GLIDE_MS = 320

/** The line of the group's bar: the heading when there is one, then the count written by `label`. */
export const countText = ({heading, label, count}) =>
  [heading, label.replace("__COUNT__", String(count))].filter(Boolean).join(" \u00b7 ")

/** How long the list stays open after the pointer or the focus has left the pile, so a stray move does not close it. */
export const HOVER_CLOSE_MS = 250

/**
 * What the pile does when the pointer or the focus comes in (`enter`) or goes out (`leave`): a collapsed stack
 * opens, and a list that opened by itself closes again; one the person opened on purpose (a click) stays.
 */
export const hoverStep = ({event, stacked, expanded, auto}) =>
  decide(
    [
      [(s) => s.event === "enter" && s.stacked && !s.expanded, () => "open"],
      [(s) => s.event === "leave" && s.auto && s.expanded, () => "close"],
      [() => true, () => null],
    ],
    {event, stacked, expanded, auto},
  )

/** What Escape does: close an open list first, else close the toast the focus is on, else nothing. */
export const escapeStep = ({expanded, focused}) =>
  decide(
    [
      [(s) => s.expanded, () => "collapse"],
      [(s) => s.focused, () => "dismiss"],
      [() => true, () => null],
    ],
    {expanded, focused},
  )

/** How long a finished job's toast stays before it leaves, and how long its exit animation gets. */
export const LINGER_MS = 1600
export const EXIT_MS = 400

/**
 * What the toast should do now. A job that is done leaves after LINGER_MS, with the time the pointer or
 * focus spent on it not counted; one that is running or failed stays.
 *
 * `remaining` is what is left of the wait (LINGER_MS when it has not started), `paused` whether the
 * pointer or the focus is on it. The answer is `{wait: ms}` to leave after that time, or `{wait: null}`
 * to stay where it is.
 */
export function plan({state, remaining = LINGER_MS, paused = false}) {
  return state === "done" && !paused ? {wait: Math.max(0, remaining)} : {wait: null}
}

/** What is left of a wait that started at `startedAt` and is being interrupted at `now`. */
export function leftAfter(remaining, startedAt, now) {
  return Math.max(0, remaining - (now - startedAt))
}
