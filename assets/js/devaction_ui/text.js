/** Lower case without accents, so "Pão" is found by "pao". */
export const fold = (text) =>
  text
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .toLowerCase()

/** Whether `label` contains `term`, ignoring case and accents; a blank term matches everything. */
export const matches = (label, term) => fold(label).includes(fold(term.trim()))
