import {notify} from "./dom.js"
import {buttonText, canCreate, fill, keeps, pick, placePanel} from "./listbox_logic.js"
import {extendBuffer, isTypeahead, matchIndex} from "./menu_logic.js"
import {runKey, wrap} from "./keys.js"
import {screenSize} from "./placement.js"

/**
 * The listbox: a button that shows the choice and a panel the library draws. With a search, the field keeps
 * focus and points at the active option with `aria-activedescendant` (the combobox pattern); without one, the
 * list itself takes focus and letters jump to the option that starts with them. ↑ ↓ Home End move round the
 * options that are shown and not disabled, Enter (and Space without a search) chooses, Esc closes and returns to
 * the button, Tab leaves. A multiple listbox stays open while choosing.
 *
 * The values live in hidden inputs that are rewritten on every choice, and `input` is fired on them so the
 * form's `phx-change` hears it. The create row sends `data-create-event` with the text typed, to
 * `data-create-target` when there is one.
 */
export default {
  mounted() {
    this.trigger = this.el.querySelector("[data-trigger]")
    this.panel = this.el.querySelector("[data-panel]")
    this.list = this.el.querySelector("[data-list]")
    this.search = this.el.querySelector("[data-search]")
    this.searchClear = this.el.querySelector("[data-search-clear]")
    this.focusTarget = this.search ?? this.list
    this.typed = {buffer: "", at: 0}

    this.trigger.addEventListener("click", () => (this.panel.hidden ? this.open() : this.close()))
    this.trigger.addEventListener("keydown", (event) => runKey({ArrowDown: () => this.open(), ArrowUp: () => this.open()}, event))
    this.focusTarget.addEventListener("keydown", (event) => this.onKey(event))
    this.search?.addEventListener("input", () => this.filter())
    this.panel.addEventListener("mousedown", (event) => event.target.closest("[data-list], [data-search-clear]") && event.preventDefault())
    this.el.addEventListener("click", (event) => this.onClick(event))

    this.outside = (event) => !this.el.contains(event.target) && this.close()
    this.reflow = (event) => !this.panel.contains(event.target) && this.place()
    document.addEventListener("mousedown", this.outside)
  },

  updated() {
    this.panel.hidden || this.filter(false)
  },

  destroyed() {
    document.removeEventListener("mousedown", this.outside)
    window.removeEventListener("resize", this.reflow)
    window.removeEventListener("scroll", this.reflow, true)
  },

  isMultiple() {
    return this.el.dataset.multiple === "true"
  },

  options() {
    return [...this.el.querySelectorAll('[role="option"]:not([data-create])')]
  },

  /** The rows the keyboard moves through: shown, not disabled, the create row last when it shows. */
  rows() {
    const create = this.el.querySelector("[data-create]")
    return [...this.options(), ...(create ? [create] : [])].filter((row) => !row.hidden && row.getAttribute("aria-disabled") !== "true")
  },

  activeIndex() {
    return this.rows().findIndex((row) => row.hasAttribute("data-active"))
  },

  onClick(event) {
    const row = event.target.closest('[role="option"]')
    row && row.getAttribute("aria-disabled") !== "true" && this.choose(row)
    event.target.closest("[data-clear]") && this.clear()
    event.target.closest("[data-search-clear]") && this.clearSearch()
  },

  onKey(event) {
    const rows = this.rows()
    const move = (delta) => () => this.activate(rows[wrap(this.activeIndex(), delta, rows.length)])
    const chooseActive = () => rows[this.activeIndex()] && this.choose(rows[this.activeIndex()])

    const handled = runKey(
      {
        ArrowDown: move(1),
        ArrowUp: move(-1),
        Home: () => (this.search ? false : this.activate(rows[0])),
        End: () => (this.search ? false : this.activate(rows.at(-1))),
        Enter: chooseActive,
        " ": () => (this.search ? false : chooseActive()),
        Escape: () => {
          this.close()
          this.trigger.focus()
        },
        Tab: () => {
          this.close()
          return false
        },
      },
      event,
    )

    !handled && !this.search && isTypeahead(event) && this.typeahead(event.key)
  },

  typeahead(key) {
    const now = Date.now()
    this.typed = {buffer: extendBuffer(this.typed.buffer, key, now - this.typed.at), at: now}
    const rows = this.rows()
    const index = matchIndex(rows.map((row) => row.dataset.label ?? ""), this.activeIndex(), this.typed.buffer)
    index >= 0 && this.activate(rows[index])
  },

  open() {
    this.panel.hidden = false
    this.trigger.setAttribute("aria-expanded", "true")
    this.search && (this.search.value = "")
    this.filter(false)
    this.activate(this.rows().find((row) => row.getAttribute("aria-selected") === "true") ?? this.rows()[0])
    this.focusTarget.focus({preventScroll: true})
    window.addEventListener("resize", this.reflow)
    window.addEventListener("scroll", this.reflow, true)
  },

  close() {
    if (this.panel.hidden) return
    window.removeEventListener("resize", this.reflow)
    window.removeEventListener("scroll", this.reflow, true)
    this.panel.removeAttribute("style")
    this.panel.hidden = true
    this.trigger.setAttribute("aria-expanded", "false")
    this.focusTarget.removeAttribute("aria-activedescendant")
  },

  /** Shows the options the search keeps, the groups that still have one, the empty text and the create row. */
  filter(resetActive = true) {
    const term = this.search?.value ?? ""
    this.options().forEach((option) => (option.hidden = !keeps({label: option.dataset.label, keywords: option.dataset.keywords}, term)))
    this.el.querySelectorAll("[data-group]").forEach((group) => {
      group.hidden = !group.querySelector('[role="option"]:not([hidden])')
    })

    const shown = this.options().filter((option) => !option.hidden)
    const empty = this.el.querySelector("[data-empty]")
    empty && ((empty.hidden = shown.length > 0), (empty.textContent = fill(empty.dataset.pattern, {term: term.trim()})))

    const create = this.el.querySelector("[data-create]")
    if (create) {
      create.hidden = !canCreate(term, this.options().map((option) => option.dataset.label))
      create.querySelector("[data-create-text]").textContent = fill(create.dataset.pattern, {term: term.trim()})
    }

    this.searchClear && (this.searchClear.hidden = term === "")
    resetActive && this.activate(this.rows()[0])
    this.place()
  },

  /** Puts the panel by the button, on the side that has room, and shortens the list when neither side has enough. */
  place() {
    if (this.panel.hidden) return
    const {panel, list, trigger} = this
    panel.removeAttribute("style")
    const size = {width: panel.offsetWidth, height: panel.offsetHeight}
    const anchor = trigger.getBoundingClientRect()
    const spot = placePanel({
      anchor,
      panel: size,
      chrome: size.height - list.offsetHeight,
      screen: screenSize(),
      wanted: this.el.dataset.position,
      align: this.el.dataset.align,
    })
    const px = (value) => (value === null ? "auto" : `${value}px`)
    Object.assign(panel.style, {position: "fixed", margin: "0", right: "auto", minWidth: `${anchor.width}px`, width: `${size.width}px`, left: px(spot.left), top: px(spot.top), bottom: px(spot.bottom)})
    panel.style.setProperty("--listbox-room", `${spot.list}px`)

    const box = panel.getBoundingClientRect()
    const drift = {x: box.left - spot.left, y: (spot.side === "bottom" ? box.top : box.bottom) - spot.edge}
    panel.style.left = px(spot.left - drift.x)
    panel.style.top = px(spot.top === null ? null : spot.top - drift.y)
    panel.style.bottom = px(spot.bottom === null ? null : spot.bottom + drift.y)
  },

  clearSearch() {
    this.search.value = ""
    this.filter()
    this.search.focus({preventScroll: true})
  },

  activate(row) {
    this.rows().forEach((other) => other.removeAttribute("data-active"))
    this.el.querySelectorAll("[data-active]").forEach((other) => other.removeAttribute("data-active"))
    row?.setAttribute("data-active", "")
    row?.scrollIntoView({block: "nearest"})
    row ? this.focusTarget.setAttribute("aria-activedescendant", row.id) : this.focusTarget.removeAttribute("aria-activedescendant")
  },

  values() {
    return this.options()
      .filter((option) => option.getAttribute("aria-selected") === "true")
      .map((option) => option.dataset.value)
  },

  /** Writes `values` into the options, the hidden inputs and the button, and tells the form. */
  commit(values) {
    this.options().forEach((option) => option.setAttribute("aria-selected", String(values.includes(option.dataset.value))))

    const holder = this.el.querySelector("[data-values]")
    const sentinel = holder.querySelector("[data-sentinel]")
    const template = holder.querySelector("input:not([data-sentinel])") ?? sentinel
    const inputs = (this.isMultiple() ? values : [values[0] ?? ""]).map((value) => {
      const input = template.cloneNode()
      input.removeAttribute("data-sentinel")
      input.value = value
      return input
    })
    holder.replaceChildren(...(sentinel ? [sentinel] : []), ...inputs)
    notify(holder.lastElementChild)

    this.show(values)
  },

  show(values) {
    const chosen = this.options().filter((option) => values.includes(option.dataset.value))
    const view = buttonText({
      labels: chosen.map((option) => option.dataset.label),
      multiple: this.isMultiple(),
      placeholder: this.el.dataset.placeholder,
      countText: this.el.dataset.countText,
    })
    const current = this.el.querySelector("[data-current]")
    current.textContent = view.text
    current.classList.toggle("text-muted-2", view.muted)

    const marker = this.el.querySelector("[data-current-marker]")
    marker && (marker.innerHTML = chosen[0]?.querySelector("[data-marker]")?.innerHTML ?? "")

    const clear = this.el.querySelector("[data-clear]")
    clear && (clear.hidden = view.muted)
  },

  choose(row) {
    if (row.hasAttribute("data-create")) return this.create()

    this.commit(pick(this.values(), row.dataset.value, this.isMultiple()))
    if (this.isMultiple()) return this.activate(row)

    this.close()
    this.trigger.focus()
  },

  create() {
    const term = this.search.value.trim()
    const {createEvent, createTarget} = this.el.dataset
    const payload = {id: this.el.id, term}
    createTarget ? this.pushEventTo(/^\d+$/.test(createTarget) ? Number(createTarget) : createTarget, createEvent, payload) : this.pushEvent(createEvent, payload)
    this.close()
    this.trigger.focus()
  },

  clear() {
    this.commit([])
    this.close()
    this.trigger.focus()
  },
}
