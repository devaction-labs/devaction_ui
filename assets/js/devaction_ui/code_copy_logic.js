/** The copy button of a code block: idle until a copy, `copied` until the timer says reset. */
export const COPIED_MS = 1800

const STATES = {idle: {copy: "copied"}, copied: {copy: "copied", reset: "idle"}}

/** The state after an event; an event the state does not know leaves it as it is. */
export const next = (state, event) => STATES[state]?.[event] ?? state

/** Whether this browser (and this context: it needs https) can write to the clipboard. */
export const canCopy = (nav) => typeof nav?.clipboard?.writeText === "function"
