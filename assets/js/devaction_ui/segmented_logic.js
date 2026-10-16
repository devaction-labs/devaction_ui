import {wrap} from "./keys.js"

const openIndexes = (items) => items.flatMap((item, index) => (item.disabled ? [] : [index]))

/**
 * The index of the one segment in the Tab order (roving tabindex): the pressed one, or the first one that is
 * not disabled when none is. `-1` when every segment is disabled.
 * @param {{pressed: boolean, disabled: boolean}[]} items
 */
export const tabStop = (items) => {
  const open = openIndexes(items)
  return open.find((index) => items[index].pressed) ?? open[0] ?? -1
}

const STEPS = {ArrowRight: 1, ArrowDown: 1, ArrowLeft: -1, ArrowUp: -1}

/**
 * The index the focus goes to from segment `from` on a key (arrows step and wrap, Home and End jump to the
 * ends), skipping the disabled ones; `undefined` for a key the control does not use.
 * @param {{pressed: boolean, disabled: boolean}[]} items
 */
export const move = (items, from, key) => {
  const open = openIndexes(items)
  const jump = {Home: () => open[0], End: () => open.at(-1)}[key]
  const step = STEPS[key]
  return jump?.() ?? (step === undefined ? undefined : open[wrap(open.indexOf(from), step, open.length)])
}
