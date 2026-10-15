/**
 * A file dragged over the zone fires `dragenter` and `dragleave` on every child it crosses, so a plain
 * on/off flag flickers. Counting the enters and the leaves tells when the pointer is really out.
 */
export const depthAfter = (depth, type) => ({dragenter: depth + 1, dragleave: Math.max(depth - 1, 0), drop: 0})[type] ?? depth

/** Whether the zone is highlighted at that depth. */
export const isOver = (depth) => depth > 0
