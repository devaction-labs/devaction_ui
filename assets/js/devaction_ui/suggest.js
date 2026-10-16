import {nextIndex, rowParts} from "./editor_logic.js"

const cell = ({text, className}) => {
  const span = document.createElement("span")
  span.className = className
  span.textContent = text
  return span
}

/**
 * The popup of a suggestion (the "/" menu and the @mentions): a `role="listbox"` of `role="option"` rows near
 * the caret. It takes the TipTap suggestion props, keeps the highlighted row, and answers the keys the
 * menu owns (arrows, Home, End, Enter, Tab, Escape) so the editor leaves them alone while it is open.
 * A row is the `icon` (a glyph), the `label` and the `hint` of its item.
 */
export function popup(id) {
  let box = null
  let items = []
  let index = 0
  let command = null
  let field = null

  const announce = (open) => {
    field?.setAttribute("aria-expanded", String(open))
    open && items.length > 0
      ? field?.setAttribute("aria-activedescendant", `${id}-option-${index}`)
      : field?.removeAttribute("aria-activedescendant")
  }

  const draw = () => {
    box.replaceChildren(
      ...items.map((item, at) => {
        const option = document.createElement("div")
        option.setAttribute("role", "option")
        option.id = `${id}-option-${at}`
        option.setAttribute("aria-selected", String(at === index))
        option.className = "cmdk-item"
        option.replaceChildren(...rowParts(item).map(cell))
        option.addEventListener("mousedown", (event) => {
          event.preventDefault()
          command(item)
        })
        return option
      })
    )
    box.hidden = items.length === 0
    announce(!box.hidden)
  }

  const place = (props) => {
    const rect = props.clientRect?.()
    if (!rect) return
    box.style.left = `${rect.left + window.scrollX}px`
    box.style.top = `${rect.bottom + window.scrollY + 4}px`
  }

  const update = (props) => {
    items = props.items
    command = (item) => props.command(item)
    index = Math.min(index, Math.max(items.length - 1, 0))
    draw()
    place(props)
  }

  return {
    onStart(props) {
      box = document.createElement("div")
      box.id = id
      box.setAttribute("role", "listbox")
      field = props.editor.view.dom
      field.setAttribute("aria-controls", id)
      box.className = "absolute z-[2000] w-[270px] overflow-hidden rounded-xl border border-line bg-card p-1 shadow-pop"
      document.body.appendChild(box)
      index = 0
      update(props)
    },
    onUpdate: update,
    onKeyDown({event}) {
      const pick = {Enter: true, Tab: true}[event.key]
      if (pick && items[index]) {
        command(items[index])
        return true
      }
      if (event.key === "Escape") {
        box.hidden = true
        announce(false)
        return true
      }
      const next = nextIndex(index, event.key, items.length)
      if (next === null) return false
      index = next
      draw()
      return true
    },
    onExit() {
      field?.removeAttribute("aria-controls")
      field?.removeAttribute("aria-activedescendant")
      field?.setAttribute("aria-expanded", "false")
      box?.remove()
      box = null
    },
  }
}
