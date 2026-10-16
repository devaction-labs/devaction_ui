/**
 * The LiveView hooks of DevactionUI, by the name each component gives in `phx-hook`. Merge them into the
 * `hooks` of the LiveSocket:
 *
 *     import {hooks as devactionUI} from "./devaction_ui"
 *     new LiveSocket("/live", Socket, {hooks: {...devactionUI}})
 *
 * The logic that needs no DOM sits in `*_logic.js`, `clock.js`, `dates.js`, `keys.js`, `numbers.js`, `placement.js` and
 * `text.js`, with a test beside it (`npm test`, which is Node's own runner and installs nothing).
 */
import Autocomplete from "./autocomplete.js"
import Breadcrumb from "./breadcrumb.js"
import Calendar from "./calendar.js"
import ColorPicker from "./color_picker.js"
import CodeCopy from "./code_copy.js"
import Combobox from "./combobox.js"
import Composer from "./composer.js"
import ContextMenu from "./context_menu.js"
import Dropdown from "./dropdown.js"
import Editor from "./editor.js"
import Dropzone from "./dropzone.js"
import MoneyMask from "./money_mask.js"
import DataTable from "./data_table.js"
import DateInput from "./date_input.js"
import DatePicker from "./date_picker.js"
import FileTree from "./file_tree.js"
import DateRange from "./date_range.js"
import FilterMenu from "./filter_menu.js"
import HoverCard from "./hover_card.js"
import {Indeterminate, NumberInput, Range, RangePair, Segmented, Switch} from "./controls.js"
import Kanban from "./kanban.js"
import Overlay from "./overlay.js"
import PdfViewer from "./pdf_viewer.js"
import {CookieConsent, NotificationCenter} from "./panels.js"
import OtpInput from "./otp_input.js"
import Pillbox from "./pillbox.js"
import Popover from "./popover.js"
import ProgressToast from "./progress_toast.js"
import Resizable from "./resizable.js"
import ScrollArea from "./scroll_area.js"
import Shell from "./shell.js"
import Signature from "./signature.js"
import Sortable from "./sortable.js"
import Tabs from "./tabs.js"
import TimeField from "./time_field.js"
import Timer from "./timer.js"
import ToastGroup from "./toast_group.js"
import Tooltip from "./tooltip.js"

export const hooks = {
  "DevactionUI.Autocomplete": Autocomplete,
  "DevactionUI.Breadcrumb": Breadcrumb,
  "DevactionUI.Calendar": Calendar,
  "DevactionUI.ColorPicker": ColorPicker,
  "DevactionUI.CodeCopy": CodeCopy,
  "DevactionUI.Combobox": Combobox,
  "DevactionUI.Composer": Composer,
  "DevactionUI.CopyField": CodeCopy,
  "DevactionUI.CookieConsent": CookieConsent,
  "DevactionUI.ContextMenu": ContextMenu,
  "DevactionUI.DataTable": DataTable,
  "DevactionUI.DateInput": DateInput,
  "DevactionUI.DatePicker": DatePicker,
  "DevactionUI.DateRange": DateRange,
  "DevactionUI.Dropdown": Dropdown,
  "DevactionUI.Dropzone": Dropzone,
  "DevactionUI.Editor": Editor,
  "DevactionUI.MoneyMask": MoneyMask,
  "DevactionUI.NotificationCenter": NotificationCenter,
  "DevactionUI.NumberInput": NumberInput,
  "DevactionUI.FileTree": FileTree,
  "DevactionUI.FilterMenu": FilterMenu,
  "DevactionUI.HoverCard": HoverCard,
  "DevactionUI.Indeterminate": Indeterminate,
  "DevactionUI.Kanban": Kanban,
  "DevactionUI.Overlay": Overlay,
  "DevactionUI.PdfViewer": PdfViewer,
  "DevactionUI.OtpInput": OtpInput,
  "DevactionUI.Pillbox": Pillbox,
  "DevactionUI.Popover": Popover,
  "DevactionUI.Range": Range,
  "DevactionUI.RangePair": RangePair,
  "DevactionUI.Resizable": Resizable,
  "DevactionUI.ProgressToast": ProgressToast,
  "DevactionUI.ScrollArea": ScrollArea,
  "DevactionUI.Shell": Shell,
  "DevactionUI.Signature": Signature,
  "DevactionUI.Segmented": Segmented,
  "DevactionUI.SortableList": Sortable,
  "DevactionUI.Switch": Switch,
  "DevactionUI.Tabs": Tabs,
  "DevactionUI.TimeField": TimeField,
  "DevactionUI.Timer": Timer,
  "DevactionUI.ToastGroup": ToastGroup,
  "DevactionUI.Tooltip": Tooltip,
}
