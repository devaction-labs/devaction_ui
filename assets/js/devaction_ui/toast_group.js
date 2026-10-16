import {
  CLOSE_DELAY_MS, durationFor, focusAfter, GAP_PX, isForGroup, isHotkey, leftAfter, listHeight, MAX_TOASTS, PEEK_PX, roleFor,
  stackPlan, swipeOutcome, timerStep, variantOf,
} from "./toast_logic.js"
import {runKey} from "./keys.js"

const NUMBER = (value, fallback) => (Number.isFinite(Number(value)) && value !== "" && value != null ? Number(value) : fallback)

/**
 * Toasts pushed from the server (`put_toast`, `update_toast`, `dismiss_toast`, `clear_toasts`) or from the page
 * (`window` event `dui:toast`) that pile up without covering the screen. Closed, only the front one shows and up to
 * two peek behind it, smaller and without text; with the pointer over it, or the focus inside, the pile opens
 * into a list with a gap the pointer can cross. The timers pause while it is open and while the tab is hidden,
 * and go on from where they stopped. Alt+T moves the focus to the pile, Escape closes the focused toast, a drag
 * sideways dismisses, and a `loading` toast stays until `update_toast` turns it into another variant. The list
 * is owned by this hook (`phx-update="ignore"`); the icons are cloned from the `<template data-icon>` elements
 * the component renders.
 */
export default {
  mounted() {
    this.list = this.el.querySelector("[data-toasts]")
    this.toasts = []
    this.seen = new Set()
    this.expanded = false
    this.hidden = document.hidden
    this.seq = 0

    const on = (target, name, handler) => {
      target.addEventListener(name, handler)
      return () => target.removeEventListener(name, handler)
    }
    this.off = [
      on(this.el, "pointerenter", () => this.hover(true)),
      on(this.el, "pointerleave", () => this.hover(false)),
      on(this.el, "focusin", () => this.hover(true)),
      on(this.el, "focusout", (event) => this.onFocusOut(event)),
      on(document, "visibilitychange", () => ((this.hidden = document.hidden), this.syncTimers())),
      on(document, "keydown", (event) => this.onHotkey(event)),
      on(window, "dui:toast", (event) => this.push(event.detail ?? {})),
    ]
    this.resizer = typeof ResizeObserver === "undefined" ? null : new ResizeObserver(() => this.layout())

    const mine = (handler) => (payload) => isForGroup(payload, this.el.id) && handler(payload)
    this.handleEvent("toast", mine(({group, ...toast}) => this.push(toast)))
    this.handleEvent("toast:update", mine(({id, group, ...patch}) => this.update(id, patch)))
    this.handleEvent("toast:dismiss", mine(({id}) => this.dismiss(id)))
    this.handleEvent("toast:clear", mine(() => this.clear()))
    this.flash()
  },

  updated() {
    this.flash()
    this.layout()
  },

  destroyed() {
    this.off?.forEach((undo) => undo())
    this.toasts?.forEach((toast) => clearTimeout(toast.timer))
    clearTimeout(this.closing)
    this.resizer?.disconnect()
  },

  settings() {
    return {
      visible: NUMBER(this.el.dataset.visible, 3),
      duration: NUMBER(this.el.dataset.duration, 4000),
    }
  },

  flash() {
    const initial = JSON.parse(this.el.dataset.initial || "[]")
    initial
      .filter((toast) => !this.seen.has(`${toast.id}:${toast.title}`))
      .forEach((toast) => (this.seen.add(`${toast.id}:${toast.title}`), this.push(toast)))
  },

  find(id) {
    return this.toasts.find((toast) => toast.id === String(id))
  },

  push(input = {}) {
    const known = input.id != null && this.find(input.id)
    const added = () => {
      const {duration} = this.settings()
      const variant = variantOf(input.variant)
      const toast = {
        id: input.id != null ? String(input.id) : `toast-${++this.seq}`,
        title: input.title ?? "",
        description: input.description ?? "",
        variant,
        action: input.action ?? null,
        duration: durationFor({variant, duration: input.duration, fallback: duration}),
        remaining: 0,
        startedAt: 0,
        timer: null,
      }
      toast.remaining = toast.duration
      toast.el = this.render(toast)
      this.list.prepend(toast.el)
      this.toasts.unshift(toast)
      this.resizer?.observe(toast.el.querySelector("[data-row]"))
      this.toasts.slice(MAX_TOASTS).forEach((old) => this.remove(old, true))
      requestAnimationFrame(() => requestAnimationFrame(() => ((toast.el.dataset.mounted = "true"), this.layout())))
      this.layout()
      this.syncTimers()
      return toast.id
    }
    return known ? this.update(input.id, input) : added()
  },

  update(id, patch = {}) {
    const toast = this.find(id)
    const apply = () => {
      const variant = patch.variant === undefined ? toast.variant : variantOf(patch.variant)
      const restart = patch.duration !== undefined || patch.variant !== undefined
      Object.assign(toast, {
        title: patch.title ?? toast.title,
        description: patch.description ?? toast.description,
        variant,
        action: patch.action === undefined ? toast.action : patch.action,
      })
      restart &&
        (clearTimeout(toast.timer),
        (toast.timer = null),
        (toast.duration = durationFor({variant, duration: patch.duration, fallback: this.settings().duration})),
        (toast.remaining = toast.duration))
      this.fill(toast)
      this.layout()
      this.syncTimers()
      return toast.id
    }
    return toast ? apply() : null
  },

  dismiss(id) {
    const toast = this.find(id)
    toast && this.remove(toast)
  },

  clear() {
    ;[...this.toasts].forEach((toast) => this.remove(toast))
  },

  template(name) {
    return this.el.querySelector(`template[data-icon="${name}"]`)
  },

  icon(name) {
    return this.template(name)?.content.cloneNode(true) ?? document.createDocumentFragment()
  },

  render(toast) {
    const li = document.createElement("li")
    li.className = "toast-item"
    li.tabIndex = 0
    li.dataset.id = toast.id
    li.dataset.mounted = "false"
    li.innerHTML = `<div class="toast-card"><div class="toast-row" data-row>
      <span class="toast-icon" data-icon-slot aria-hidden="true"></span>
      <div class="toast-body"><p class="toast-title" data-title></p><p class="toast-desc" data-desc></p></div>
      <button type="button" class="toast-action" data-action hidden></button>
      <button type="button" class="toast-close" data-dismiss aria-label=""></button>
    </div></div>`
    const close = li.querySelector("[data-dismiss]")
    close.setAttribute("aria-label", this.el.dataset.dismissLabel ?? "")
    close.append(this.icon("close"))
    close.addEventListener("click", () => this.remove(toast))
    li.querySelector("[data-action]").addEventListener("click", () => this.act(toast))
    li.addEventListener("keydown", (event) => runKey({Escape: () => (event.stopPropagation(), this.remove(toast))}, event))
    this.swipe(li, toast)
    this.fill(toast, li)
    return li
  },

  fill(toast, li = toast.el) {
    li.dataset.variant = toast.variant
    li.setAttribute("role", roleFor(toast.variant))
    const slot = li.querySelector("[data-icon-slot]")
    slot.replaceChildren(this.icon(toast.variant))
    slot.hidden = slot.childElementCount === 0
    li.querySelector("[data-title]").textContent = toast.title
    const description = li.querySelector("[data-desc]")
    description.textContent = toast.description
    description.hidden = !toast.description
    const action = li.querySelector("[data-action]")
    action.hidden = !toast.action
    action.textContent = toast.action?.label ?? ""
  },

  act(toast) {
    const {event, value} = toast.action ?? {}
    event && this.pushEventTo(this.el, event, value ?? {})
    toast.action?.dismiss !== false && this.remove(toast)
  },

  remove(toast, instant = false) {
    const index = this.toasts.indexOf(toast)
    const leave = () => {
      clearTimeout(toast.timer)
      this.toasts.splice(index, 1)
      const li = toast.el
      const hadFocus = li.contains(document.activeElement)
      this.resizer?.unobserve(li.querySelector("[data-row]"))
      instant ? li.remove() : this.fade(li)
      hadFocus && (this.toasts[focusAfter(this.toasts.length, index)]?.el ?? this.el).focus()
      this.layout()
      this.syncTimers()
      this.toasts.length === 0 && this.setExpanded(false)
    }
    index >= 0 && leave()
  },

  fade(li) {
    li.dataset.removed = "true"
    li.inert = true
    li.addEventListener("transitionend", () => li.remove(), {once: true})
    setTimeout(() => li.remove(), 450)
  },

  hover(inside) {
    clearTimeout(this.closing)
    inside
      ? this.setExpanded(true)
      : (this.closing = setTimeout(() => this.el.contains(document.activeElement) || this.setExpanded(false), CLOSE_DELAY_MS))
  },

  onFocusOut(event) {
    const stays = this.el.contains(event.relatedTarget) || this.el.matches(":hover")
    stays || this.hover(false)
  },

  onHotkey(event) {
    const mine = this.el.dataset.hotkey !== "false" && isHotkey(event) && !event.defaultPrevented && this.toasts.length > 0
    mine && (event.preventDefault(), this.toasts[0].el.focus())
  },

  setExpanded(open) {
    const next = open && this.toasts.length > 0
    const changed = this.expanded !== next
    this.expanded = next
    this.el.toggleAttribute("data-expanded", next)
    changed && (this.layout(), this.syncTimers())
  },

  layout() {
    const {visible} = this.settings()
    const heights = this.toasts.map((toast) => this.measure(toast.el))
    const pile = stackPlan(heights, {visible})
    this.toasts.forEach((toast, index) => {
      const item = pile.items[index]
      const style = toast.el.style
      style.setProperty("--i", index)
      style.setProperty("--front-h", `${pile.front}px`)
      style.setProperty("--own-h", `${item.height}px`)
      style.setProperty("--offset", `${item.offset}px`)
      style.setProperty("--peek", `${PEEK_PX}px`)
      style.zIndex = String(this.toasts.length - index)
      toast.el.toggleAttribute("data-front", item.front)
      toast.el.toggleAttribute("data-behind", !item.front)
      toast.el.toggleAttribute("data-overflow", item.overflow)
    })
    this.list.style.height = `${listHeight(pile, this.expanded)}px`
  },

  measure(li) {
    const row = li.querySelector("[data-row]")
    const style = getComputedStyle(li.querySelector(".toast-card"))
    const chrome = ["paddingTop", "paddingBottom", "borderTopWidth", "borderBottomWidth"].reduce(
      (sum, key) => sum + (Number.parseFloat(style[key]) || 0),
      0,
    )
    return Math.ceil(row.offsetHeight + chrome)
  },

  syncTimers() {
    const paused = this.expanded || this.hidden
    const steps = {
      pause: (toast) => (clearTimeout(toast.timer), (toast.timer = null), (toast.remaining = leftAfter(toast.remaining, toast.startedAt, Date.now()))),
      start: (toast) => ((toast.startedAt = Date.now()), (toast.timer = setTimeout(() => this.remove(toast), Math.max(0, toast.remaining)))),
      keep: () => false,
    }
    this.toasts.forEach((toast) =>
      steps[timerStep({paused, running: toast.timer !== null, finite: Number.isFinite(toast.duration)})](toast),
    )
  },

  swipe(li, toast) {
    let origin = null
    let dx = 0
    const finish = () => {
      const moved = origin !== null
      origin = null
      delete li.dataset.swiping
      const steps = {
        dismiss: () => ((li.dataset.swipeOut = "true"), li.style.setProperty("--swipe", `${Math.sign(dx) * (li.offsetWidth + 40)}px`), this.remove(toast)),
        restore: () => li.style.setProperty("--swipe", "0px"),
      }
      moved && steps[swipeOutcome(Math.abs(dx))]()
    }
    li.addEventListener("pointerdown", (event) => {
      const ignore = event.button !== 0 || event.target.closest("button")
      ignore || ((origin = event.clientX), (dx = 0), li.setPointerCapture(event.pointerId), (li.dataset.swiping = "true"))
    })
    li.addEventListener("pointermove", (event) => {
      origin === null || ((dx = event.clientX - origin), li.style.setProperty("--swipe", `${dx}px`))
    })
    li.addEventListener("pointerup", finish)
    li.addEventListener("pointercancel", finish)
  },
}
