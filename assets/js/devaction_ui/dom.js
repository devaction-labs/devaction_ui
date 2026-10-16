/**
 * Tells the form that a field changed the way the browser does when a person edits it: the event bubbles, so
 * a `phx-change` on the form hears it.
 *
 * @param {EventTarget} field
 * @param {"input" | "change"} [type]
 */
export const notify = (field, type = "input") => field.dispatchEvent(new Event(type, {bubbles: true}))
