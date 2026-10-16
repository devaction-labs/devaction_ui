/**
 * How many options of each group are ticked, and how many in all, not counting the ones that are the
 * default (a default is what the filter already means before anyone picks anything).
 *
 * @param {{group: string, checked: boolean, isDefault: boolean}[]} options
 */
export function counts(options) {
  const ticked = options.filter((option) => option.checked && !option.isDefault)
  const byGroup = ticked.reduce((all, option) => ({...all, [option.group]: (all[option.group] ?? 0) + 1}), {})
  return {byGroup, total: ticked.length}
}

const keyOf = (option) => `${option.group}\u0000${option.value}`

/**
 * How many options are ticked differently in the draft than in what was applied: the changes that Apply
 * would send.
 *
 * @param {{group: string, value: string, checked: boolean}[]} draft
 * @param {{group: string, value: string, checked: boolean}[]} applied
 */
export function pendingCount(draft, applied) {
  const ticked = (options) => new Set(options.filter((option) => option.checked).map(keyOf))
  const now = ticked(draft)
  const before = ticked(applied)
  return [...now].filter((key) => !before.has(key)).length + [...before].filter((key) => !now.has(key)).length
}

/** How much room a submenu wants beyond its own width before it is moved to the other side. */
const MARGIN = 12

/**
 * The side a submenu opens on: the one asked for, unless it does not fit there and the other side has more
 * room.
 *
 * @param {"left" | "right"} wanted
 * @param {{panel: number, left: number, right: number}} room widths, in pixels
 */
export const submenuSide = (wanted, {panel, left, right}) => {
  const rules = {
    right: right < panel + MARGIN && left > right ? "left" : "right",
    left: left < panel + MARGIN && right > left ? "right" : "left",
  }
  return rules[wanted]
}
