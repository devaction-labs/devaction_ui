import test from "node:test"
import assert from "node:assert/strict"
import Kanban from "./kanban.js"

const camel = (name) => name.replace(/^data-/, "").replace(/-(\w)/g, (_m, letter) => letter.toUpperCase())

const parseSelector = (selector) => {
  const [, tag, attr] = selector.trim().match(/^([a-z]+)?(?:\[([\w-]+)\])?$/)
  return {tag, attr}
}

class Node {
  constructor(tag, attrs = {}, children = []) {
    this.tag = tag
    this.attrs = {...attrs}
    this.dataset = {}
    Object.entries(this.attrs).forEach(([name, value]) => name.startsWith("data-") && (this.dataset[camel(name)] = value))
    this.children = []
    this.parentElement = null
    this.style = {}
    this.classes = new Set()
    this.classList = {add: (...names) => names.forEach((name) => this.classes.add(name))}
    this.textContent = ""
    this.rect = {left: 0, top: 0, width: 100, height: 40, right: 100, bottom: 40}
    this.template = null
    children.forEach((child) => this.append(child))
  }

  get content() {
    return {firstElementChild: this.template}
  }

  get nextElementSibling() {
    const siblings = this.parentElement?.children ?? []
    return siblings[siblings.indexOf(this) + 1] ?? null
  }

  append(child) {
    child.remove()
    child.parentElement = this
    this.children.push(child)
  }

  insertBefore(child, reference) {
    child.remove()
    child.parentElement = this
    const at = reference ? this.children.indexOf(reference) : -1
    at < 0 ? this.children.push(child) : this.children.splice(at, 0, child)
  }

  remove() {
    const siblings = this.parentElement?.children
    siblings?.splice(siblings.indexOf(this), 1)
    this.parentElement = null
  }

  matches(selector) {
    return selector.split(",").some((part) => {
      const {tag, attr} = parseSelector(part)
      return (!tag || tag === this.tag) && (!attr || attr in this.attrs)
    })
  }

  closest(selector) {
    return this.matches(selector) ? this : (this.parentElement?.closest(selector) ?? null)
  }

  contains(node) {
    return node === this || this.children.some((child) => child.contains(node))
  }

  all(selector) {
    return this.children.flatMap((child) => [...(child.matches(selector) ? [child] : []), ...child.all(selector)])
  }

  querySelectorAll(selector) {
    return this.all(selector)
  }

  querySelector(selector) {
    return this.all(selector)[0] ?? null
  }

  cloneNode() {
    const copy = new Node(this.tag, this.attrs)
    copy.rect = this.rect
    copy.template = this.template
    return copy
  }

  removeAttribute(name) {
    delete this.attrs[name]
  }

  setAttribute(name, value) {
    this.attrs[name] = value
  }

  toggleAttribute(name, force) {
    force ? (this.attrs[name] = "") : delete this.attrs[name]
  }

  getBoundingClientRect() {
    return this.rect
  }

  focus() {
    document.activeElement = this
  }

  scrollBy(dx, dy) {
    this.scrolled = [...(this.scrolled ?? []), [dx, dy]]
  }
}

const column = (id, title, wip, cards = []) => {
  const list = new Node("div", {"data-cards": ""}, cards)
  const meter = new Node("span", {"data-meter": ""}, [new Node("span", {"data-count": ""})])
  const header = new Node("header", {}, [meter])
  const section = new Node("section", {"data-column": id, "data-title": title, ...(wip ? {"data-wip": String(wip)} : {})}, [header, list])
  section.dataset.column = id
  section.dataset.title = title
  wip && (section.dataset.wip = String(wip))
  return section
}

const card = (id) => {
  const node = new Node("div", {"data-kanban-card": "", id, tabindex: "0"})
  node.id = id
  node.dataset.cardId = id
  return node
}

const setup = () => {
  const a = card("a")
  const b = card("b")
  const c = card("c")
  const todo = column("todo", "To do", null, [a, b])
  const doing = column("doing", "Doing", 1, [c])
  const done = column("done", "Done", null)
  const slotTemplate = new Node("template", {"data-drop": ""})
  slotTemplate.template = new Node("div", {"data-drop-slot": ""})
  const live = new Node("p", {"data-live": ""})
  const board = new Node("div", {}, [todo, doing, done, live, slotTemplate])
  board.dataset = {
    event: "move_card",
    movedLabel: "Moved to __COLUMN__",
    fullLabel: "Limit reached",
    hintId: "hint",
  }

  const listeners = {}
  const document = {
    activeElement: null,
    body: new Node("body"),
    listeners: {},
    addEventListener: (type, fn) => (document.listeners[type] = fn),
    removeEventListener: (type) => delete document.listeners[type],
    getElementById: () => null,
    elementFromPoint: () => document.hovered,
    hovered: null,
  }
  const timers = []
  const frames = []
  Object.assign(globalThis, {
    document,
    window: {innerWidth: 1000, innerHeight: 800, scrollBy: (dx, dy) => (document.windowScrolled = [dx, dy])},
    setTimeout: (fn) => timers.push(fn) && timers.length,
    clearTimeout: () => {},
    requestAnimationFrame: (fn) => frames.push(fn),
    cancelAnimationFrame: () => {},
  })

  const pushed = []
  const hook = {...Kanban, el: board, pushEventTo: (_t, event, payload, reply) => pushed.push({event, payload, reply})}
  board.addEventListener = (type, fn) => (listeners[type] = fn)
  hook.mounted()
  return {hook, board, a, b, c, todo, doing, done, live, document, listeners, pushed, timers, frames}
}

const press = (target, extra = {}) => ({
  target,
  isPrimary: true,
  button: 0,
  pointerId: 1,
  pointerType: "mouse",
  clientX: 10,
  clientY: 10,
  ...extra,
})

const at = (x, y, extra = {}) => ({pointerId: 1, clientX: x, clientY: y, ...extra})

test("a mouse drag moves the card to the column under the pointer and tells the server once", () => {
  const {a, doing, done, board, document, listeners, pushed} = setup()
  const target = done.querySelector("[data-cards]")

  listeners.pointerdown(press(a))
  document.hovered = target
  document.listeners.pointermove(at(300, 100))

  assert.equal(a.dataset.dragging, "")
  assert.equal(document.body.children.length, 1)
  assert.ok(document.body.children[0].classes.has("shadow-pop"))
  assert.equal(board.querySelector("[data-drop-slot]").parentElement, target)

  document.listeners.pointerup(at(300, 100))

  assert.equal(a.parentElement, target)
  assert.equal(a.dataset.dragging, undefined)
  assert.equal(document.body.children.length, 0)
  assert.equal(board.querySelector("[data-drop-slot]"), null)
  assert.deepEqual(pushed.map((entry) => entry.payload), [{card: "a", from: "todo", to: "done", index: 0}])
  assert.equal(doing.querySelector("[data-count]").textContent, 1)
  assert.equal(done.querySelector("[data-count]").textContent, 1)
  assert.deepEqual(Object.keys(document.listeners), [])
})

test("a drop within the column lands where the slot was", () => {
  const {a, b, c, todo, document, listeners, pushed} = setup()
  const cards = todo.querySelector("[data-cards]")
  b.rect = {left: 0, top: 0, width: 100, height: 40, right: 100, bottom: 40}

  listeners.pointerdown(press(a))
  document.hovered = cards
  document.listeners.pointermove(at(20, 90))
  document.listeners.pointerup(at(20, 90))

  assert.deepEqual(cards.children.map((node) => node.id), ["b", "a"])
  assert.equal(pushed[0].payload.index, 1)
  assert.equal(c.closest("[data-column]").dataset.column, "doing")
})

test("the card drops as the pointer is over a column, not only over its list", () => {
  const {a, done, document, listeners, pushed} = setup()

  listeners.pointerdown(press(a))
  document.hovered = done
  document.listeners.pointermove(at(300, 100))
  document.listeners.pointerup(at(300, 100))

  assert.equal(pushed.length, 1)
  assert.equal(a.closest("[data-column]"), done)
})

test("a press that does not move is a click: nothing is dragged and nothing is sent", () => {
  const {a, document, listeners, pushed} = setup()

  listeners.pointerdown(press(a))
  document.listeners.pointermove(at(12, 11))
  document.listeners.pointerup(at(12, 11))

  assert.equal(a.dataset.dragging, undefined)
  assert.equal(pushed.length, 0)
  assert.equal(document.body.children.length, 0)
})

test("a drag that ends is not followed by the click it would cause", () => {
  const {a, done, document, listeners, timers} = setup()
  const clicks = []
  const event = () => ({stopPropagation: () => clicks.push("stopped"), preventDefault: () => clicks.push("prevented")})

  listeners.pointerdown(press(a))
  document.hovered = done
  document.listeners.pointermove(at(300, 100))
  document.listeners.pointerup(at(300, 100))
  listeners.click(event())
  assert.deepEqual(clicks, ["stopped", "prevented"])

  timers.at(-1)()
  listeners.click(event())
  assert.equal(clicks.length, 2)
})

test("Esc gives the drag up and the card stays where it was", () => {
  const {a, todo, done, document, listeners, pushed} = setup()

  listeners.pointerdown(press(a))
  document.hovered = done
  document.listeners.pointermove(at(300, 100))
  document.listeners.keydown({key: "Escape", altKey: false, metaKey: false, ctrlKey: false, preventDefault: () => {}})

  assert.equal(a.closest("[data-column]"), todo)
  assert.equal(pushed.length, 0)
  assert.equal(a.dataset.dragging, undefined)
  assert.equal(document.body.children.length, 0)
})

test("a column that is full takes no card from outside: no slot, and a drop sends nothing", () => {
  const {a, doing, board, document, listeners, pushed} = setup()

  listeners.pointerdown(press(a))
  document.hovered = doing.querySelector("[data-cards]")
  document.listeners.pointermove(at(300, 100))
  assert.equal(board.querySelector("[data-drop-slot]"), null)

  document.listeners.pointerup(at(300, 100))
  assert.equal(pushed.length, 0)
  assert.equal(a.closest("[data-column]").dataset.column, "todo")
})

test("a refused move puts the card back", () => {
  const {a, todo, done, document, listeners, pushed} = setup()

  listeners.pointerdown(press(a))
  document.hovered = done
  document.listeners.pointermove(at(300, 100))
  document.listeners.pointerup(at(300, 100))
  assert.equal(a.closest("[data-column]"), done)

  pushed[0].reply({rejected: true})
  assert.equal(a.closest("[data-column]"), todo)
  assert.equal(todo.querySelector("[data-cards]").children[0], a)
})

test("a finger that moves before it has held is scrolling, and one that holds can drag", () => {
  const {a, done, document, listeners, timers, pushed} = setup()

  listeners.pointerdown(press(a, {pointerType: "touch"}))
  assert.equal(timers.length, 1)
  document.listeners.pointermove(at(10, 60))
  assert.deepEqual(Object.keys(document.listeners), [])
  assert.equal(a.dataset.dragging, undefined)

  listeners.pointerdown(press(a, {pointerType: "touch"}))
  timers.at(-1)()
  assert.equal(a.dataset.dragging, "")
  document.hovered = done
  document.listeners.pointermove(at(300, 100))
  document.listeners.pointerup(at(300, 100))
  assert.equal(pushed.length, 1)
  assert.equal(a.closest("[data-column]"), done)
})

test("the page keeps a touch move that is not a drag, and loses the one that is", () => {
  const {a, listeners, timers} = setup()
  const move = () => ({
    cancelable: true,
    prevented: false,
    preventDefault() {
      this.prevented = true
    },
  })

  const idle = move()
  listeners.touchmove(idle)
  assert.equal(idle.prevented, false)

  listeners.pointerdown(press(a, {pointerType: "touch"}))
  timers.at(-1)()
  const during = move()
  listeners.touchmove(during)
  assert.equal(during.prevented, true)
})

test("controls inside a card do not start a drag, and neither does a second pointer or a right button", () => {
  const {a, listeners, document} = setup()
  const button = new Node("button")
  a.append(button)

  listeners.pointerdown(press(button))
  assert.deepEqual(Object.keys(document.listeners), [])

  listeners.pointerdown(press(a, {button: 2}))
  assert.deepEqual(Object.keys(document.listeners), [])

  listeners.pointerdown(press(a, {isPrimary: false}))
  assert.deepEqual(Object.keys(document.listeners), [])
})

test("near the edge of the board it scrolls by itself while the card is in hand", () => {
  const {a, board, document, listeners, frames} = setup()
  board.rect = {left: 0, top: 0, right: 1000, bottom: 600, width: 1000, height: 600}

  listeners.pointerdown(press(a))
  document.hovered = null
  document.listeners.pointermove(at(990, 400))
  assert.equal(frames.length, 1)

  frames.at(-1)()
  assert.ok(board.scrolled[0][0] > 0)
  assert.equal(document.windowScrolled[0], 0)
  assert.equal(frames.length, 2)
})

test("in the middle of the board it does not scroll", () => {
  const {a, board, document, listeners, frames} = setup()
  board.rect = {left: 0, top: 0, right: 1000, bottom: 600, width: 1000, height: 600}

  listeners.pointerdown(press(a))
  document.listeners.pointermove(at(500, 400))
  frames.at(-1)()

  assert.equal(board.scrolled, undefined)
})

test("the keyboard still moves the card and says where", () => {
  const {a, b, doing, todo, live, listeners, pushed} = setup()
  const key = (name, target) => ({key: name, altKey: true, metaKey: false, ctrlKey: false, target, preventDefault: () => {}})

  listeners.keydown(key("ArrowRight", a))
  assert.equal(a.closest("[data-column]"), todo)
  assert.equal(live.textContent, "Limit reached")
  assert.equal(pushed.length, 0)

  listeners.keydown(key("ArrowUp", b))
  assert.equal(todo.querySelector("[data-cards]").children[0], b)
  assert.equal(pushed.at(-1).payload.index, 0)
  assert.equal(doing.querySelector("[data-count]").textContent, 1)
})
