/** How much a screen drawn `designWidth` wide has to shrink to fit `available` pixels; it never grows. */
export function fitScale(available, designWidth) {
  return designWidth <= 0 ? 1 : Math.min(1, available / designWidth)
}
