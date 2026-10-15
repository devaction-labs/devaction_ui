import {activeId} from "./toc_logic.js"

export default {
  mounted() {
    this.onScroll = () => this.mark()
    window.addEventListener("scroll", this.onScroll, {passive: true})
    this.mark()
  },
  updated() {
    this.mark()
  },
  destroyed() {
    window.removeEventListener("scroll", this.onScroll)
  },
  mark() {
    const links = [...this.el.querySelectorAll("a[href^='#']")]
    const tops = links.flatMap((link) => {
      const target = document.getElementById(link.getAttribute("href").slice(1))
      return target ? [{id: target.id, top: target.getBoundingClientRect().top}] : []
    })
    const current = activeId(tops)
    links.forEach((link) =>
      link.getAttribute("href") === `#${current}`
        ? link.setAttribute("aria-current", "location")
        : link.removeAttribute("aria-current"),
    )
  },
}
