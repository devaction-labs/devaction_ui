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

/** A toast behind the front one of a collapsed stack is not drawn: the layers above the front toast stand for it. */
const hiddenStyle = {display: "none", position: "", zIndex: ""}

/** The front toast of a stack, above the blocks behind it. */
const leadStyle = {display: "", position: "relative", zIndex: "20"}

/** A toast in a list (or alone): back to the normal flow. */
const flowStyle = {display: "", position: "", zIndex: ""}

/** The style of the toast at `index`: hidden behind the first, the first of a stack, or a normal one. */
export const styleFor = ({index, stacked}) =>
  decide(
    [
      [(s) => s.stacked && s.index > 0, () => hiddenStyle],
      [(s) => s.stacked, () => leadStyle],
      [() => true, () => flowStyle],
    ],
    {index, stacked},
  )

/** The layers that peek out above the front toast of a collapsed stack: one per toast behind it, at most two. */
export const layerCount = (count) => Math.min(Math.max(count - 1, 0), 2)

/** Room above a collapsed stack for the two layers that peek out over the front toast. */
export const stackPadding = (count) => (count > 1 ? "16px" : "")

/** The line of the group's bar: the heading when there is one, then the count written by `label`. */
export const countText = ({heading, label, count}) =>
  [heading, label.replace("__COUNT__", String(count))].filter(Boolean).join(" \u00b7 ")

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
