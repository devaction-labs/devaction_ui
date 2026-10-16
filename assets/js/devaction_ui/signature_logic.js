const SIZE = {width: 360, height: 170}

const DEFAULT_COLOR = "#18181B"

/** One decimal, so a stroke stays short. */
export function round(value) {
  return Math.round(value * 10) / 10
}

/** The point of a pointer inside the box of the pad, scaled to the drawing's own size. */
export function toPoint(event, box, size = SIZE) {
  return [
    round(((event.clientX - box.left) / box.width) * size.width),
    round(((event.clientY - box.top) / box.height) * size.height),
  ]
}

/** One stroke as path commands; a single touch is a dot (a zero length line). */
export function strokePath(points) {
  if (points.length === 0) return ""
  const [first, ...rest] = points
  const lines = (rest.length === 0 ? [first] : rest).map(([x, y]) => `L${x} ${y}`)
  return [`M${first[0]} ${first[1]}`, ...lines].join(" ")
}

/** All the strokes as one path, or an empty text when nothing was drawn. */
export function signaturePath(strokes) {
  return strokes.map(strokePath).join(" ")
}

/** The SVG of a path in `color`, or `null` when nothing was drawn. The path is only commands and numbers, written by the code above. */
export function toSvg(path, color = DEFAULT_COLOR) {
  return path === ""
    ? null
    : `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${SIZE.width} ${SIZE.height}"><path d="${path}" fill="none" stroke="${color}" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/></svg>`
}

/** The status text for the strokes drawn: `empty` with none, `ready` with some. */
export const statusText = (strokes, {empty, ready}) => (strokes.length === 0 ? empty : ready) ?? ""
