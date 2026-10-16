import {nextTab, runKey} from "./keys.js"

const TAB_KEYS = ["ArrowLeft", "ArrowRight", "ArrowUp", "ArrowDown", "Home", "End"]

/**
 * Which tab is selected after the server patched the tabs. The tab the person chose in the browser stays,
 * unless the server has since changed its own selection (then the server wins) or that tab is gone.
 *
 * @param {{chosen: string, lastServer: string, server: string, ids: string[]}} state `chosen` is `""` when the
 *   person has not chosen; `lastServer` and `server` are the server's selection before and after the patch
 * @returns {{selected: string, chosen: string, lastServer: string}}
 */
export const resolveSelection = ({chosen, lastServer, server, ids}) =>
  chosen && server === lastServer && ids.includes(chosen)
    ? {selected: chosen, chosen, lastServer: server}
    : {selected: server, chosen: "", lastServer: server}

/**
 * Tabs that switch panels on the client. ← → (↑ ↓ in a vertical list) move the selection round the list, Home and End jump to the
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
    const layout = this.layout(event)
    const go = (key) => () => {
      const target = tabs[nextTab(key, current, tabs.length, layout)]
      return target ? this.go(target) : false
    }

    runKey(Object.fromEntries(TAB_KEYS.map((key) => [key, go(key)])), event)
  },

  layout(event) {
    const list = event.target.closest('[role="tablist"]')
    return {
      orientation: list.getAttribute("aria-orientation") ?? "horizontal",
      rtl: getComputedStyle(list).direction === "rtl",
    }
  },

  go(target) {
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
