const root = document.documentElement
const systemTheme = () => (matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light")

const setTheme = (theme) => {
  const isSystem = theme === "system"
  isSystem ? localStorage.removeItem("phx:theme") : localStorage.setItem("phx:theme", theme)
  root.setAttribute("data-theme", isSystem ? systemTheme() : theme)
  root.setAttribute("data-theme-source", isSystem ? "system" : "user")
}

const forced = new URLSearchParams(location.search).get("theme")

forced
  ? root.setAttribute("data-theme", forced)
  : setTheme(localStorage.getItem("phx:theme") || "system")

window.addEventListener("storage", (e) => e.key === "phx:theme" && setTheme(e.newValue || "system"))
window.addEventListener("phx:toggle-theme", () => setTheme(root.getAttribute("data-theme") === "dark" ? "light" : "dark"))
matchMedia("(prefers-color-scheme: dark)").addEventListener("change", () => {
  root.getAttribute("data-theme-source") === "system" && root.setAttribute("data-theme", systemTheme())
})
