import {target} from "./calendar_logic.js"

/**
 * The keyboard of a calendar grid: `phx-hook="DevactionUI.Calendar"` on the `role="grid"` box with
 * `data-columns`. One cell has `tabindex="0"`; the arrows, Home and End move it (and the focus) by day and by
 * week, the page keys press the previous and the next button of the calendar, and Enter or Space press the day.
 * The cell that holds the focus stays the one in the tab order after the server redraws the grid.
 */
export default {
  mounted() {
    this.el.addEventListener("keydown", (event) => this.onKey(event))
    this.el.addEventListener("focusin", (event) => this.remember(event.target))
  },

  updated() {
    this.restore()
  },

  cells() {
    return [...this.el.querySelectorAll('[role="gridcell"]')]
  },

  remember(cell) {
    this.lastDate = cell.closest?.('[role="gridcell"]')?.dataset.date ?? this.lastDate
  },

  restore() {
    const cells = this.cells()
    const keep = cells.find((cell) => cell.dataset.date === this.lastDate)
    keep && cells.forEach((cell) => cell.setAttribute("tabindex", cell === keep ? "0" : "-1"))
  },

  onKey(event) {
    const cell = event.target.closest?.('[role="gridcell"]')
    if (!cell) return

    if (event.key === "Enter" || event.key === " ") {
      event.preventDefault()
      return cell.click()
    }

    const cells = this.cells()
    const index = cells.indexOf(cell)
    const next = target(index, event.key, {columns: Number(this.el.dataset.columns), total: cells.length})
    if (next === null) return

    event.preventDefault()
    next === "prev" || next === "next" ? this.page(next) : this.focus(cells, next)
  },

  focus(cells, index) {
    cells.forEach((cell, at) => cell.setAttribute("tabindex", at === index ? "0" : "-1"))
    cells[index].focus()
  },

  page(direction) {
    const root = this.el.parentElement
    root.querySelector(`[id$="-${direction}"]`)?.click()
  },
}
