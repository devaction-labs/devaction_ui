const EPSILON = 1

/**
 * Which edges of a scroll area still have content behind them. The shadow is drawn only on those, and the
 * header of a table gets its own shadow once the content has moved under it.
 *
 * @param {{scrollLeft: number, scrollTop: number, scrollWidth: number, clientWidth: number, scrollHeight: number, clientHeight: number}} box
 * @returns {{left: boolean, right: boolean, top: boolean, bottom: boolean}}
 */
export const edges = ({scrollLeft, scrollTop, scrollWidth, clientWidth, scrollHeight, clientHeight}) => ({
  left: scrollLeft > EPSILON,
  right: scrollLeft < scrollWidth - clientWidth - EPSILON,
  top: scrollTop > EPSILON,
  bottom: scrollTop < scrollHeight - clientHeight - EPSILON,
})

/** The attribute of the root for each edge. */
export const ATTRIBUTES = {left: "data-more-left", right: "data-more-right", top: "data-more-top", bottom: "data-more-bottom"}
