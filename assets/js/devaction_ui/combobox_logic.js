/**
 * What the button shows: the label of the chosen option, or the placeholder (muted) when nothing is chosen.
 *
 * @param {{label: string} | null | undefined} option
 * @param {string} placeholder
 * @returns {{text: string, muted: boolean}}
 */
export const buttonView = (option, placeholder) => ({text: option?.label ?? placeholder, muted: !option})
