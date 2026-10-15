/**
 * Decisions as a table, not an `if / else if` chain: each rule is `[test, result]`, the first test that
 * passes decides, and the last rule is usually `[() => true, ...]`. Both receive the same arguments.
 *
 * @template R
 * @param {Array<[(...args: any[]) => boolean, (...args: any[]) => R]>} rules
 * @returns {R}
 */
export const decide = (rules, ...args) => rules.find(([test]) => test(...args))[1](...args)
