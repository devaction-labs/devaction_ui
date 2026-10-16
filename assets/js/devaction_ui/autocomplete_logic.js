/**
 * Whether the field should say its list is open: there is a list, it is showing, and it has a row to move
 * to (a list that only says "nothing found" is not open as far as the keys go).
 *
 * @param {{hasList: boolean, visible: boolean, options: number}} state
 */
export const isExpanded = ({hasList, visible, options}) => hasList && visible && options > 0

/**
 * The `aria-selected` of each of `count` rows when row `active` is the active one (`-1` for none).
 *
 * @param {number} count
 * @param {number} active
 * @returns {string[]}
 */
export const selectedStates = (count, active) => Array.from({length: count}, (_, index) => String(index === active))
