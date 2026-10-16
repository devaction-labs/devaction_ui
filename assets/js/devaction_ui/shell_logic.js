export const COOKIE = "dui_sidebar"
export const GROUPS_KEY = "dui_sidebar_groups"
export const MOBILE_BELOW = 1024

/**
 * The state the sidebar goes to when toggled on a desktop screen.
 *
 * @param {string} state `"open"` or `"rail"`
 * @returns {"open" | "rail"}
 */
export const otherState = (state) => (state === "open" ? "rail" : "open")

/**
 * The state a `data-sidebar` value stands for: anything but `"rail"` is open.
 *
 * @param {string | undefined} value
 * @returns {"open" | "rail"}
 */
export const stateOf = (value) => (value === "rail" ? "rail" : "open")

/**
 * The cookie string that remembers the state, which the server reads on the next request to render the sidebar
 * right on the first paint.
 *
 * @param {string} state
 * @param {string} [name]
 */
export const stateCookie = (state, name = COOKIE) => `${name}=${state}; path=/; max-age=31536000; samesite=lax`

const keepsBold = ({tagName = "", isContentEditable = false}) => isContentEditable || tagName.toLowerCase() === "textarea"

/**
 * Whether a key press is the shortcut of the sidebar: ⌘B or Ctrl+B. A text area and an editor keep it for bold
 * unless Shift is held.
 *
 * @param {{key: string, metaKey?: boolean, ctrlKey?: boolean, altKey?: boolean, shiftKey?: boolean}} event
 * @param {{tagName?: string, isContentEditable?: boolean}} [target]
 */
export const isToggleKey = (event, target = {}) =>
  Boolean(event.metaKey || event.ctrlKey) &&
  !event.altKey &&
  event.key.toLowerCase() === "b" &&
  (Boolean(event.shiftKey) || !keepsBold(target))

/**
 * What `aria-expanded` of the toggle says: on a small screen the drawer, on a large one the full sidebar.
 *
 * @param {{mobile: boolean, drawerOpen: boolean, state: string}} view
 */
export const expanded = ({mobile, drawerOpen, state}) => (mobile ? drawerOpen : state === "open")

/**
 * The label of the toggle for the state it is in: it offers to close what is open.
 *
 * @param {boolean} isExpanded
 * @param {{open?: string, close?: string}} labels
 * @returns {string | undefined}
 */
export const toggleLabel = (isExpanded, {open, close}) => (isExpanded ? close : open)

/**
 * The open or closed state of each group, read from the storage: anything that is not an object of booleans
 * is an empty memory.
 *
 * @param {string | null} raw
 * @returns {Record<string, boolean>}
 */
export const parseGroups = (raw) => {
  try {
    const value = JSON.parse(raw ?? "{}")
    return Object.fromEntries(Object.entries(value).filter(([, open]) => typeof open === "boolean"))
  } catch {
    return {}
  }
}

/**
 * The groups with one of them set.
 *
 * @param {Record<string, boolean>} groups
 * @param {string} id
 * @param {boolean} open
 */
export const withGroup = (groups, id, open) => ({...groups, [id]: open})
