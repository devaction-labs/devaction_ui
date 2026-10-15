/** Whether a column with a work-in-progress limit takes one more card from another column. */
export const isFull = ({count, wip, sameColumn}) => !sameColumn && Number.isInteger(wip) && wip > 0 && count >= wip

/**
 * Where a dragged card would land: the number of cards (the dragged one left out) whose middle is above the
 * pointer, so a pointer below them all means the end.
 *
 * @param {{top: number, height: number}[]} boxes the other cards of the column, top to bottom
 * @param {number} y the pointer's vertical position
 */
export const insertionIndex = (boxes, y) => boxes.filter((box) => y >= box.top + box.height / 2).length

/** `wip` as the column carries it in `data-wip`: a number, or `NaN` when it has no limit. */
export const parseWip = (text) => Number.parseInt(text ?? "", 10)
