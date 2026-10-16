export const matches = (filter, kind) => filter === "all" || filter === kind

export const plan = (filter, releases) =>
  releases.map((groups) => {
    const planned = groups.map((kinds) => {
      const count = kinds.filter((kind) => matches(filter, kind)).length
      return {count, visible: count > 0}
    })
    return {groups: planned, empty: planned.every((group) => !group.visible)}
  })
