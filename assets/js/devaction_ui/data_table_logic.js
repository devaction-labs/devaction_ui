/** What the header checkbox and the bulk bar show for `checked` of `total` ticked rows. */
export const selectionState = (checked, total) => ({
  all: total > 0 && checked === total,
  mixed: checked > 0 && checked < total,
  barHidden: checked === 0,
})
