import {handleKey, renderScale, pageSize, thumbScrollTarget, clampPage} from "./pdf_viewer_logic.js"

const TYPING = "input, textarea, select, [contenteditable]"
const THUMB_WIDTH = 80

/**
 * The PDF viewer: `phx-hook="DevactionUI.PdfViewer"` on the root, with the page and the zoom in `data-page`,
 * `data-pages` and `data-zoom`, which the server owns. The hook only asks: the keys (`+` `-` `0`, PageUp,
 * PageDown, Home, End, the arrows in the rail) go to the server as `data-page-event` and `data-zoom-event`
 * with `pushEventTo(this.el, ...)`, and the server answers with new data attributes.
 *
 * With a `data-src` the hook loads `pdfjs-dist` with `import()` (a host that never gives a source does not need
 * the package), takes the worker from `data-worker-src`, draws the current page into the canvas of
 * `[data-pdf-canvas-host]` and the thumbnails into `[data-pdf-thumb-host]`, and hides the server-rendered
 * page (`[data-pdf-fallback]`). Without a source, or when the file does not open, the server's page stays.
 */
export default {
  mounted() {
    this.token = 0
    this.keydown = (event) => this.onKey(event)
    this.el.addEventListener("keydown", this.keydown)
    this.open()
  },

  updated() {
    this.el.dataset.src === this.src ? this.redraw() : this.open()
    this.reveal()
  },

  destroyed() {
    this.el.removeEventListener("keydown", this.keydown)
    this.close()
  },

  state() {
    const data = this.el.dataset
    return {page: Number(data.page), total: Number(data.pages), zoom: Number(data.zoom)}
  },

  onKey(event) {
    event.target.closest(TYPING) ||
      handleKey(event, this.state(), (action) => this.send(action), {
        rail: event.target.closest('[role="listbox"]') !== null,
      })
  },

  send({type, value}) {
    const names = {page: this.el.dataset.pageEvent, zoom: this.el.dataset.zoomEvent}
    names[type] && this.pushEventTo(this.el, names[type], {[type]: value})
  },

  close() {
    this.token += 1
    this.task?.cancel()
    this.doc?.destroy()
    this.doc = null
  },

  async open() {
    this.close()
    this.src = this.el.dataset.src
    const token = this.token
    this.src && (await this.load(this.src, token))
  },

  async load(src, token) {
    const pdfjs = await import("pdfjs-dist").catch(() => null)
    pdfjs && (pdfjs.GlobalWorkerOptions.workerSrc = this.el.dataset.workerSrc)
    const doc = await pdfjs?.getDocument(src).promise.catch(() => null)
    const current = token === this.token && this.el.isConnected
    this.doc = current ? doc : null
    !current && doc?.destroy()
    this.doc && this.draw()
  },

  redraw() {
    const {page, zoom} = this.state()
    this.drawn !== `${page}/${zoom}` && this.draw()
  },

  async draw() {
    const doc = this.doc
    const token = this.token
    const {page, zoom} = this.state()
    this.drawn = `${page}/${zoom}`
    const host = this.el.querySelector("[data-pdf-canvas-host]")
    this.task?.cancel()
    const pdfPage = doc && host && (await doc.getPage(clampPage(page, doc.numPages)).catch(() => null))
    const current = pdfPage && token === this.token && page === this.state().page
    current && (await this.paint(pdfPage, host, zoom))
    current && this.thumbs(doc, token)
  },

  async paint(pdfPage, host, zoom) {
    const base = {width: Number(this.el.dataset.pageWidth), height: Number(this.el.dataset.pageHeight)}
    const natural = pdfPage.getViewport({scale: 1})
    const size = pageSize(base, zoom)
    const viewport = pdfPage.getViewport({
      scale: renderScale({pageWidth: base.width, naturalWidth: natural.width, zoom}),
    })
    const ratio = window.devicePixelRatio || 1
    const canvas = host.querySelector("canvas") ?? host.appendChild(document.createElement("canvas"))
    canvas.width = Math.floor(viewport.width * ratio)
    canvas.height = Math.floor(viewport.height * ratio)
    canvas.style.width = `${size.width}px`
    canvas.style.height = `${size.height}px`
    this.task = pdfPage.render({
      canvasContext: canvas.getContext("2d"),
      viewport,
      transform: ratio === 1 ? null : [ratio, 0, 0, ratio, 0, 0],
    })
    await this.task.promise.then(
      () => this.show(host),
      () => null,
    )
  },

  show(host) {
    host.hidden = false
    this.el.querySelector("[data-pdf-fallback]")?.setAttribute("hidden", "")
  },

  async thumbs(doc, token) {
    const hosts = [...this.el.querySelectorAll("[data-pdf-thumb-host]")].filter((host) => !host.firstChild)
    for (const host of hosts) {
      const live = token === this.token
      const pdfPage = live ? await doc.getPage(Number(host.dataset.pdfThumbHost)).catch(() => null) : null
      pdfPage && token === this.token && (await this.thumb(pdfPage, host))
    }
  },

  async thumb(pdfPage, host) {
    const natural = pdfPage.getViewport({scale: 1})
    const viewport = pdfPage.getViewport({scale: THUMB_WIDTH / natural.width})
    const canvas = host.appendChild(document.createElement("canvas"))
    canvas.width = Math.floor(viewport.width)
    canvas.height = Math.floor(viewport.height)
    canvas.style.cssText = "width:100%;height:100%"
    await pdfPage.render({canvasContext: canvas.getContext("2d"), viewport}).promise.catch(() => null)
  },

  reveal() {
    const rail = this.el.querySelector("[data-pdf-rail]")
    const current = rail?.querySelector('[aria-selected="true"]')
    const target =
      current &&
      thumbScrollTarget({
        top: current.offsetTop,
        height: current.offsetHeight,
        scrollTop: rail.scrollTop,
        viewHeight: rail.clientHeight,
      })
    target !== null && target !== undefined && rail.scrollTo({top: target})
    rail?.contains(document.activeElement) && current?.focus()
  },
}
