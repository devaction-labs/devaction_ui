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
