import {formatIso, maskDate, readDate} from "./dates.js"
import {notify} from "./dom.js"

const SET_EVENT = "devaction:date-picker-set"
const PICKER_INPUTS = "[data-from-input], [data-to-input]"

/**
 * The text fields of `date_input/1` and `date_range/1`. The person types digits and the mask puts the
 * separators in; a complete, existing date goes (as ISO) into the hidden input the form sends, and the
 * calendar in the popover is told to show it. A day picked in the calendar goes the other way: it is written
 * in the text field and in the hidden input, and the popover closes once the date (or the range) is complete.
 *
 * The text fields have no name and the calendar's own inputs are not sent: only the hidden inputs fire
 * `input`, so `phx-change` hears one event per change.
 */
export default {
  mounted() {
    const data = this.el.dataset
    this.format = {order: data.order, separator: data.separator}
    this.min = data.min || null
    this.range = data.mode === "range"
    this.collect()
    this.el.addEventListener("input", (event) => this.onInput(event))
  },

  updated() {
    this.collect()
    this.syncPicker()
  },

  collect() {
    const find = (side) => ({
      text: this.el.querySelector(`[data-date-text="${side}"]`),
      value: this.el.querySelector(`[data-date-value="${side}"]`),
    })
    this.fields = Object.fromEntries(["from", "to"].map((side) => [side, find(side)]).filter(([, field]) => field.text))
  },

  onInput(event) {
    const side = event.target.dataset?.dateText
    side ? this.typed(side, event) : event.target.matches?.(PICKER_INPUTS) && this.picked(event)
  },

  minFor(side) {
    const from = side === "to" ? this.fields.from?.value.value : null
    return [this.min, from].filter(Boolean).sort().pop() ?? null
  },

  typed(side, event) {
    event.stopPropagation()
    const field = this.fields[side]
    const text = maskDate(field.text.value, this.format)
    const {iso, status} = readDate(text, this.format, this.minFor(side))

    field.text.value = text
    this.flag(field.text, status === "invalid")
    this.commit(side, iso ?? "")
    this.syncPicker()
  },

  picked(event) {
    event.stopPropagation()
    const picker = event.target.closest("[data-date-picker]")
    const from = picker.querySelector("[data-from-input]").value
    const to = picker.querySelector("[data-to-input]")?.value ?? ""

    this.write("from", from)
    this.range && this.write("to", to)
    ;(this.range ? to : from) && this.close()
  },

  write(side, iso) {
    const field = this.fields[side]
    field.text.value = formatIso(iso, this.format)
    this.flag(field.text, false)
    this.commit(side, iso)
  },

  commit(side, iso) {
    const value = this.fields[side].value
    const changed = value.value !== iso
    value.value = iso
    changed && notify(value)
  },

  flag(text, invalid) {
    invalid ? text.setAttribute("aria-invalid", "true") : text.removeAttribute("aria-invalid")
  },

  syncPicker() {
    const value = (side) => this.fields[side]?.value.value || null
    const detail = {from: value("from"), to: value("to")}
    this.el.querySelector("[data-date-picker]")?.dispatchEvent(new CustomEvent(SET_EVENT, {detail}))
  },

  close() {
    const panel = this.el.querySelector("[data-panel]")
    panel && !panel.hidden && this.el.querySelector("[data-trigger] button")?.click()
  },
}
