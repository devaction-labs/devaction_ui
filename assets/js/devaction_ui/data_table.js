import {selectionState} from "./data_table_logic.js"

/**
 * Row selection for `DataTable`: the header checkbox ticks them all and shows a mixed state when only some
 * are (the box is `indeterminate` and carries `data-partial`, which draws the dash), and a bulk bar with the
 * count appears while anything is ticked; every row says `aria-selected`. A redraw (a sort, a refresh) puts the
 * ticks back by value. Every change fires `input` on the table so a form around it hears it.
 */
export default {
  mounted() {
    this.el.addEventListener("change", (event) => this.onChange(event))
    this.el.addEventListener("click", (event) => this.onClick(event))
    this.sync()
  },

  beforeUpdate() {
    this.kept = new Set(this.rows().filter((row) => row.checked).map((row) => row.value))
  },

  updated() {
    this.rows().forEach((row) => (row.checked = this.kept.has(row.value)))
    this.sync()
  },

  rows() {
    return [...this.el.querySelectorAll("[data-select-row]")]
  },

  onChange(event) {
    const reactions = {
      "[data-select-all]": () => this.rows().forEach((row) => (row.checked = event.target.checked)),
      "[data-select-row]": () => {},
    }
    const selector = Object.keys(reactions).find((candidate) => event.target.matches(candidate))
    reactions[selector]?.()
    selector && this.changed()
  },

  onClick(event) {
    if (!event.target.closest("[data-clear]")) return
    this.rows().forEach((row) => (row.checked = false))
    this.changed()
  },

  changed() {
    this.sync()
    this.el.dispatchEvent(new Event("input", {bubbles: true}))
  },

  sync() {
    const rows = this.rows()
    const checked = rows.filter((row) => row.checked).length
    const state = selectionState(checked, rows.length)

    const all = this.el.querySelector("[data-select-all]")
    all && Object.assign(all, {checked: state.all, indeterminate: state.mixed})
    all && (all.dataset.partial = String(state.mixed))
    rows.forEach((row) => row.closest("tr").setAttribute("aria-selected", String(row.checked)))

    const bar = this.el.querySelector("[data-bulk]")
    bar && (bar.hidden = state.barHidden)
    bar && (bar.querySelector("[data-count]").textContent = this.el.dataset.selectedLabel.replace("__COUNT__", checked))
  },
}
