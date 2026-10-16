/** What a control that can take the focus looks like: the first one inside a tooltip is what it describes. */
export const FOCUSABLE =
  'a[href], button:not([disabled]), input:not([disabled]):not([type="hidden"]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])'

/**
 * The value of `aria-describedby` with `id` in it: the ids it already had are kept, and `id` is not
 * added twice.
 *
 * @param {string | null | undefined} current
 * @param {string} id
 */
export const withDescription = (current, id) => {
  const ids = (current ?? "").split(/\s+/).filter(Boolean)
  return [...new Set([...ids, id])].join(" ")
}

/** The space between the trigger and the hint on each side, as the canvas draws it. */
const GAP = {top: 8, bottom: 8, left: 6, right: 6}
const OPPOSITE = {top: "bottom", bottom: "top", left: "right", right: "left"}
const HORIZONTAL = {top: true, bottom: true, left: false, right: false}
/** How close to the edge of the screen a hint may come, and how far the arrow stays from the hint's corner. */
const EDGE = 8
const ARROW_INSET = 12

const clamp = (value, min, max) => Math.min(Math.max(value, min), max)

/**
 * Where a hint goes so it stays on the screen: on the side asked for, unless it does not fit there and the
 * opposite side has more room (flip), and pushed along the edge of the trigger until it is inside the
 * screen (shift). The arrow is moved back by the same amount, so it still points at the trigger.
 *
 * @param {"top" | "bottom" | "left" | "right"} wanted
 * @param {{
 *   tip: {width: number, height: number},
 *   trigger: {left: number, top: number, right: number, bottom: number},
 *   viewport: {width: number, height: number}
 * }} measures sizes and positions, in pixels
 * @returns {{side: string, shift: number, arrow: number}} `shift` moves the hint along the trigger, `arrow` is
 *   how far the arrow is from the middle of the hint
 */
export const placeTip = (wanted, {tip, trigger, viewport}) => {
  const room = {
    top: trigger.top,
    bottom: viewport.height - trigger.bottom,
    left: trigger.left,
    right: viewport.width - trigger.right,
  }
  const need = (side) => (HORIZONTAL[side] ? tip.height : tip.width) + GAP[side] + EDGE
  const opposite = OPPOSITE[wanted]
  const flips = room[wanted] < need(wanted) && room[opposite] > room[wanted]
  const side = flips ? opposite : wanted

  const along = HORIZONTAL[side]
    ? {center: (trigger.left + trigger.right) / 2, size: tip.width, limit: viewport.width}
    : {center: (trigger.top + trigger.bottom) / 2, size: tip.height, limit: viewport.height}
  const half = along.size / 2
  const placed = clamp(along.center, EDGE + half, along.limit - EDGE - half)
  const shift = placed - along.center
  const reach = Math.max(half - ARROW_INSET, 0)
  return {side, shift, arrow: clamp(0 - shift,-reach, reach)}
}

/** Pointers that tap rather than hover: after one, the hint is dismissed instead of left open. */
const TAPS = {touch: true, pen: false, mouse: false}

/** @param {string | undefined} pointerType the `pointerType` of a pointer event */
export const dismissesOnTap = (pointerType) => TAPS[pointerType] ?? false
