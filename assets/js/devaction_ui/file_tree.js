import {isTyping, keyName, runKey, treeKey} from "./keys.js"
import {resolveSelection} from "./tabs.js"

const ARROWS = ["ArrowDown", "ArrowUp", "ArrowLeft", "ArrowRight", "Home", "End"]
const ITEM = '[role="treeitem"]'

/**
 * The keyboard of a file tree: ↑ ↓ Home End move the focus through the visible items, → opens a closed folder
 * or enters an open one, ← closes an open folder or goes to its parent, and Enter or Space presses the item
 * (the browser does that, the items are buttons). Only one item is in the Tab order (roving tabindex): the one
 * the server marks, until the person moves, and then the one that has the focus. The open folders and the
 * selection stay on the server: → and ← press the folder, which sends its toggle event.
 *
 * With `data-search-key` that key focuses the search field when the person is not typing in a field.
 */
export default {
  mounted() {
    this.lastServer = this.el.dataset.stop
    this.chosen = ""
    this.el.addEventListener("keydown", (event) => this.onKey(event))
    this.el.addEventListener("focusin", (event) => this.onFocus(event))
    this.onPageKey = (event) => this.searchKey(event)
    document.addEventListener("keydown", this.onPageKey)
  },

  updated() {
    const paths = this.items().map((item) => item.dataset.path)
    const next = resolveSelection({chosen: this.chosen, lastServer: this.lastServer, server: this.el.dataset.stop, ids: paths})

    this.lastServer = next.lastServer
    this.chosen = next.chosen
    this.rove(next.selected)
  },

  destroyed() {
    document.removeEventListener("keydown", this.onPageKey)
  },

  items() {
    return [...this.el.querySelectorAll(ITEM)]
  },

  meta(item) {
    const expanded = item.getAttribute("aria-expanded")
    return {level: Number(item.getAttribute("aria-level")), expandable: expanded !== null, expanded: expanded === "true"}
  },

  onKey(event) {
    const items = this.items()
    const index = items.indexOf(event.target.closest(ITEM))
    const go = (key) => () => {
      const move = treeKey(key, items.map((item) => this.meta(item)), index)
      return move ? this.apply(items, move) : false
    }

    runKey(Object.fromEntries(ARROWS.map((key) => [key, go(key)])), event)
  },

  apply(items, {focus, click}) {
    focus !== undefined && items[focus].focus()
    click !== undefined && items[click].click()
  },

  onFocus(event) {
    const item = event.target.closest(ITEM)
    this.chosen = item?.dataset.path ?? this.chosen
    item && this.rove(item.dataset.path)
  },

  rove(path) {
    this.items().forEach((item) => {
      item.tabIndex = item.dataset.path === path ? 0 : -1
    })
  },

  searchKey(event) {
    const field = this.el.querySelector("[data-tree-search]")
    const ours = field && keyName(event) === this.el.dataset.searchKey && !isTyping(event.target)
    ours && this.focusSearch(event, field)
  },

  focusSearch(event, field) {
    event.preventDefault()
    field.focus()
  },
}
