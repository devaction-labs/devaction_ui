/** What the header checkbox and the bulk bar show for `checked` of `total` ticked rows. */
export const selectionState = (checked, total) => ({
  all: total > 0 && checked === total,
  mixed: checked > 0 && checked < total,
  barHidden: checked === 0,
})

/** The density the toggle switches to: `compact` from `comfortable`, and `comfortable` from anything else. */
export const nextDensity = (density) => (density === "comfortable" ? "compact" : "comfortable")
