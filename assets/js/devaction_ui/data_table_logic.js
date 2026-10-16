/** What the header checkbox and the bulk bar show for `checked` of `total` ticked rows. */
export const selectionState = (checked, total) => ({
  all: total > 0 && checked === total,
  mixed: checked > 0 && checked < total,
  barHidden: checked === 0,
})

/** The indexes between two rows, both included and in order: the rows a Shift+click ticks. */
export const rangeBetween = (first, second) =>
  Array.from({length: Math.abs(second - first) + 1}, (_, step) => Math.min(first, second) + step)

/** The value of `aria-expanded` after a click on a chevron that reads `current`. */
export const toggledExpanded = (current) => String(current !== "true")

/** The density the toggle switches to: `compact` from `comfortable`, and `comfortable` from anything else. */
export const nextDensity = (density) => (density === "comfortable" ? "compact" : "comfortable")
