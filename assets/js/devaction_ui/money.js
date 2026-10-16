const BRL = {decimal: ",", group: ".", precision: 2, signed: false}

/**
 * Money as typed: digits only in, `1.234,56` out (the currency sign is the add-on beside the field), the last
 * `precision` digits being the minor units. Nothing typed is nothing shown. With `signed`, a `-` anywhere in
 * the text makes the amount negative, and alone it is kept as a sign waiting for its digits. The defaults are the
 * Brazilian real; every option is a `data-*` of the field.
 */
export const formatMoney = (typed, options = {}) => {
  const {decimal, group, precision, signed} = {...BRL, ...options}
  const digits = typed.replace(/\D/g, "")
  const sign = signed && typed.includes("-") ? "-" : ""
  const padded = digits.padStart(precision + 1, "0")
  const cut = padded.length - precision
  const whole = padded.slice(0, cut).replace(/^0+(?=\d)/, "").replace(/\B(?=(\d{3})+(?!\d))/g, () => group)
  const amount = precision === 0 ? whole : `${whole}${decimal}${padded.slice(cut)}`
  return digits === "" ? sign : `${sign}${amount}`
}

/** Brazilian reais as typed: `formatMoney` with its defaults. */
export const formatReais = (typed) => formatMoney(typed)

/** The options of the field, read from its `data-*` attributes; what is absent keeps the default. */
export const moneyOptions = (dataset) => ({
  ...(dataset.decimal === undefined ? {} : {decimal: dataset.decimal}),
  ...(dataset.group === undefined ? {} : {group: dataset.group}),
  ...(dataset.precision === undefined ? {} : {precision: Number(dataset.precision)}),
  signed: dataset.signed === "true",
})

/**
 * Where the caret goes after `before` became `after`: at the end when it was at the end, else after the same
 * number of digits as before, so editing in the middle does not jump to the end.
 */
export const caretAfter = (before, caret, after) => {
  const digitsBefore = before.slice(0, caret).replace(/\D/g, "").length
  const at = [...after].flatMap((char, index) => (/\d/.test(char) ? [index] : []))
  const signed = before.slice(0, caret).includes("-") && after.startsWith("-")
  const inside = digitsBefore === 0 ? Number(signed) : (at[digitsBefore - 1] ?? after.length - 1) + 1
  return caret >= before.length ? after.length : inside
}
