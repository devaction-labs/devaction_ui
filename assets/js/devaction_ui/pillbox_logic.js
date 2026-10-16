/** What was typed, cleaned: trimmed, without a trailing comma. Empty means nothing to add. */
export const clean = (raw) => raw.trim().replace(/,$/, "")

/** A text with its `%{label}` filled in; a text without the marker is left as it is, and nothing stays nothing. */
export const fillLabel = (pattern, label) => pattern?.replaceAll("%{label}", label)

/** Whether `value` is already among `values`, ignoring case. */
export const isTaken = (values, value) => values.some((known) => known.toLowerCase() === value.toLowerCase())
