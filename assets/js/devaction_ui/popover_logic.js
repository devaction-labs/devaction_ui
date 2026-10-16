/** How much room a panel wants beyond its own height before it is moved to the other side. */
const MARGIN = 12

const OPPOSITE = {top: "bottom", bottom: "top", left: "right", right: "left"}
const SIZE = {top: "height", bottom: "height", left: "width", right: "width"}

/** The room a panel keeps from the edge of the screen, and the distance between the panel and the trigger. */
export const EDGE = 8
export const GAP = 6
/** How far from the edge of the panel its arrow stays when the panel is shifted. */
const ARROW_EDGE = 16

/**
 * The side a popover opens on: the one asked for, unless it does not fit there and the opposite side has more
 * room.
 *
 * @param {"top" | "bottom" | "left" | "right"} wanted
 * @param {{width: number, height: number}} panel
 * @param {{top: number, bottom: number, left: number, right: number}} room pixels free around the trigger
 */
export const flipSide = (wanted, panel, room) => {
  const opposite = OPPOSITE[wanted]
  const short = room[wanted] < panel[SIZE[wanted]] + MARGIN
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
  const target = Math.min(Math.max(center - shift, ARROW_EDGE), size - ARROW_EDGE)
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
  const vertical = side === "top" || side === "bottom"
  const shiftX = vertical ? clampShift(across.x, panel.width, screen.width) : 0
  const shiftY = vertical ? 0 : clampShift(across.y, panel.height, screen.height)
  return {top: across.y + shiftY, left: across.x + shiftX, shiftX, shiftY}
}

/** What Tab does at the edge of the panel: `forward` leaves it for what follows the trigger, `back` returns to the trigger. */
export const tabExit = ({shift, active, first, last}) =>
  [
    [shift && active === first, "back"],
    [!shift && active === last, "forward"],
  ].find(([hit]) => hit)?.[1] ?? null

/**
 * The vertical side a popover opens on, from the heights free above and below the trigger: see `flipSide`.
 *
 * @param {"top" | "bottom"} wanted
 * @param {{panel: number, above: number, below: number}} room heights, in pixels
 */
export const chooseSide = (wanted, {panel, above, below}) =>
  flipSide(wanted, {width: 0, height: panel}, {top: above, bottom: below, left: 0, right: 0})
