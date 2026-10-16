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
