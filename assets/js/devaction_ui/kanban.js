import {runKey} from "./keys.js"
import {HOLD, edgeDelta, ghostOffset, insertionIndex, isFull, moveIntent, parseWip} from "./kanban_logic.js"

const INTERACTIVE = "a, button, input, select, textarea, summary, [contenteditable], [data-no-drag]"
const GHOST = ["pointer-events-none", "fixed", "z-50", "rotate-2", "opacity-95", "shadow-pop", "motion-reduce:rotate-0"]

/**
 * A board of columns with cards that move. Drag a card with a mouse, a pen or a finger to another column or
 * another place in its own, or focus it and press Alt + arrow keys (←→ between columns, ↑↓ within one). The
 * card moves in the page at once and the LiveView, which stays the source of truth, gets one event with
 * `{card, from, to, index}`. A column with a limit that is full takes no more cards from outside, and every
 * move is announced in a live region, and every card is described by the keyboard hint of the board
 * (`data-hint-id`). After the server redraws, the focus goes back to the moved card.
 *
 * Dragging uses pointer events, so it is the same for every kind of pointer: a mouse or a pen starts after a few
 * pixels of movement, a finger after holding still for a moment (moving first is a scroll, which the page keeps).
 * The card in hand is a floating copy under the pointer; the original stays dimmed where it was, and the target
 * column shows a "drop here" slot. Near the edges of the board (and of the window) it scrolls by itself; Esc
 * gives the drag up. Buttons, links and fields inside a card do not start a drag.
 */
export default {
  mounted() {
    this.el.addEventListener("pointerdown", (event) => this.onPress(event))
    this.el.addEventListener("keydown", (event) => this.onKey(event))
    this.el.addEventListener("dragstart", (event) => event.target.closest?.("[data-kanban-card]") && event.preventDefault())
    this.el.addEventListener("selectstart", (event) => this.press && event.preventDefault())
    this.el.addEventListener("click", (event) => this.swallowClick(event), true)
    this.el.addEventListener("touchmove", (event) => this.dragged && event.cancelable && event.preventDefault(), {passive: false})
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

  destroyed() {
    this.release(false)
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

  onPress(event) {
    const card = event.target.closest("[data-kanban-card]")
    if (!card || this.press || !event.isPrimary || event.button > 0 || event.target.closest(INTERACTIVE)) return

    const box = card.getBoundingClientRect()
    const hold = HOLD[event.pointerType] ?? HOLD.touch
    this.press = {
      card,
      id: event.pointerId,
      type: event.pointerType,
      origin: {x: event.clientX, y: event.clientY},
      grab: {x: event.clientX - box.left, y: event.clientY - box.top},
      size: {width: box.width, height: box.height},
      timer: hold === null ? null : setTimeout(() => this.begin(), hold),
    }
    this.pointer = this.press.origin

    this.listeners = {
      pointermove: (move) => this.onMove(move),
      pointerup: (up) => up.pointerId === this.press?.id && this.release(true),
      pointercancel: (cancel) => cancel.pointerId === this.press?.id && this.release(false),
      keydown: (key) => runKey({Escape: () => this.press && this.release(false)}, key),
    }
    Object.entries(this.listeners).forEach(([type, handler]) => document.addEventListener(type, handler))
  },

  onMove(event) {
    if (event.pointerId !== this.press?.id) return
    this.pointer = {x: event.clientX, y: event.clientY}
    const distance = Math.hypot(this.pointer.x - this.press.origin.x, this.pointer.y - this.press.origin.y)

    const intents = {
      start: () => this.begin(),
      cancel: () => this.release(false),
      wait: () => {},
    }
    this.dragged ? this.track() : intents[moveIntent(this.press.type, distance)]()
  },

  begin() {
    if (!this.press || this.dragged) return
    clearTimeout(this.press.timer)
    this.dragged = this.press.card
    this.dragged.dataset.dragging = ""
    this.ghost = this.makeGhost(this.dragged)
    document.body.append(this.ghost)
    this.track()
    this.frame = requestAnimationFrame(() => this.tick())
  },

  makeGhost(card) {
    const ghost = card.cloneNode(true)
    ghost.removeAttribute("id")
    ghost.removeAttribute("tabindex")
    ghost.removeAttribute("data-kanban-card")
    ghost.removeAttribute("data-dragging")
    ghost.setAttribute("aria-hidden", "true")
    ghost.classList.add(...GHOST)
    Object.assign(ghost.style, {left: "0", top: "0", width: `${this.press.size.width}px`, height: `${this.press.size.height}px`})
    return ghost
  },

  track() {
    const {x, y} = ghostOffset(this.pointer, this.press.grab)
    this.ghost.style.transform = `translate3d(${x}px, ${y}px, 0)`

    const column = this.hit(this.pointer)?.closest("[data-column]")
    const cards = column && this.el.contains(column) && !this.full(column, this.dragged) ? column.querySelector("[data-cards]") : null
    this.target = cards
    cards ? this.showSlot(cards, this.indexAt(cards, this.pointer.y)) : this.hideSlot()
  },

  hit({x, y}) {
    return document.elementFromPoint(x, y)
  },

  tick() {
    if (!this.dragged) return
    const board = this.el.getBoundingClientRect()
    const dx = edgeDelta(this.pointer.x, {start: Math.max(board.left, 0), end: Math.min(board.right, window.innerWidth)})
    const dy = edgeDelta(this.pointer.y, {start: 0, end: window.innerHeight})

    const scrolling = dx !== 0 || dy !== 0
    scrolling && this.scroll(dx, dy)
    this.frame = requestAnimationFrame(() => this.tick())
  },

  scroll(dx, dy) {
    this.el.scrollBy(dx, 0)
    window.scrollBy(0, dy)
    this.track()
  },

  release(commit) {
    const press = this.press
    if (!press) return

    clearTimeout(press.timer)
    Object.entries(this.listeners ?? {}).forEach(([type, handler]) => document.removeEventListener(type, handler))
    const dragging = this.dragged === press.card
    const slot = this.el.querySelector("[data-drop-slot]")

    dragging && commit && this.target && this.place(press.card, this.target, slot?.nextElementSibling ?? null)
    dragging && this.swallowNextClick()
    this.clear()
  },

  swallowNextClick() {
    this.swallow = true
    setTimeout(() => (this.swallow = false), 0)
  },

  swallowClick(event) {
    this.swallow && (event.stopPropagation(), event.preventDefault())
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

  hideSlot() {
    this.el.querySelectorAll("[data-drop-slot]").forEach((slot) => slot.remove())
  },

  clear() {
    this.hideSlot()
    cancelAnimationFrame(this.frame)
    this.ghost?.remove()
    this.dragged && delete this.dragged.dataset.dragging
    this.ghost = null
    this.dragged = null
    this.target = null
    this.press = null
    this.listeners = null
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
