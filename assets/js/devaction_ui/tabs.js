import {runKey, wrap} from "./keys.js"

/**
 * Tabs that switch panels on the client. ← → move the selection round the list, Home and End jump to the
 * ends, and only the selected tab is in the tab order (roving tabindex). The server renders the first
 * selection; LiveView is told not to undo what this changes (`JS.ignore_attributes` on the tabs and panels).
 */
export default {
  mounted() {
    this.el.addEventListener("click", (event) => this.onClick(event))
    this.el.addEventListener("keydown", (event) => this.onKey(event))
  },

  tabs() {
    return [...this.el.querySelectorAll('[role="tablist"] > [role="tab"]')]
  },

  onClick(event) {
    const tab = event.target.closest('[role="tab"]')
    tab && this.el.contains(tab) && this.select(tab)
  },

  onKey(event) {
    if (!event.target.closest('[role="tablist"]')) return
    const tabs = this.tabs()
    const current = tabs.findIndex((tab) => tab.getAttribute("aria-selected") === "true")
    const go = (to) => () => {
      const tab = tabs[to(current, tabs.length)]
      this.select(tab)
      tab.focus()
    }

    runKey(
      {
        ArrowRight: go((at, count) => wrap(at, 1, count)),
        ArrowLeft: go((at, count) => wrap(at, -1, count)),
        Home: go(() => 0),
        End: go((_at, count) => count - 1),
      },
      event,
    )
  },

  select(selected) {
    this.tabs().forEach((tab) => {
      const on = tab === selected
      tab.setAttribute("aria-selected", String(on))
      tab.tabIndex = on ? 0 : -1
      const panel = this.el.querySelector(`#${CSS.escape(tab.getAttribute("aria-controls"))}`)
      panel && (panel.hidden = !on)
    })
  },
}
