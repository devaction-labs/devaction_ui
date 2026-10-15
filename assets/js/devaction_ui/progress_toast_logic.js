/** How long a finished job's toast stays before it leaves, and how long its exit animation gets. */
export const LINGER_MS = 1600
export const EXIT_MS = 250

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
