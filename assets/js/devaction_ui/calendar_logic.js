/**
 * Where the focus goes in a grid of days when a key is pressed, as an index into the cells (row by row):
 * the arrows move a day or a week, Home and End go to the start and the end of the week, and the page keys
 * are not a move inside the grid (they ask for another month, `"prev"` or `"next"`). `null` means the key is not ours.
 */
export function target(index, key, {columns, total}) {
  const clamp = (value) => Math.min(Math.max(value, 0), total - 1)
  const row = Math.floor(index / columns) * columns

  const moves = {
    ArrowLeft: () => clamp(index - 1),
    ArrowRight: () => clamp(index + 1),
    ArrowUp: () => clamp(index - columns),
    ArrowDown: () => clamp(index + columns),
    Home: () => row,
    End: () => clamp(row + columns - 1),
    PageUp: () => "prev",
    PageDown: () => "next",
  }

  return moves[key]?.() ?? null
}
