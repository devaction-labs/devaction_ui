import {matches, plan} from "./changelog_filter_logic.js"

export default {
  mounted() {
    this.filter = "all"
    this.onClick = (event) => {
      const pill = event.target.closest("[data-filter]")
      pill && this.apply(pill.dataset.filter)
    }
    this.el.addEventListener("click", this.onClick)
    this.apply(this.filter)
  },
  updated() {
    this.apply(this.filter)
  },
  destroyed() {
    this.el.removeEventListener("click", this.onClick)
  },
  apply(filter) {
    this.filter = filter
    this.el.querySelectorAll("[data-filter]").forEach((pill) => {
      pill.setAttribute("aria-pressed", String(pill.dataset.filter === filter))
    })
    this.el.querySelectorAll("[data-kind]").forEach((row) => {
      row.hidden = !matches(filter, row.dataset.kind)
    })
    const releases = [...this.el.querySelectorAll("[data-release]")]
    const groups = releases.map((release) => [...release.querySelectorAll("[data-group]")])
    const kinds = groups.map((list) =>
      list.map((group) => [...group.querySelectorAll("[data-kind]")].map((row) => row.dataset.kind)),
    )
    plan(filter, kinds).forEach((result, index) => {
      releases[index].querySelector("[data-empty]")?.toggleAttribute("hidden", !result.empty)
      result.groups.forEach((state, position) => {
        const group = groups[index][position]
        group.hidden = !state.visible
        group.querySelector("[data-count]").textContent = state.count
      })
    })
  },
}
