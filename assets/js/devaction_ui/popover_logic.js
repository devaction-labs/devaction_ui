/** How much room a panel wants beyond its own height before it is moved to the other side. */
const MARGIN = 12

/**
 * The side a popover opens on: the one asked for, unless it does not fit there and the other side has more
 * room.
 *
 * @param {"top" | "bottom"} wanted
 * @param {{panel: number, above: number, below: number}} room heights, in pixels
 */
export const chooseSide = (wanted, {panel, above, below}) => {
  const rules = {
    bottom: below < panel + MARGIN && above > below ? "top" : "bottom",
    top: above < panel + MARGIN && below > above ? "bottom" : "top",
  }
  return rules[wanted]
}
