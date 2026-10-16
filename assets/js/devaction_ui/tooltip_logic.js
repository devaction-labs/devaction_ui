import {decide} from "./keys.js"

/** What a control that can take the focus looks like: the first one inside a tooltip is what it describes. */
export const FOCUSABLE =
  'a[href], button:not([disabled]), input:not([disabled]):not([type="hidden"]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])'

/**
 * The value of `aria-describedby` with `id` in it: the ids it already had are kept, and `id` is not
 * added twice.
 *
 * @param {string | null | undefined} current
 * @param {string} id
 */
export const withDescription = (current, id) => {
  const ids = (current ?? "").split(/\s+/).filter(Boolean)
  return [...new Set([...ids, id])].join(" ")
}

/** Pointers that tap rather than hover: after one, the hint is dismissed instead of left open. */
const TAPS = {touch: true, pen: false, mouse: false}

/** @param {string | undefined} pointerType the `pointerType` of a pointer event */
export const dismissesOnTap = (pointerType) => TAPS[pointerType] ?? false

/**
 * What a hover card does when the pointer or the focus comes or goes. `phase` is `"closed"`, `"opening"` (the pointer is
 * on the trigger and the delay has not run out), `"open"` or `"closing"` (nothing holds it and the delay before it
 * closes is running); `pointer` and `focus` say what holds it now, and `dismissed` that Esc closed it. The answer is
 * the next phase and what the hook does with its timers: `"open"` and `"close"` start the delay of that name, `"now"`
 * opens at once (the keyboard does not wait), and `"none"` leaves the timers alone. The pointer may cross the gap to the
 * card, and a card held by the pointer or the focus is never closed by the delay (WCAG 1.4.13: persistent, hoverable).
 *
 * @param {{phase: string, pointer: boolean, focus: boolean, dismissed: boolean}} state
 * @returns {{phase: string, schedule: "open" | "close" | "now" | "cancel" | "none"}}
 */
export const settle = ({phase, pointer, focus, dismissed}) =>
  decide(
    [
      [() => dismissed, () => ({phase: "closed", schedule: "cancel"})],
      [() => focus && phase === "open", () => ({phase: "open", schedule: "cancel"})],
      [() => focus, () => ({phase: "open", schedule: "now"})],
      [() => pointer && phase === "open", () => ({phase: "open", schedule: "cancel"})],
      [() => pointer && phase === "opening", () => ({phase: "opening", schedule: "none"})],
      [() => pointer && phase === "closing", () => ({phase: "open", schedule: "cancel"})],
      [() => pointer, () => ({phase: "opening", schedule: "open"})],
      [() => phase === "open" || phase === "closing", () => ({phase: "closing", schedule: phase === "open" ? "close" : "none"})],
      [() => true, () => ({phase: "closed", schedule: "cancel"})],
    ],
    {phase, pointer, focus, dismissed},
  )

/** Whether the card is shown in a phase. */
export const isShown = (phase) => phase === "open" || phase === "closing"

/** What a timer that ran out does to the phase: the delay to open opens it, the delay to close closes it, anything else changes nothing. */
export const afterTimer = (phase, timer) => ({opening: {open: "open"}, closing: {close: "closed"}})[phase]?.[timer] ?? phase

/** Whether a tap on the trigger should be taken by the card (it opens, and the link under the finger does not go) rather than passed on: only a finger, and only while the card is closed. */
export const tapOpens = (pointerType, phase) => pointerType === "touch" && !isShown(phase)
