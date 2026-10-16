import {runKey} from "./keys.js"
import {clamp} from "./numbers.js"

export const ZOOM_STEPS = [50, 75, 100, 125, 150, 200, 300]

/** The zoom one step in `direction` (`1` in, `-1` out) from `zoom`, which may sit between two steps; it stops at the ends. */
export const stepZoom = (zoom, direction) =>
  ({
    1: () => ZOOM_STEPS.find((step) => step > zoom) ?? ZOOM_STEPS.at(-1),
    "-1": () => ZOOM_STEPS.findLast((step) => step < zoom) ?? ZOOM_STEPS[0],
  })[direction]()

/** A zoom held to the range of the steps. */
export const clampZoom = (zoom) => clamp(zoom, ZOOM_STEPS[0], ZOOM_STEPS.at(-1))

/** A page number held to `1...total`. */
export const clampPage = (page, total) => clamp(page, 1, Math.max(total, 1))

/** The size of a page in px at `zoom` percent, from its size at 100%. */
export const pageSize = ({width, height}, zoom) => ({
  width: Math.round((width * zoom) / 100),
  height: Math.round((height * zoom) / 100),
})

/** A signature field, given in percent of the page, as a box in px on a page of `width` by `height`. */
export const fieldBox = ({x, y, w, h}, {width, height}) => ({
  left: Math.round((width * x) / 100),
  top: Math.round((height * y) / 100),
  width: Math.round((width * w) / 100),
  height: Math.round((height * h) / 100),
})

/** The scale that draws a PDF page, `naturalWidth` wide at scale 1, `pageWidth` px wide at 100% and `zoom` percent. */
export const renderScale = ({pageWidth, naturalWidth, zoom}) => (pageWidth * zoom) / 100 / naturalWidth

/** The `scrollTop` that brings a thumbnail into view in the rail, or `null` when it is already in view. */
export const thumbScrollTarget = ({top, height, scrollTop, viewHeight, margin = 8}) =>
  [
    [top - margin < scrollTop, () => Math.max(top - margin, 0)],
    [top + height + margin > scrollTop + viewHeight, () => top + height + margin - viewHeight],
  ].find(([outside]) => outside)?.[1]() ?? null

const turn = (value, {total}) => ({type: "page", value: clampPage(value, total)})

const KEYS = {
  "+": ({zoom}) => ({type: "zoom", value: stepZoom(zoom, 1)}),
  "=": ({zoom}) => ({type: "zoom", value: stepZoom(zoom, 1)}),
  "-": ({zoom}) => ({type: "zoom", value: stepZoom(zoom, -1)}),
  0: () => ({type: "zoom", value: 100}),
  PageDown: (state) => turn(state.page + 1, state),
  PageUp: (state) => turn(state.page - 1, state),
  Home: (state) => turn(1, state),
  End: (state) => turn(state.total, state),
}

const RAIL_KEYS = {
  ArrowDown: (state) => turn(state.page + 1, state),
  ArrowUp: (state) => turn(state.page - 1, state),
}

/**
 * What a key asks of the viewer: `{type: "zoom" | "page", value}`, or `null` for a key that is not ours or that
 * changes nothing (already at the last page, at the biggest zoom). The arrows are the rail's own.
 *
 * @param {string} key the name of the key (`keyName`)
 * @param {{page: number, total: number, zoom: number}} state
 * @param {{rail?: boolean}} [where]
 */
export const keyAction = (key, state, {rail = false} = {}) => {
  const action = (rail ? {...KEYS, ...RAIL_KEYS} : KEYS)[key]?.(state) ?? null
  const current = {zoom: state.zoom, page: state.page}[action?.type]
  return action && action.value !== current ? action : null
}

/**
 * Runs the key of `event` through the viewer's table and hands the action to `send`; the key is consumed only
 * when there is an action.
 */
export const handleKey = (event, state, send, where) =>
  runKey(
    Object.fromEntries(
      [...Object.keys(KEYS), ...Object.keys(RAIL_KEYS)].map((key) => [
        key,
        () => {
          const action = keyAction(key, state, where)
          return action ? send(action) : false
        },
      ]),
    ),
    event,
  )
