/**
 * The hooks of the panels that sit on a page without taking it over: `NotificationCenter` and `CookieConsent`.
 * The server owns their state; the hooks only move the focus and turn a key into the click the server already
 * listens to.
 */
import {nextTab, runKey} from "./keys.js"

const ZONES = {
  "[data-notification]": {orientation: "vertical", keys: ["ArrowUp", "ArrowDown", "Home", "End"]},
  '[role="tab"]': {orientation: "horizontal", keys: ["ArrowLeft", "ArrowRight", "Home", "End"]},
}

/**
 * The index of the item the focus goes to from `current` on `key` in a vertical list of notifications or a
 * horizontal list of tabs, or `null` for a key the list does not use.
 */
export const stepTo = (key, current, count, orientation) => nextTab(key, current, count, {orientation})

/** The zone (`selector` and what it takes) a target is in, or `undefined`. */
export const zoneOf = (target) => Object.entries(ZONES).find(([selector]) => target.closest?.(selector))

/** Moves between the notifications with the vertical arrows and between the tabs with the horizontal ones. */
export const NotificationCenter = {
  mounted() {
    this.onKey = (event) => this.key(event)
    this.el.addEventListener("keydown", this.onKey)
  },

  destroyed() {
    this.el.removeEventListener("keydown", this.onKey)
  },

  key(event) {
    const zone = zoneOf(event.target)
    zone && this.move(event, ...zone)
  },

  move(event, selector, {orientation, keys}) {
    const items = [...this.el.querySelectorAll(selector)]
    const current = items.indexOf(event.target.closest(selector))
    const go = (key) => () => this.focusAt(items, stepTo(key, current, items.length, orientation))

    runKey(Object.fromEntries(keys.map((key) => [key, go(key)])), event)
  },

  focusAt(items, index) {
    const target = items[index]
    target?.focus()
    return target !== undefined
  },
}

/**
 * Where the focus goes when the list of categories opens or closes: to the first switch you can change when it
 * opens from the preferences button, back to the button when it closes with the focus lost, else nowhere.
 *
 * @param {{was: boolean, now: boolean, triggerFocused: boolean, lost: boolean}} state
 * @returns {"first" | "trigger" | null}
 */
export const focusAfter = ({was, now, triggerFocused, lost}) =>
  [
    [!was && now && triggerFocused, "first"],
    [was && !now && lost, "trigger"],
  ].find(([hit]) => hit)?.[1] ?? null

/** Esc closes the categories only, through the preferences button; focus follows the list opening and closing. */
export const CookieConsent = {
  mounted() {
    this.open = this.el.dataset.open === "true"
    this.onKey = (event) => runKey({Escape: () => this.closeCategories()}, event)
    this.el.addEventListener("keydown", this.onKey)
  },

  updated() {
    const now = this.el.dataset.open === "true"
    const active = document.activeElement
    const place = focusAfter({
      was: this.open,
      now,
      triggerFocused: active === this.toggle(),
      lost: active === null || active === document.body,
    })

    this.open = now
    this.focusPlace(place)
  },

  destroyed() {
    this.el.removeEventListener("keydown", this.onKey)
  },

  toggle() {
    return this.el.querySelector("[data-prefs-toggle]")
  },

  closeCategories() {
    const open = this.el.dataset.open === "true"
    open && this.toggle().click()
    return open
  },

  focusPlace(place) {
    const places = {
      first: () => this.el.querySelector('[role="switch"]:not([aria-disabled="true"])'),
      trigger: () => this.toggle(),
    }

    places[place]?.()?.focus()
  },
}
