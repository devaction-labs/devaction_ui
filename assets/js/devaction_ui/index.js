/**
 * The LiveView hooks of DevactionUI, by the name each component gives in `phx-hook`. Merge them into the
 * `hooks` of the LiveSocket:
 *
 *     import {hooks as devactionUI} from "./devaction_ui"
 *     new LiveSocket("/live", Socket, {hooks: {...devactionUI}})
 *
 * The logic that needs no DOM sits in `*_logic.js`, `dates.js`, `keys.js` and `text.js`, with a test beside
 * it (`npm test`, which is Node's own runner and installs nothing).
 */
import Autocomplete from "./autocomplete.js"
import Calendar from "./calendar.js"
import ColorPicker from "./color_picker.js"
import Combobox from "./combobox.js"
import Dropdown from "./dropdown.js"
import Editor from "./editor.js"
import Dropzone from "./dropzone.js"
import MoneyMask from "./money_mask.js"
import DataTable from "./data_table.js"
import DatePicker from "./date_picker.js"
import FilterMenu from "./filter_menu.js"
import Kanban from "./kanban.js"
import Pillbox from "./pillbox.js"
import Popover from "./popover.js"
import ProgressToast from "./progress_toast.js"
import Range from "./range.js"
import Signature from "./signature.js"
import Tabs from "./tabs.js"
import Timer from "./timer.js"
import ToastGroup from "./toast_group.js"
import Tooltip from "./tooltip.js"

export const hooks = {
  "DevactionUI.Autocomplete": Autocomplete,
  "DevactionUI.Calendar": Calendar,
  "DevactionUI.ColorPicker": ColorPicker,
  "DevactionUI.Combobox": Combobox,
  "DevactionUI.DataTable": DataTable,
  "DevactionUI.DatePicker": DatePicker,
  "DevactionUI.Dropdown": Dropdown,
  "DevactionUI.Dropzone": Dropzone,
  "DevactionUI.Editor": Editor,
  "DevactionUI.MoneyMask": MoneyMask,
  "DevactionUI.FilterMenu": FilterMenu,
  "DevactionUI.Kanban": Kanban,
  "DevactionUI.Pillbox": Pillbox,
  "DevactionUI.Popover": Popover,
  "DevactionUI.Range": Range,
  "DevactionUI.ProgressToast": ProgressToast,
  "DevactionUI.Signature": Signature,
  "DevactionUI.Tabs": Tabs,
  "DevactionUI.Timer": Timer,
  "DevactionUI.ToastGroup": ToastGroup,
  "DevactionUI.Tooltip": Tooltip,
}
