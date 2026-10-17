/**
 * What the listbox decides without a DOM: the text of its button, which options a search keeps (by the label
 * and the keywords, ignoring case and accents), whether the "create" row shows, and the values after a choice.
 */
import {fold, matches} from "./text.js"

/** A text with its `%{name}` markers filled from `values`; nothing stays nothing. */
export const fill = (pattern, values) =>
  pattern == null ? pattern : Object.entries(values).reduce((text, [key, value]) => text.replaceAll(`%{${key}}`, String(value)), pattern)

/** Whether an option is kept by the search `term`: its label or its keywords contain it. */
export const keeps = ({label, keywords = ""}, term) => matches(`${label} ${keywords}`, term)

/** Whether the "create" row shows: something was typed and no option is called exactly that. */
export const canCreate = (term, labels) => term.trim() !== "" && !labels.some((label) => fold(label) === fold(term.trim()))

/**
 * The values after choosing `value`: a single listbox keeps only it, a multiple one adds it or takes it away.
 *
 * @param {string[]} values
 * @param {string} value
 * @param {boolean} multiple
 */
export const pick = (values, value, multiple) =>
  multiple ? (values.includes(value) ? values.filter((known) => known !== value) : [...values, value]) : [value]

/**
 * What the button shows: the placeholder (muted) when nothing is chosen, the label of the choice, and for a
 * multiple listbox the count text (`"%{count} chosen"`) or, without one, the labels joined.
 *
 * @param {{labels: string[], multiple: boolean, placeholder: string, countText?: string | null}} state
 */
export const buttonText = ({labels, multiple, placeholder, countText}) =>
  labels.length === 0
    ? {text: placeholder, muted: true}
    : {text: multiple && countText ? fill(countText, {count: labels.length}) : labels.join(", "), muted: false}
