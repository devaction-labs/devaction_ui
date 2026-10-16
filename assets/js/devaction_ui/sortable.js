import {insertionIndex} from "./kanban_logic.js"
import {runKey} from "./keys.js"
import {atEnds, heldMove, moveBy, placeAt, sameOrder, say, targetIndex} from "./sortable_logic.js"

const ROW = "[data-sortable-row]"
const DRAG_FROM = 4

/**
 * A list whose rows are put in order by the person: drag a row by its handle (a mouse, a pen or a finger),
 * press the up and down buttons of a row, or focus the handle and press Space to pick the row up, ↑ ↓ (Home, End)
 * to move it, Space or Enter to drop it and Esc to put it back. The row moves in the page at once and the LiveView, which
 * keeps the real order, gets one event with `{order, id, from, to}` (`order` is every id in the new order) when the move
 * ends; a drop that changes nothing sends nothing. Every step is said in a live region with the texts of the page
 * (`__ITEM__`, `__POS__`, `__TOTAL__`), and the up and down buttons at the ends are off. A pointer drag
 * reorders the rows under the pointer as it passes their middles; Esc gives it up.
 */
export default {
  mounted() {
    this.list = this.el.querySelector("[data-sortable-list]")
    this.live = this.el.querySelector("[data-live]")

    this.el.addEventListener("pointerdown", (event) => this.onPress(event))
    this.el.addEventListener("keydown", (event) => event.target.closest("[data-handle]") && this.onHandleKey(event))
    this.el.addEventListener("click", (event) => this.onMoveButton(event))
    this.el.addEventListener("selectstart", (event) => this.press && event.preventDefault())
    this.refresh()
  },

  updated() {
    this.refresh()
  },

  destroyed() {
    this.release(false)
  },

  rows() {
    return [...this.list.querySelectorAll(`:scope > ${ROW}`)]
  },

  ids() {
    return this.rows().map((row) => row.dataset.id)
  },

  row(id) {
    return this.rows().find((row) => row.dataset.id === id)
  },

  arrange(order) {
    order.forEach((id) => this.list.append(this.row(id)))
    this.refresh()
  },

  refresh() {
    const count = this.rows().length
    this.rows().forEach((row, index) => {
      const off = atEnds(index, count)
      row.querySelector('[data-move="up"]')?.toggleAttribute("disabled", off.up)
      row.querySelector('[data-move="down"]')?.toggleAttribute("disabled", off.down)
    })
  },

  tell(name, id) {
    const order = this.ids()
    const row = this.row(id)
    this.live.textContent = say(this.el.dataset[name], {item: row.dataset.label, pos: order.indexOf(id) + 1, total: order.length})
  },

  commit(id, before) {
    const order = this.ids()
    sameOrder(order, before) ||
      this.pushEventTo(this.el, this.el.dataset.event, {order, id, from: before.indexOf(id), to: order.indexOf(id)})
  },

  // -- the buttons

  onMoveButton(event) {
    const button = event.target.closest("[data-move]")
    const row = button?.closest(ROW)
    if (!row || button.disabled) return

    const before = this.ids()
    const delta = {up: -1, down: 1}[button.dataset.move]
    this.arrange(moveBy(before, row.dataset.id, delta))
    const stay = row.querySelector(`[data-move="${button.dataset.move}"]:not([disabled])`)
    const next = stay ?? row.querySelector("[data-move]:not([disabled])") ?? row.querySelector("[data-handle]")
    next.focus()
    this.tell("movedLabel", row.dataset.id)
    this.commit(row.dataset.id, before)
  },

  // -- the keyboard

  onHandleKey(event) {
    const row = event.target.closest(ROW)
    const id = row.dataset.id
    const held = this.held?.id === id

    const drop = () => this.drop(row)
    const move = (key) => () => this.moveHeld(row, heldMove(key))

    const keys = held
      ? {
          " ": drop,
          Enter: drop,
          Escape: () => this.putBack(row),
          Tab: () => {
            this.drop(row)
            return false
          },
          ArrowUp: move("ArrowUp"),
          ArrowDown: move("ArrowDown"),
          Home: move("Home"),
          End: move("End"),
        }
      : {" ": () => this.pickUp(row)}

    runKey(keys, event)
  },

  pickUp(row) {
    this.held = {id: row.dataset.id, before: this.ids()}
    this.mark(row, true)
    this.tell("pickedLabel", row.dataset.id)
  },

  moveHeld(row, move) {
    const order = this.ids()
    const to = targetIndex(move, order.indexOf(row.dataset.id), order.length)
    this.arrange(placeAt(order, row.dataset.id, to))
    row.querySelector("[data-handle]").focus()
    this.tell("movedLabel", row.dataset.id)
  },

  drop(row) {
    const {id, before} = this.held
    this.held = null
    this.mark(row, false)
    this.tell("droppedLabel", id)
    this.commit(id, before)
  },

  putBack(row) {
    const {id, before} = this.held
    this.held = null
    this.arrange(before)
    this.mark(row, false)
    row.querySelector("[data-handle]").focus()
    this.tell("cancelledLabel", id)
  },

  mark(row, on) {
    row.toggleAttribute("data-dragging", on)
    row.querySelector("[data-handle]").setAttribute("aria-pressed", String(on))
  },

  // -- the pointer

  onPress(event) {
    const handle = event.target.closest("[data-handle]")
    if (!handle || this.press || !event.isPrimary || event.button > 0) return

    this.press = {row: handle.closest(ROW), id: event.pointerId, origin: {x: event.clientX, y: event.clientY}, before: this.ids()}
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
    const far = Math.hypot(event.clientX - this.press.origin.x, event.clientY - this.press.origin.y) >= DRAG_FROM
    this.dragging || (far && this.begin())
    this.dragging && this.follow(event.clientY)
  },

  begin() {
    this.dragging = true
    this.mark(this.press.row, true)
    this.tell("pickedLabel", this.press.row.dataset.id)
  },

  follow(y) {
    const {row} = this.press
    const others = this.rows().filter((other) => other !== row)
    const index = insertionIndex(
      others.map((other) => other.getBoundingClientRect()),
      y,
    )
    const order = placeAt(this.ids(), row.dataset.id, index)
    sameOrder(order, this.ids()) || (this.arrange(order), this.tell("movedLabel", row.dataset.id))
  },

  release(commit) {
    const press = this.press
    if (!press) return
    Object.entries(this.listeners ?? {}).forEach(([type, handler]) => document.removeEventListener(type, handler))
    const dragged = this.dragging

    dragged && !commit && this.arrange(press.before)
    dragged && this.mark(press.row, false)
    dragged && this.tell(commit ? "droppedLabel" : "cancelledLabel", press.row.dataset.id)
    dragged && commit && this.commit(press.row.dataset.id, press.before)
    this.press = null
    this.dragging = false
    this.listeners = null
  },
}
