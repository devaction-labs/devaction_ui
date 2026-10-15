import "phoenix_html"
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import {hooks as devactionUI} from "../../../assets/js/devaction_ui"
import SiteFit from "./site_fit.js"
import SiteToc from "./site_toc.js"

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken, tz_offset: new Date().getTimezoneOffset()},
  hooks: {...devactionUI, SiteFit, SiteToc},
})

liveSocket.connect()
window.liveSocket = liveSocket

window.addEventListener("phx:page-loading-stop", () => {
  location.hash === "" && window.scrollTo(0, 0)
})

window.addEventListener("keydown", (event) => {
  const wantsSearch = (event.metaKey || event.ctrlKey) && event.key.toLowerCase() === "k"
  wantsSearch && (event.preventDefault(), document.getElementById("site-search")?.focus())
})

document.addEventListener("click", (event) => {
  const button = event.target.closest("[data-copy-text]")
  button &&
    navigator.clipboard.writeText(button.dataset.copyText).then(() => {
      button.dataset.copied = ""
      setTimeout(() => delete button.dataset.copied, 1600)
    })
})
