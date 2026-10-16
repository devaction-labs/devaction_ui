/**
 * Whether a key press closes the open list of collapsed pages: Esc does, and only while it is open.
 *
 * @param {{key: string}} event
 * @param {boolean} open
 */
export const closesOnKey = (event, open) => open && event.key === "Escape"

/**
 * Whether a press landed outside the list, so it closes: the list is open and the target is not inside it.
 *
 * @param {{contains: (node: unknown) => boolean}} root
 * @param {unknown} target
 * @param {boolean} open
 */
export const closesOnPress = (root, target, open) => open && !root.contains(target)
