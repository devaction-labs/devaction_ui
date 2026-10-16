/**
 * The text the hooks compare and clean: matching that ignores case and accents, what is typed into the
 * pillbox before it becomes a tag, and the boxes of a one-time code.
 */

/** Lower case without accents, so "Pão" is found by "pao". */
export const fold = (text) =>
  text
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .toLowerCase()

/** Whether `label` contains `term`, ignoring case and accents; a blank term matches everything. */
export const matches = (label, term) => fold(label).includes(fold(term.trim()))

/** What was typed, cleaned: trimmed, without a trailing comma. Empty means nothing to add. */
export const clean = (raw) => raw.trim().replace(/,$/, "")

/** A text with its `%{label}` filled in; a text without the marker is left as it is, and nothing stays nothing. */
export const fillLabel = (pattern, label) => pattern?.replaceAll("%{label}", label)

/** Whether `value` is already among `values`, ignoring case. */
export const isTaken = (values, value) => values.some((known) => known.toLowerCase() === value.toLowerCase())

/**
 * The boxes of a one-time code. A code is a list of `length` one-character strings (`""` for an empty box); every
 * function here returns the new `{boxes, focus}` so the hook only draws them.
 */

/** The characters of `raw` a code box takes: digits only when `numeric`, spaces and dashes never, at most `length`. */
export const codeChars = (raw, {length, numeric}) =>
  [...raw.replace(numeric ? /\D/g : /[\s-]/g, "")].slice(0, length)

/** `length` empty boxes holding the characters of `text`. */
export const boxesOf = (text, length) => Array.from({length}, (_, index) => [...text][index] ?? "")

/** The value the form gets: what the boxes hold, in order, with no gaps. */
export const joinCode = (boxes) => boxes.join("")

/** Whether every box has a character. */
export const isComplete = (boxes) => boxes.every((box) => box !== "")

/** The index of the first empty box, or the last box when all are full. */
export const firstEmpty = (boxes) => {
  const index = boxes.indexOf("")
  return index === -1 ? boxes.length - 1 : index
}

/**
 * What typing or pasting `raw` into box `index` does: its characters fill that box and the next ones (a paste
 * of the whole code fills them all, wherever it lands), and the focus goes to the box after the last one filled, or
 * stays on the last box. Characters the code does not take are dropped; nothing taken leaves the boxes alone.
 */
export const enterChars = (boxes, index, raw, options) => {
  const chars = codeChars(raw, {length: boxes.length, numeric: options.numeric})
  const start = chars.length === boxes.length ? 0 : index
  const taken = chars.slice(0, boxes.length - start)
  const next = boxes.map((box, at) => taken[at - start] ?? box)
  const focus = Math.min(start + taken.length, boxes.length - 1)
  return taken.length === 0 ? {boxes, focus: index} : {boxes: next, focus}
}

/** Backspace: clears the box when it has a character, otherwise steps back and clears the box before. */
export const backspaceAt = (boxes, index) => {
  const target = boxes[index] === "" ? Math.max(index - 1, 0) : index
  return {boxes: boxes.map((box, at) => (at === target ? "" : box)), focus: target}
}

/** Delete: clears the box and stays on it. */
export const deleteAt = (boxes, index) => ({boxes: boxes.map((box, at) => (at === index ? "" : box)), focus: index})

const STEP = {ArrowLeft: -1, ArrowRight: 1}

/** The box an arrow key, Home or End moves to; `undefined` for another key. */
export const moveBox = (key, index, length) =>
  ({Home: () => 0, End: () => length - 1})[key]?.() ??
  (STEP[key] === undefined ? undefined : Math.min(Math.max(index + STEP[key], 0), length - 1))
