/**
 * The text the hooks compare and clean: matching that ignores case and accents, and what is typed into the
 * pillbox before it becomes a tag.
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
