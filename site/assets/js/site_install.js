import {nextIndex, tabStates} from "./install_tabs_logic.js"

export default {
  mounted() {
    this.active = this.el.dataset.initial
    this.onClick = (event) => {
      const tab = event.target.closest("[role='tab']")
      tab && this.select(tab.dataset.tab, false)
    }
    this.onKey = (event) => {
      const tabs = this.tabs()
      const current = tabs.findIndex((tab) => tab.dataset.tab === this.active)
      const next = nextIndex(tabs.length, current, event.key)
      next !== null && (event.preventDefault(), this.select(tabs[next].dataset.tab, true))
    }
    this.el.addEventListener("click", this.onClick)
    this.el.addEventListener("keydown", this.onKey)
    this.select(this.active, false)
  },
  updated() {
    this.select(this.active, false)
  },
  destroyed() {
    this.el.removeEventListener("click", this.onClick)
    this.el.removeEventListener("keydown", this.onKey)
  },
  tabs() {
    return [...this.el.querySelectorAll("[role='tab']")]
  },
  select(id, focus) {
    this.active = id
    const tabs = this.tabs()
    tabStates(tabs.map((tab) => tab.dataset.tab), id).forEach((state, index) => {
      tabs[index].setAttribute("aria-selected", String(state.selected))
      tabs[index].setAttribute("tabindex", state.tabindex)
      focus && state.selected && tabs[index].focus()
    })
    this.el.querySelectorAll("[role='tabpanel']").forEach((panel) => {
      panel.hidden = panel.dataset.tab !== id
    })
    const panel = this.el.querySelector(`[role='tabpanel'][data-tab='${id}']`)
    this.el.querySelector("[data-copy-text]")?.setAttribute("data-copy-text", panel?.dataset.copy ?? "")
  },
}
