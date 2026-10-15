/**
 * Keyboard handling by table instead of `if / else if`: a hook lists the keys it cares about and what each
 * does, and `runKey` looks the pressed key up. A key the table does not know is left alone.
 */

/** The name of a key with its modifier, e.g. `"Enter"`, `"Mod+Enter"` (⌘ or Ctrl), `"Alt+ArrowLeft"`. */
export const keyName = (event) => {
  const prefix = [event.altKey && "Alt", (event.metaKey || event.ctrlKey) && "Mod"].filter(Boolean)
  return [...prefix, event.key].join("+")
}

/**
 * Runs the handler the table has for the key of `event` and says whether there was one. A handler that
 * returns `false` declines the key (the event is not consumed); any other result consumes it with
 * `preventDefault`.
 *
 * @param {Record<string, (event: KeyboardEvent) => unknown>} table
 * @param {KeyboardEvent} event
 */
export const runKey = (table, event) => {
  const handler = table[keyName(event)]
  const result = handler?.(event)
  const consumed = handler !== undefined && result !== false
  consumed && event.preventDefault()
  return consumed
}

/** `index + delta` wrapped into `0...count`; `-1` for an empty list. */
export const wrap = (index, delta, count) => (count === 0 ? -1 : (((index + delta) % count) + count) % count)
