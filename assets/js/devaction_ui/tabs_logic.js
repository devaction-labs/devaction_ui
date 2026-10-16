import {wrap} from "./keys.js"

const ENDS = {
  Home: () => 0,
  End: (_at, count) => count - 1,
}

const MOVES = {
  horizontal: {
    ArrowRight: (at, count) => wrap(at, 1, count),
    ArrowLeft: (at, count) => wrap(at, -1, count),
    ...ENDS,
  },
  vertical: {
    ArrowDown: (at, count) => wrap(at, 1, count),
    ArrowUp: (at, count) => wrap(at, -1, count),
    ...ENDS,
  },
}

const FLIPPED = {ArrowRight: "ArrowLeft", ArrowLeft: "ArrowRight"}

/**
 * The index of the tab a key moves to from `current`, or `null` for a key that does not move the selection
 * and for an empty list. Arrows wrap round the list; Home and End jump to its ends. A horizontal list takes
 * ← and → (swapped on a right-to-left page), a vertical one ↑ and ↓.
 *
 * @param {string} key the name of the key (`keyName` of keys.js)
 * @param {number} current index of the selected tab
 * @param {number} count how many tabs there are
 * @param {{orientation?: "horizontal" | "vertical", rtl?: boolean}} [layout]
 * @returns {number | null}
 */
export const nextTab = (key, current, count, {orientation = "horizontal", rtl = false} = {}) => {
  const name = (rtl && orientation === "horizontal" && FLIPPED[key]) || key
  const target = count > 0 ? MOVES[orientation]?.[name]?.(current, count) : undefined
  return target ?? null
}

/**
 * Which tab is selected after the server patched the tabs. The tab the person chose in the browser stays,
 * unless the server has since changed its own selection (then the server wins) or that tab is gone.
 *
 * @param {{chosen: string, lastServer: string, server: string, ids: string[]}} state `chosen` is `""` when the
 *   person has not chosen; `lastServer` and `server` are the server's selection before and after the patch
 * @returns {{selected: string, chosen: string, lastServer: string}}
 */
export const resolveSelection = ({chosen, lastServer, server, ids}) =>
  chosen && server === lastServer && ids.includes(chosen)
    ? {selected: chosen, chosen, lastServer: server}
    : {selected: server, chosen: "", lastServer: server}
