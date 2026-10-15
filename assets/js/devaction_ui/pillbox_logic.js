/** What was typed, cleaned: trimmed, without a trailing comma. Empty means nothing to add. */
export const clean = (raw) => raw.trim().replace(/,$/, "")

/** Whether `value` is already among `values`, ignoring case. */
export const isTaken = (values, value) => values.some((known) => known.toLowerCase() === value.toLowerCase())
