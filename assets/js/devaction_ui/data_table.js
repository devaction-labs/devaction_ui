import {nextDensity, selectionState} from "./data_table_logic.js"
import {notify} from "./dom.js"

/**
 * Row selection for `DataTable`: the header checkbox ticks them all and shows a mixed state when only some
 * are (the box is `indeterminate` and carries `data-partial`, which draws the dash), and a bulk bar with the
 * count appears while anything is ticked; every row says `aria-selected`. A redraw (a sort, a refresh) puts the
 * ticks back by value. Every change fires `input` on the table so a form around it hears it. The density toggle
 * (`[data-density-toggle]`) switches `data-density` between `comfortable` and `compact` in the browser, and the
 * choice is put back after a redraw.
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
    this.density && this.setDensity(this.density)
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
    const actions = {
      "[data-clear]": () => {
        this.rows().forEach((row) => (row.checked = false))
        this.changed()
      },
      "[data-density-toggle]": () => this.setDensity(nextDensity(this.el.dataset.density)),
    }
    const selector = Object.keys(actions).find((candidate) => event.target.closest(candidate))
    selector && actions[selector]()
  },

  setDensity(density) {
    this.density = density
    this.el.dataset.density = density
    this.el.querySelector("[data-density-toggle]")?.setAttribute("aria-pressed", String(density === "compact"))
  },

  changed() {
    this.sync()
    notify(this.el)
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
