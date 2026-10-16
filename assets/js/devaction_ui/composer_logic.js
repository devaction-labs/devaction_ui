/**
 * What the composer decides without a DOM: how tall the field grows, whether the message can be sent, what the
 * counter says, what a key means and whether a drag carries files.
 */

/** The share of the limit from which the counter shows. */
const COUNT_FROM = 0.8

/**
 * The height of the field for its content: it grows with the text up to `maxRows` lines, then scrolls inside.
 *
 * @param {{scrollHeight: number, lineHeight: number, padding: number, maxRows: number}} measures pixels
 * @returns {{height: number, scrolls: boolean}}
 */
export const fieldHeight = ({scrollHeight, lineHeight, padding, maxRows}) => {
  const limit = lineHeight * maxRows + padding
  return {height: Math.min(scrollHeight, limit), scrolls: scrollHeight > limit}
}

/** Whether the text is over the limit (`maxLength` 0 means no limit). */
export const isOver = (text, maxLength) => maxLength > 0 && text.length > maxLength

/** Whether there is something to send: text that is not only blanks, within the limit, and the AI not answering. */
export const canSend = ({text, maxLength, busy}) => text.trim().length > 0 && !isOver(text, maxLength) && !busy

/**
 * What the counter shows: nothing until the text reaches 80% of the limit, then `length / limit` written for `locale`.
 *
 * @param {number} length
 * @param {number} maxLength
 * @param {string | undefined} locale
 * @returns {{hidden: boolean, text: string}}
 */
export const countView = (length, maxLength, locale) => {
  const shown = maxLength > 0 && length >= maxLength * COUNT_FROM
  const number = (value) => value.toLocaleString(locale)
  return {hidden: !shown, text: shown ? `${number(length)} / ${number(maxLength)}` : ""}
}

import {nextIndex} from "./editor_logic.js"

/** Not a key that confirms an accent or a word being composed (IME). */
const settled = (event) => !event.isComposing && event.keyCode !== 229

/** Enter without Shift, and not the Enter that confirms an accent or a word being composed (IME). */
const sends = (event) => event.key === "Enter" && !event.shiftKey && settled(event)

/**
 * What a key in the field means. While a suggestion list is open (`suggesting`) the keys are its: `"previous"` and
 * `"next"` (↑ ↓), `"pick"` (Enter or Tab) and `"close"` (Esc). Otherwise `"send"` (Enter with something to send),
 * `"hold"` (Enter with nothing to send: no new line either), `"stop"` (Esc while the AI answers), `"edit-last"`
 * (↑ in an empty field) or `"none"`.
 *
 * @param {KeyboardEvent} event
 * @param {{text: string, maxLength: number, busy: boolean, suggesting?: boolean}} state
 */
export const intentOf = (event, state) =>
  [
    [state.suggesting && settled(event) && event.key === "ArrowDown", "next"],
    [state.suggesting && settled(event) && event.key === "ArrowUp", "previous"],
    [state.suggesting && settled(event) && ["Enter", "Tab"].includes(event.key) && !event.shiftKey, "pick"],
    [state.suggesting && event.key === "Escape", "close"],
    [sends(event) && canSend(state), "send"],
    [sends(event), "hold"],
    [event.key === "Escape" && state.busy, "stop"],
    [event.key === "ArrowUp" && state.text === "", "edit-last"],
  ].find(([matches]) => matches)?.[1] ?? "none"

/** Whether a drag carries files (and not text or a link): `types` is `dataTransfer.types`. */
export const carriesFiles = (types) => [...(types ?? [])].includes("Files")

/** The files already chosen followed by the ones that arrive. */
export const joinFiles = (current, added) => [...(current ?? []), ...added]

/**
 * The word the caret is in when it is a `/` command (only at the very start of the text) or an `@` mention (at the
 * start of any word): its sign, what follows the sign up to the caret and where it spans in the text.
 *
 * @param {string} text
 * @param {number} caret
 * @returns {{trigger: "/" | "@", query: string, start: number, end: number} | null}
 */
export const triggerOf = (text, caret) => {
  const before = text.slice(0, caret)
  const start = before.search(/\S*$/)
  const word = before.slice(start)
  const opens = word.startsWith("@") || (word.startsWith("/") && start === 0)
  return opens ? {trigger: word[0], query: word.slice(1), start, end: caret} : null
}

/** The text with the typed word replaced by `insert` and a space, and where the caret goes. */
export const applyPick = (text, {start, end}, insert) => {
  const head = `${text.slice(0, start)}${insert} `
  return {text: `${head}${text.slice(end)}`, caret: head.length}
}

/** The highlighted row after a key of the suggestion list (the same row when the key is not one of its own). */
export const moveActive = (active, key, count) => nextIndex(active, key, count) ?? active
