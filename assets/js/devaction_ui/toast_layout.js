import {decide} from "./rules.js"

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

/** The inline style of the toast at `index` (0 is the newest) in a collapsed stack: the layers peek out below it. */
export const layerStyle = (index) => ({
  position: "absolute",
  left: "0",
  right: "0",
  top: "0",
  zIndex: String(10 - index),
  transform: `translateY(${index * 8}px) scale(${1 - index * 0.05})`,
  transformOrigin: "top center",
  opacity: index > 2 ? "0" : String(1 - index * 0.2),
  pointerEvents: "none",
})

/** The newest toast sits on top of the layers behind it. */
export const leadStyle = {position: "relative", left: "", right: "", top: "", zIndex: "20", transform: "", opacity: "", pointerEvents: ""}

/** A toast in a list (or alone): back to the normal flow. */
export const flowStyle = {position: "", left: "", right: "", top: "", zIndex: "", transform: "", opacity: "", pointerEvents: ""}

/** The style of the toast at `index`: a layer behind the first, the first of a stack, or a normal one. */
export const styleFor = ({index, stacked}) =>
  decide(
    [
      [(s) => s.stacked && s.index > 0, (s) => layerStyle(s.index)],
      [(s) => s.stacked, () => leadStyle],
      [() => true, () => flowStyle],
    ],
    {index, stacked},
  )

/** Extra space under a stack so the layers do not run into what is below: at most two layers show. */
export const stackPadding = (count) => `${Math.min(count - 1, 2) * 8}px`

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
