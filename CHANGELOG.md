# Changelog

Every release lists new components, improvements, fixes and breaking changes. While the version is 0.x a minor release may break compatibility, and every break is listed with the step to follow.

## 0.2.2

### Fixed

- `toast_group`: the pile is the toasts themselves, each a little behind and smaller than the one in front, and it opens and closes with a glide: the front toast stays where it is and the others slide to their place in the list. The group no longer forces `relative`, so `fixed bottom-4` anchors it.

## 0.2.1

### Fixed

- The documentation site serves its scripts, styles and icons under digested names, so a cache in front of it can no longer hand a page an older script, and its content security policy allows the Cloudflare analytics script.

## 0.2.0

### New

`banner`, `context_menu`, `cookie_consent`, `copy_field`, `date_range`, `description_list`, `diff_view`, `field`, `file_tree`, `filter_pill`, `hover_card`, `notification_center`, `otp_input`, `pdf_viewer`, `pricing`, `resizable`, `separator`, `sortable_list`, `time_field`.

### Improved

- `toast_group`: The notices pile up as soon as there are two, with layers peeking out above the newest; the pile opens on hover or focus.
- `data_table`: Takes a stream, with toolbar and footer slots, a density toggle, loading and error states and sort arrows through slots.
- `dropzone`: `queue/1`: a file queue with progress, errors, retry and cancel.
- `avatar`: `group/1`: overlapped avatars with status dots and a +N chip; `tone: :auto` picks a colour from the name.
- `editor`: `suggest/1`, a compact variant with the toolbar at the bottom, and TipTap loaded only when an editor mounts.
- `calendar`: The week view has an hours grid and the month and week take a legend.
- `date_picker`: A recurring due chip, and the range fields live in `date_range` and `date_input`.
- `timer`: `timer_mini/1` for the app bar and `time_log/1` for what was logged today.
- `kanban`: Cards move with touch and pen, and a move the server rejects is put back.
- `popover`: Left and right placements, edge clamping and a portal mode for scrolling containers.
- `modal`: Body scroll lock, an inert page behind and Esc for the top overlay only.
- `drawer`: A bottom sheet that closes by dragging, stacked with modals in a defined order.
- `tooltip`: Hoverable and dismissible with Esc, and it flips at the edges of the screen.
- `sidebar`: Search and user building blocks and collapsible groups.
- `code_block`: Copy button, line numbers, highlighted lines, diff lines and an Elixir lexer.
- `tone`: Indigo, emerald and chart tones, with strong text tokens.
- `spinner`: `dots/1`, a three-dot indicator.
- `tabs`: Vertical orientation, and the server can set the selected tab.
- `breadcrumb`: A collapsed middle for long paths and a separator as text or chevron.

### Breaking changes

- `confirm_dialog`: Now a thin wrapper over `Modal`: `eyebrow` is gone and the close button is optional.
- `danger_dialog`: `type_label` is a slot, so the name to type can be a `<code>` chip.
- `modal`: Modal and drawer need the `DevactionUI.Overlay` hook: load the package hooks.
- `command_palette`: The scopes are a tablist of their own and no longer use `Segmented`.
- `chart`: A line chart's second series is no longer dashed by default: pass `dashed: true`.
- `tag`: The default size is 11px with `3px 8px`; the old size is `:lg`.
- `callout`: The icon sits inline by default; `icon_layout: :box` is the old tile.
- `avatar`: The sizes follow the canvas: `:md` is 40px, `:sm` 32px and `:xs` 22px.
- `money_input`: The value no longer carries `R$`: the prefix is an add-on.
- `switch`: The thumb is a real element instead of `::after`.
- `dropdown`: The `check_icon` slot is gone: the chosen item shows a leading ring.
- `panel`: `Panel.empty/1` is removed (use `EmptyState`) and `inner_class` has no default.
- `required_texts`: New required text attrs: `nav_label` (AuthLayout), `toolbar_label` (Editor), `hint_label` (Kanban), `meter_label` (PasswordStrength), and the labels of DataTable, Kanban and Editor no longer have English defaults.

## 0.1.0

First public release: function components for Phoenix LiveView with light and dark tokens, keyboard navigation and state on the server.
