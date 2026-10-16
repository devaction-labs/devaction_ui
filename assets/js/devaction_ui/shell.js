import {GROUPS_KEY, MOBILE_BELOW, expanded, isToggleKey, otherState, pageInert, parseGroups, stateCookie, stateOf, toggleLabel, withGroup} from "./shell_logic.js"

const readGroups = () => {
  try {
    return parseGroups(localStorage.getItem(GROUPS_KEY))
  } catch {
    return {}
  }
}

const writeGroups = (groups) => {
  try {
    localStorage.setItem(GROUPS_KEY, JSON.stringify(groups))
  } catch {
    return
  }
}

/**
 * The shell of an app: a sidebar that collapses to a rail and, below 1024px, becomes a drawer over the page.
 * ⌘B or Ctrl+B and the `[data-sidebar-toggle]` button switch it; on a desktop screen the choice is the
 * `data-sidebar` attribute (`open` or `rail`) and the `dui_sidebar` cookie, which the server reads to render the
 * right state on the next first paint; on a small screen it is `data-mobile-open`. The backdrop, Esc and
 * following a link close the drawer, and focus goes into it and back out; while it is open the page behind is
 * `inert`, so the keys cannot wander off into it. A `[data-sidebar-group]` keeps being
 * open or closed in the local storage, by its id. The shell fires `dui:sidebar` with `{detail: {state}}` when
 * the state changes. LiveView is told to leave these attributes alone, so a patch does not undo what the
 * person chose.
 */
export default {
  mounted() {
    this.groups = readGroups()
    this.query = window.matchMedia(`(max-width: ${MOBILE_BELOW - 0.02}px)`)
    this.onClick = (event) => this.click(event)
    this.onKey = (event) => this.key(event)
    this.onQuery = () => this.mobile() || this.closeDrawer(false)

    this.el.addEventListener("click", this.onClick)
    document.addEventListener("keydown", this.onKey)
    this.query.addEventListener("change", this.onQuery)

    this.el.querySelectorAll("[data-sidebar-group]").forEach((group) => {
      const id = group.dataset.sidebarGroup
      id in this.groups && this.setGroup(group, this.groups[id], false)
    })
    this.sync()
  },

  updated() {
    this.sync()
  },

  destroyed() {
    this.el.removeEventListener("click", this.onClick)
    document.removeEventListener("keydown", this.onKey)
    this.query.removeEventListener("change", this.onQuery)
  },

  mobile() {
    return this.query.matches
  },

  state() {
    return stateOf(this.el.dataset.sidebar)
  },

  drawerOpen() {
    return this.el.hasAttribute("data-mobile-open")
  },

  click(event) {
    const toggle = event.target.closest("[data-sidebar-toggle]")
    const group = event.target.closest("[data-group-toggle]")
    toggle && this.toggle(event)
    event.target.closest("[data-sidebar-backdrop]") && this.closeDrawer(true)
    group && this.toggleGroup(event, group)
    this.mobile() && event.target.closest(".shell-sidebar a[href]") && this.closeDrawer(false)
  },

  key(event) {
    isToggleKey(event, event.target) && this.toggle(event)
    event.key === "Escape" && this.drawerOpen() && this.closeDrawer(true)
  },

  toggle(event) {
    event.preventDefault()
    this.mobile() ? (this.drawerOpen() ? this.closeDrawer(true) : this.openDrawer()) : this.set(otherState(this.state()))
  },

  set(state) {
    this.el.dataset.sidebar = state
    document.cookie = stateCookie(state)
    this.sync()
    this.el.dispatchEvent(new CustomEvent("dui:sidebar", {detail: {state}, bubbles: true}))
  },

  openDrawer() {
    this.opener = document.activeElement
    this.el.setAttribute("data-mobile-open", "")
    this.sync()
    requestAnimationFrame(() => this.el.querySelector(".shell-sidebar a[href], .shell-sidebar button")?.focus())
  },

  closeDrawer(restore) {
    this.drawerOpen() && this.el.removeAttribute("data-mobile-open")
    this.sync()
    restore && this.opener?.focus?.()
  },

  sync() {
    const inert = pageInert({mobile: this.mobile(), drawerOpen: this.drawerOpen()})
    this.el.querySelectorAll(":scope > :not(.shell-sidebar, .shell-backdrop)").forEach((part) => (part.inert = inert))
    const isExpanded = expanded({mobile: this.mobile(), drawerOpen: this.drawerOpen(), state: this.state()})
    this.el.querySelectorAll("[data-sidebar-toggle]").forEach((button) => {
      button.setAttribute("aria-expanded", String(isExpanded))
      const label = toggleLabel(isExpanded, {open: button.dataset.labelOpen, close: button.dataset.labelClose})
      label && button.setAttribute("aria-label", label)
    })
  },

  toggleGroup(event, button) {
    event.preventDefault()
    this.setGroup(button.closest("[data-sidebar-group]"), button.getAttribute("aria-expanded") !== "true", true)
  },

  setGroup(group, open, persist) {
    group.querySelector("[data-group-toggle]")?.setAttribute("aria-expanded", String(open))
    const body = group.querySelector("[data-group-body]")
    body && (body.hidden = !open)
    group.toggleAttribute("data-collapsed", !open)
    persist && this.remember(group.dataset.sidebarGroup, open)
  },

  remember(id, open) {
    this.groups = withGroup(this.groups, id, open)
    writeGroups(this.groups)
  },
}
