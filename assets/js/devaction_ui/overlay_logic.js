/**
 * Pure bookkeeping of the open overlays (modal, drawer): who is on top, what is held inert, and how the page
 * behind is locked. The hook keeps the state, these functions only compute the next one.
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
