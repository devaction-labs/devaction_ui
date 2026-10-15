/** Seconds as `H:MM:SS`, the same text the server draws. */
export function format(seconds) {
  const whole = Math.max(0, Math.floor(seconds))
  const hours = Math.floor(whole / 3600)
  const minutes = Math.floor((whole % 3600) / 60)
  const pad = (number) => String(number).padStart(2, "0")
  return `${hours}:${pad(minutes)}:${pad(whole % 60)}`
}

/** The seconds counted: the base plus, while running, the time since it started (both in seconds). */
export function elapsed({base, startedAt, nowSeconds}) {
  return startedAt === null ? base : base + Math.max(0, nowSeconds - startedAt)
}

/** What the element says: its numbers (or `null` for the start of a paused timer). */
export function read(dataset) {
  const number = (text) => (text === undefined || text === "" ? null : Number(text))
  return {base: number(dataset.base) ?? 0, startedAt: number(dataset.startedAt), serverNow: number(dataset.now)}
}
