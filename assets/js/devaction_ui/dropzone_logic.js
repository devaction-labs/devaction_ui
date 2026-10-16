/**
 * A file dragged over the zone fires `dragenter` and `dragleave` on every child it crosses, so a plain
 * on/off flag flickers. Counting the enters and the leaves tells when the pointer is really out.
 */
export const depthAfter = (depth, type) => ({dragenter: depth + 1, dragleave: Math.max(depth - 1, 0), drop: 0})[type] ?? depth

/** Whether the zone is highlighted at that depth. */
export const isOver = (depth) => depth > 0

/** What is announced at that depth: the caller's text while a file is over the zone, nothing otherwise. */
export const overText = (depth, label) => (isOver(depth) ? (label ?? "") : "")
