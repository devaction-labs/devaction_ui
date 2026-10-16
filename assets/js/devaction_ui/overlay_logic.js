/**
 * Pure bookkeeping of the open overlays (modal, drawer): who is on top, what is held inert, and how the page
 * behind is locked, and the drag that closes a bottom sheet. The hook keeps the state, these functions only
 * compute the next one.
 */

/** The stack with `id` on top; an id that was already there moves up instead of being repeated. */
export const stackWith = (stack, id) => [...stack.filter((open) => open !== id), id]

/** The stack without `id`. */
export const stackWithout = (stack, id) => stack.filter((open) => open !== id)

/** Whether `id` is the overlay on top, the only one that answers Esc. */
export const isTop = (stack, id) => stack.at(-1) === id

/** How many overlays hold `key` (an element) inert; a copy of the counts with one more. */
export const retain = (counts, key) => new Map(counts).set(key, (counts.get(key) ?? 0) + 1)

/** A copy of the counts with one fewer for `key`; at zero the key is gone, and the element is free again. */
export const release = (counts, key) => {
  const next = new Map(counts)
  const left = (counts.get(key) ?? 0) - 1
  left > 0 ? next.set(key, left) : next.delete(key)
  return next
}

/** The inline style that locks the scroll of the page; the scrollbar's width stays as padding so nothing shifts. */
export const lockStyle = (scrollbar) => ({overflow: "hidden", paddingRight: scrollbar > 0 ? `${scrollbar}px` : ""})

/** What a page element needs to be left alone by the inert pass: it is part of the overlay, or it says so. */
export const exempt = ({tag, keep, live}) => ["SCRIPT", "STYLE", "LINK", "TEMPLATE"].includes(tag) || keep || live

/** The part of its height a sheet has to be dragged down to close when let go, and the speed that closes it anyway. */
const CLOSE_RATIO = 0.35
const FLING = 0.6

/** How far down the sheet follows the finger: never up past its place. */
export const dragOffset = (startY, y) => Math.max(0, y - startY)

/** The speed of a drag in pixels per millisecond. */
export const speed = (fromY, fromAt, toY, toAt) => (toY - fromY) / Math.max(1, toAt - fromAt)

/** Whether letting go closes the sheet: dragged far enough, or flung down. */
export const shouldClose = ({offset, height, velocity}) => height > 0 && (offset > height * CLOSE_RATIO || velocity > FLING)

/** The inline style of the sheet during a drag: it follows the finger with no transition. */
export const dragStyle = (offset) => ({transform: `translateY(${offset}px)`, transition: "none"})

/** The inline style when it is let go and does not close: back in place, with no motion for who asks for none. */
export const settleStyle = (reducedMotion) => ({transform: "", transition: reducedMotion ? "none" : "transform .18s ease-out"})
