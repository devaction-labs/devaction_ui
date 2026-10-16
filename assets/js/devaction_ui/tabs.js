import {keyName} from "./keys.js"
import {nextTab, resolveSelection} from "./tabs_logic.js"

/**
 * Tabs that switch panels on the client. ← → move the selection round the list, Home and End jump to the
 * ends, and only the selected tab is in the tab order (roving tabindex).
 *
 * The server renders the selection (`data-server-selected`). What the person picks in the browser lives in
 * `data-selected`, which LiveView is told to leave alone, and is put back after every patch, so it survives
 * the server re-rendering the tabs; when the server itself changes its selection, the server wins.
 */
export default {
  mounted() {
    this.lastServer = this.el.dataset.serverSelected
    this.el.addEventListener("click", (event) => this.onClick(event))
    this.el.addEventListener("keydown", (event) => this.onKey(event))
  },

  updated() {
    const ids = this.tabs().map((tab) => tab.dataset.tab)
    const next = resolveSelection({
      chosen: this.el.dataset.selected ?? "",
      lastServer: this.lastServer,
      server: this.el.dataset.serverSelected,
      ids,
    })

    this.lastServer = next.lastServer
    this.el.dataset.selected = next.chosen
    this.apply(next.selected)
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
    const target = tabs[nextTab(keyName(event), current, tabs.length)]

    target && this.go(event, target)
  },

  go(event, target) {
    event.preventDefault()
    this.select(target)
    target.focus()
  },

  select(selected) {
    this.el.dataset.selected = selected.dataset.tab
    this.apply(selected.dataset.tab)
  },

  apply(id) {
    this.tabs().forEach((tab) => {
      const on = tab.dataset.tab === id
      tab.setAttribute("aria-selected", String(on))
      tab.tabIndex = on ? 0 : -1
      const panel = this.el.querySelector(`#${CSS.escape(tab.getAttribute("aria-controls"))}`)
      panel && (panel.hidden = !on)
    })
  },
}
