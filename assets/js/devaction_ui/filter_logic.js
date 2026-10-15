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
