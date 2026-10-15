export const clamp = (value, min, max) => Math.min(max, Math.max(min, value))

const channel = (h, s, v, n) => {
  const k = (n + h / 60) % 6
  return v - v * s * Math.max(0, Math.min(k, 4 - k, 1))
}

const hex2 = (value) => Math.round(value).toString(16).padStart(2, "0").toUpperCase()

/** `#RRGGBB` for a colour given as hue (0-360), saturation and value (0-1). */
export const hsvToHex = (h, s, v) => "#" + [5, 3, 1].map((n) => hex2(channel(h, s, v, n) * 255)).join("")

const sector = (r, g, b, max, delta) =>
  [
    [r, ((g - b) / delta) % 6],
    [g, (b - r) / delta + 2],
    [b, (r - g) / delta + 4],
  ].find(([value]) => value === max)[1]

/** `{h, s, v, a}` (alpha 0-100) for `#RRGGBB` or `#RRGGBBAA`, or `null` when it is not a colour. */
export function hexToHsv(hex) {
  const match = /^#?([0-9a-f]{6})([0-9a-f]{2})?$/i.exec(String(hex).trim())
  if (!match) return null
  const n = parseInt(match[1], 16)
  const [r, g, b] = [(n >> 16) & 255, (n >> 8) & 255, n & 255].map((x) => x / 255)
  const max = Math.max(r, g, b)
  const delta = max - Math.min(r, g, b)
  const h = delta === 0 ? 0 : (sector(r, g, b, max, delta) * 60 + 360) % 360
  const a = match[2] ? Math.round((parseInt(match[2], 16) / 255) * 100) : 100
  return {h, s: max === 0 ? 0 : delta / max, v: max, a}
}

/** `hex` with its alpha (0-100) appended as two digits; unchanged when opaque. */
export const withAlpha = (hex, alpha) => (alpha >= 100 ? hex : hex + hex2((alpha / 100) * 255))

/** Fills `%{name}` placeholders of a template the server wrote, so the words stay the server's. */
export const fill = (template, values) =>
  template.replace(/%\{(\w+)\}/g, (_match, name) => String(values[name] ?? ""))
