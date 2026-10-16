const KEYS = {ArrowRight: 1, ArrowLeft: -1}

export const nextIndex = (count, current, key) =>
  key === "Home"
    ? 0
    : key === "End"
      ? count - 1
      : key in KEYS
        ? (current + KEYS[key] + count) % count
        : null

export const tabStates = (ids, active) =>
  ids.map((id) => ({id, selected: id === active, tabindex: id === active ? "0" : "-1"}))
