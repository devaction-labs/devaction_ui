/** The other state of a switch, as the text of `aria-checked` and of the field. */
export const flip = (checked) => (checked === "true" ? "false" : "true")

/** The state after a press: the same while the switch is disabled or busy (`aria-disabled="true"`). */
export const press = (checked, disabled) => (disabled === "true" ? checked : flip(checked))
