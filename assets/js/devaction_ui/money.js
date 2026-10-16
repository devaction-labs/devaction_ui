/**
 * Brazilian money as typed: digits only in, `1.234,56` out (the `R$` is the add-on beside the field), the last
 * two digits being the cents. Nothing typed is nothing shown.
 */
export const formatReais = (typed) => {
  const digits = typed.replace(/\D/g, "")
  if (digits === "") return ""
  const cents = digits.padStart(3, "0")
  const whole = cents.slice(0, -2).replace(/^0+(?=\d)/, "")
  return `${whole.replace(/\B(?=(\d{3})+(?!\d))/g, ".")},${cents.slice(-2)}`
}

/**
 * Where the caret goes after `before` became `after`: at the end when it was at the end, else after the same
 * number of digits as before, so editing in the middle does not jump to the end.
 */
export const caretAfter = (before, caret, after) => {
  const digitsBefore = before.slice(0, caret).replace(/\D/g, "").length
  const at = [...after].flatMap((char, index) => (/\d/.test(char) ? [index] : []))
  const inside = digitsBefore === 0 ? 0 : (at[digitsBefore - 1] ?? after.length - 1) + 1
  return caret >= before.length ? after.length : inside
}
