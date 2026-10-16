/**
 * The toasts without a DOM: how the pile is placed from the heights of its toasts, how tall the list is, what the
 * timers, the swipe and the hotkey do, and when the notice of a finished job leaves by itself.
 */

/** The toast variants the group draws. */
export const VARIANTS = ["default", "ok", "warn", "risk", "info", "ai", "loading"]

/** Pixels the pile uses: the gap of the open list and how much each layer peeks above the one in front. */
export const GAP_PX = 12
export const PEEK_PX = 12

/** How far sideways a toast has to be dragged to leave, and how long the open list waits before closing. */
export const SWIPE_PX = 80
export const CLOSE_DELAY_MS = 120

/** How many toasts the group keeps at most; the oldest are dropped past it. */
export const MAX_TOASTS = 20

const ROLES = {risk: "alert"}

/** The ARIA role of a toast: an error is announced at once, the rest politely. */
export const roleFor = (variant) => ROLES[variant] ?? "status"

/** The variant, or `default` for one the group does not know. */
export const variantOf = (variant) => (VARIANTS.includes(variant) ? variant : "default")

/**
 * How long a toast stays: `loading` never leaves by itself, the others take `duration` (the group's when absent);
 * zero (or less) keeps a toast until it is closed.
 */
export const durationFor = ({variant, duration, fallback}) => {
  const wanted = duration ?? fallback
  return variant === "loading" || wanted <= 0 ? Infinity : wanted
}

/**
 * Where each toast of the pile goes. `heights` are the natural heights, newest first. A toast past `visible`
 * is an overflow (hidden while the pile is closed); the open list stacks the toasts with `gap` between them.
 *
 * @param {number[]} heights
 * @param {{visible: number, gap?: number, peek?: number}} options
 */
export const stackPlan = (heights, {visible, gap = GAP_PX, peek = PEEK_PX}) => {
  const front = heights[0] ?? 0
  const items = heights.map((height, index) => ({
    index,
    height,
    offset: heights.slice(0, index).reduce((sum, h) => sum + h + gap, 0),
    front: index === 0,
    overflow: index >= visible,
  }))
  const open = Math.max(0, heights.reduce((sum, h) => sum + h + gap, -gap))
  const closed = heights.length === 0 ? 0 : front + Math.min(heights.length - 1, visible - 1) * peek
  return {front, items, open, closed}
}

/** The height of the list: the whole open list, or the front toast plus the layers that peek. */
export const listHeight = (plan, expanded) => (expanded ? plan.open : plan.closed)

/** What a timer does when the pile is paused (open or tab hidden) or not: `pause`, `start` or `keep`. */
export const timerStep = ({paused, running, finite}) =>
  [
    [!finite, "keep"],
    [paused && running, "pause"],
    [!paused && !running, "start"],
  ].find(([hit]) => hit)?.[1] ?? "keep"

/** What a drag ending at `dx` pixels does: `dismiss` past the threshold, else `restore`. */
export const swipeOutcome = (dx, threshold = SWIPE_PX) => (dx > threshold ? "dismiss" : "restore")

/** Whether a key event is the hotkey that focuses the pile (Alt+T, whatever the layout makes of the letter). */
export const isHotkey = (event) => event.altKey && !event.ctrlKey && !event.metaKey && (event.code === "KeyT" || event.key?.toLowerCase() === "t")

/** Whether an event from the server is for the group `id`: one without a `group` is for every group on the page. */
export const isForGroup = (payload, id) => payload?.group === undefined || payload.group === id

/** Which toast gets the focus when the focused one leaves: the one that takes its place, or the last, else none. */
export const focusAfter = (remaining, index) => (remaining === 0 ? null : Math.min(index, remaining - 1))

/** How long a finished job's toast stays before it leaves, and how long its exit animation gets. */
export const LINGER_MS = 1600
export const EXIT_MS = 400

/**
 * What the toast should do now. A job that is done leaves after LINGER_MS, with the time the pointer or
 * focus spent on it not counted; one that is running or failed stays.
 *
 * `remaining` is what is left of the wait (LINGER_MS when it has not started), `paused` whether the
 * pointer or the focus is on it. The answer is `{wait: ms}` to leave after that time, or `{wait: null}`
 * to stay where it is.
 */
export function plan({state, remaining = LINGER_MS, paused = false}) {
  return state === "done" && !paused ? {wait: Math.max(0, remaining)} : {wait: null}
}

/** What is left of a wait that started at `startedAt` and is being interrupted at `now`. */
export function leftAfter(remaining, startedAt, now) {
  return Math.max(0, remaining - (now - startedAt))
}
