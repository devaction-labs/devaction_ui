export function percent(value, min, max) {
  const span = Number(max) - Number(min)
  return span <= 0 ? 0 : ((Number(value) - Number(min)) / span) * 100
}
