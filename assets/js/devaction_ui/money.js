/**
 * Brazilian money as typed: digits only in, `R$ 1.234,56` out, the last two digits being the cents.
 * Nothing typed is nothing shown.
 */
export const formatReais = (typed) => {
  const digits = typed.replace(/\D/g, "")
  if (digits === "") return ""
  const cents = digits.padStart(3, "0")
  const whole = cents.slice(0, -2).replace(/^0+(?=\d)/, "")
  return `R$ ${whole.replace(/\B(?=(\d{3})+(?!\d))/g, ".")},${cents.slice(-2)}`
}
