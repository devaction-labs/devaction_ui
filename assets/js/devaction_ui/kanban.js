import {runKey} from "./keys.js"
import {insertionIndex, isFull, parseWip} from "./kanban_logic.js"

/**
 * A board of columns with cards that move. Drag a card to another column or another place in its own, or
 * focus it and press Alt + arrow keys (←→ between columns, ↑↓ within one). The card moves in the page at
 * once and the LiveView, which stays the source of truth, gets one event with
 * `{card, from, to, index}`. A column with a limit that is full takes no more cards from outside, and every
 * move is announced in a live region, and every card is described by the keyboard hint of the board
 * (`data-hint-id`). After the server redraws, the focus goes back to the moved card. Dragging is HTML5 drag
 * and drop: on a touch screen the keyboard is the way that always works.
 */
export default {
  mounted() {
    this.el.addEventListener("dragstart", (event) => this.onDragStart(event))
    this.el.addEventListener("dragover", (event) => this.onDragOver(event))
    this.el.addEventListener("drop", (event) => this.onDrop(event))
    this.el.addEventListener("dragend", () => this.clear())
    this.el.addEventListener("keydown", (event) => this.onKey(event))
    this.meters()
    this.describe()
  },

  updated() {
    this.meters()
    this.describe()
    const card = this.focusId && document.activeElement === document.body ? document.getElementById(this.focusId) : null
    card?.focus()
    this.focusId = null
  },

  describe() {
    this.el.querySelectorAll("[data-kanban-card]").forEach((card) => card.setAttribute("aria-describedby", this.el.dataset.hintId))
  },

  columns() {
    return [...this.el.querySelectorAll("[data-column]")]
  },

  cardsOf(column) {
    return [...column.querySelectorAll("[data-kanban-card]")]
  },

  full(column, card) {
    return isFull({
      count: this.cardsOf(column).length,
      wip: parseWip(column.dataset.wip),
      sameColumn: column === card.closest("[data-column]"),
    })
  },

  // -- dragging

  onDragStart(event) {
    const card = event.target.closest("[data-kanban-card]")
    if (!card) return
    this.dragged = card
    card.dataset.dragging = ""
    event.dataTransfer.effectAllowed = "move"
    event.dataTransfer.setData("text/plain", card.id)
  },

  onDragOver(event) {
    const cards = event.target.closest("[data-cards]")
    if (!this.dragged || !cards) return
    const refused = this.full(cards.closest("[data-column]"), this.dragged)
    event.dataTransfer.dropEffect = refused ? "none" : "move"
    if (refused) return
    event.preventDefault()
    this.showSlot(cards, this.indexAt(cards, event.clientY))
  },

  onDrop(event) {
    const cards = event.target.closest("[data-cards]")
    if (!this.dragged || !cards) return
    event.preventDefault()
    const refused = this.full(cards.closest("[data-column]"), this.dragged)
    const slot = this.el.querySelector("[data-drop-slot]")
    refused || this.place(this.dragged, cards, slot?.nextElementSibling ?? null)
    this.clear()
  },

  others(cards) {
    return [...cards.querySelectorAll("[data-kanban-card]")].filter((card) => card !== this.dragged)
  },

  indexAt(cards, y) {
    return insertionIndex(
      this.others(cards).map((card) => card.getBoundingClientRect()),
      y,
    )
  },

  showSlot(cards, index) {
    const slot =
      this.el.querySelector("[data-drop-slot]") ??
      this.el.querySelector("template[data-drop]").content.firstElementChild.cloneNode(true)
    cards.insertBefore(slot, this.others(cards)[index] ?? null)
  },

  clear() {
    this.el.querySelectorAll("[data-drop-slot]").forEach((slot) => slot.remove())
    this.dragged && delete this.dragged.dataset.dragging
    this.dragged = null
  },

  // -- the keyboard

  onKey(event) {
    const card = event.target.closest("[data-kanban-card]")
    if (!card) return
    const column = card.closest("[data-column]")
    const columns = this.columns()
    const siblings = this.cardsOf(column)

    const toColumn = (delta) => () => {
      const target = columns[columns.indexOf(column) + delta]
      if (!target) return false
      if (this.full(target, card)) return this.say(this.el.dataset.fullLabel)
      this.place(card, target.querySelector("[data-cards]"), null)
      card.focus()
    }
    const withinColumn = (delta) => () => {
      const at = siblings.indexOf(card) + delta
      if (at < 0 || at >= siblings.length) return false
      const neighbour = siblings[at]
      this.place(card, column.querySelector("[data-cards]"), delta > 0 ? neighbour.nextElementSibling : neighbour)
      card.focus()
    }

    runKey(
      {
        "Alt+ArrowRight": toColumn(1),
        "Alt+ArrowLeft": toColumn(-1),
        "Alt+ArrowDown": withinColumn(1),
        "Alt+ArrowUp": withinColumn(-1),
      },
      event,
    )
  },

  // -- moving, counting, telling

  place(card, cards, before) {
    const from = card.closest("[data-column]").dataset.column
    const hadFocus = card === document.activeElement
    const origin = {parent: card.parentElement, next: card.nextElementSibling}
    cards.insertBefore(card, before)
    const column = cards.closest("[data-column]")
    const index = this.cardsOf(column).indexOf(card)

    this.meters()
    this.focusId = hadFocus ? card.id : null
    this.el.querySelector("[data-live]").textContent = this.el.dataset.movedLabel.replace("__COLUMN__", column.dataset.title)
    this.pushEventTo(this.el, this.el.dataset.event, {card: card.dataset.cardId, from, to: column.dataset.column, index}, (reply) =>
      reply?.rejected && this.restore(card, origin),
    )
  },

  restore(card, {parent, next}) {
    parent.insertBefore(card, next)
    this.meters()
  },

  say(text) {
    this.el.querySelector("[data-live]").textContent = text
    return false
  },

  meters() {
    this.columns().forEach((column) => {
      const count = this.cardsOf(column).length
      const wip = parseWip(column.dataset.wip)
      column.querySelector("[data-count]").textContent = count
      column.querySelector("[data-meter]").toggleAttribute("data-full", Number.isInteger(wip) && count >= wip)
    })
  },
}
