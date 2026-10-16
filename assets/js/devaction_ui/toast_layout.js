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

/** A toast behind the front one of a collapsed stack is not drawn: the blocks of the group stand for it. */
export const hiddenStyle = {display: "none", position: "", zIndex: ""}

/** The front toast of a stack, above the blocks behind it. */
export const leadStyle = {display: "", position: "relative", zIndex: "20"}

/** A toast in a list (or alone): back to the normal flow. */
export const flowStyle = {display: "", position: "", zIndex: ""}

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

/** Room under a collapsed stack for the two blocks that peek out below the front toast. */
export const stackPadding = (count) => (count > 1 ? "20px" : "")

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
