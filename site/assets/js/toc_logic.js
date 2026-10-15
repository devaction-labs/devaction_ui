const OFFSET = 120

export function activeId(tops, offset = OFFSET) {
  const passed = tops.filter(({top}) => top <= offset)
  const current = passed.at(-1) ?? tops[0]
  return current?.id
}
