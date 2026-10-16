/**
 * Where a floating panel (popover, tooltip, dropdown, submenu) goes: the side it opens on, the shift that keeps
 * it inside the screen and the arrow that still points at the trigger. Only `screenSize` reads the DOM; the
 * rest is arithmetic on rectangles, so it is tested without one.
 */
import {clamp} from "./numbers.js"

const OPPOSITE = {top: "bottom", bottom: "top", left: "right", right: "left"}
const SIZE = {top: "height", bottom: "height", left: "width", right: "width"}
const ABOVE_BELOW = {top: true, bottom: true, left: false, right: false}

/** How much room a panel wants beyond its own size before it is moved to the other side. */
const MARGIN = 12
/** The room a panel keeps from the edge of the screen, and the distance between a popover and its trigger. */
const EDGE = 8
const GAP = 6
/** How far from the edge of the panel its arrow stays when the panel is shifted. */
const ARROW_EDGE = 16

/** The space between a tooltip and its trigger on each side, as the canvas draws it. */
const TIP_GAP = {top: 8, bottom: 8, left: 6, right: 6}
/** How far the arrow of a tooltip stays from the corner of the hint. */
const ARROW_INSET = 12

/** The size of the window, in pixels. */
export const screenSize = () => ({width: window.innerWidth, height: window.innerHeight})

/** The pixels free on each side of `rect` on a screen. */
export const roomAround = (rect, screen) => ({
  top: rect.top,
  bottom: screen.height - rect.bottom,
  left: rect.left,
  right: screen.width - rect.right,
})

/**
 * The side a panel opens on: the one asked for, unless it does not fit there (its size plus `margin`) and the
 * opposite side has more room.
 *
 * @param {"top" | "bottom" | "left" | "right"} wanted
 * @param {{width: number, height: number}} panel
 * @param {{top: number, bottom: number, left: number, right: number}} room pixels free around the trigger
 * @param {number} [margin]
 */
export const flipSide = (wanted, panel, room, margin = MARGIN) => {
  const opposite = OPPOSITE[wanted]
  const short = room[wanted] < panel[SIZE[wanted]] + margin
  return short && room[opposite] > room[wanted] ? opposite : wanted
}

/**
 * How far to shift a panel along an axis to keep it inside the screen: zero when it fits, otherwise just enough
 * (the start edge wins when the panel is larger than the screen).
 */
export const clampShift = (start, size, limit, edge = EDGE) => {
  const toEnd = Math.min(0, limit - edge - (start + size))
  return Math.max(edge - start, toEnd)
}

/**
 * How far the arrow moves inside a panel that was shifted by `shift`, so it keeps pointing at the trigger, and
 * never leaves the panel.
 *
 * @param {number} shift how much the panel moved
 * @param {{center: number, size: number}} arrow where its center was, from the start of the panel, and the panel size
 */
export const arrowShift = (shift, {center, size}) => {
  const target = clamp(center - shift, ARROW_EDGE, size - ARROW_EDGE)
  return target - center
}

/**
 * The corner of a panel with `position: fixed`, from the rectangle of the trigger: on `side` of it, aligned to
 * its start or its end, GAP away, and shifted to stay inside the screen.
 *
 * @param {{side: string, align: "start" | "end", anchor: DOMRect, panel: {width: number, height: number}, screen: {width: number, height: number}}} spec
 * @returns {{top: number, left: number, shiftX: number, shiftY: number}}
 */
export const fixedCorner = ({side, align, anchor, panel, screen}) => {
  const across = {
    top: {x: align === "end" ? anchor.right - panel.width : anchor.left, y: anchor.top - GAP - panel.height},
    bottom: {x: align === "end" ? anchor.right - panel.width : anchor.left, y: anchor.bottom + GAP},
    left: {x: anchor.left - GAP - panel.width, y: align === "end" ? anchor.bottom - panel.height : anchor.top},
    right: {x: anchor.right + GAP, y: align === "end" ? anchor.bottom - panel.height : anchor.top},
  }[side]
  const vertical = ABOVE_BELOW[side]
  const shiftX = vertical ? clampShift(across.x, panel.width, screen.width) : 0
  const shiftY = vertical ? 0 : clampShift(across.y, panel.height, screen.height)
  return {top: across.y + shiftY, left: across.x + shiftX, shiftX, shiftY}
}

/**
 * The vertical side a dropdown opens on, from the heights free above and below the trigger: see `flipSide`.
 *
 * @param {"top" | "bottom"} wanted
 * @param {{panel: number, above: number, below: number}} room heights, in pixels
 */
export const chooseSide = (wanted, {panel, above, below}) =>
  flipSide(wanted, {width: 0, height: panel}, {top: above, bottom: below, left: 0, right: 0})

/**
 * The side a submenu opens on: the one asked for, unless it does not fit there and the other side has more
 * room.
 *
 * @param {"left" | "right"} wanted
 * @param {{panel: number, left: number, right: number}} room widths, in pixels
 */
export const submenuSide = (wanted, {panel, left, right}) =>
  flipSide(wanted, {width: panel, height: 0}, {top: 0, bottom: 0, left, right})

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
  const side = flipSide(wanted, tip, roomAround(trigger, viewport), TIP_GAP[wanted] + EDGE)
  const along = ABOVE_BELOW[side]
    ? {center: (trigger.left + trigger.right) / 2, size: tip.width, limit: viewport.width}
    : {center: (trigger.top + trigger.bottom) / 2, size: tip.height, limit: viewport.height}
  const half = along.size / 2
  const placed = clamp(along.center, EDGE + half, along.limit - EDGE - half)
  const shift = placed - along.center
  const reach = Math.max(half - ARROW_INSET, 0)
  return {side, shift, arrow: clamp(0 - shift, -reach, reach)}
}

/** The edge of a panel that opens at a point: it stays where the pointer is, unless that crosses `limit`; then it ends there instead. */
const flipAt = (at, size, limit) => (at + size + EDGE <= limit ? at : Math.max(EDGE, at - size))

/**
 * The corner of a panel with `position: fixed` that opens at a point (the pointer of a context menu): its top
 * left corner is at the point, or the panel opens to the left and/or upwards of it when it would leave the
 * screen, and it never leaves the screen at all.
 *
 * @param {{x: number, y: number}} point
 * @param {{width: number, height: number}} panel
 * @param {{width: number, height: number}} screen
 * @returns {{left: number, top: number}}
 */
export const placeAtPoint = (point, panel, screen) => ({
  left: Math.max(EDGE, flipAt(point.x, panel.width, screen.width)),
  top: Math.max(EDGE, flipAt(point.y, panel.height, screen.height)),
})
