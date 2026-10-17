# Changelog

Every release lists new components, improvements, fixes and breaking changes. While the version is 0.x a minor release may break compatibility, and every break is listed with the step to follow.

## 0.6.2

### Improved

- The Select page of the docs site has a "With search" example: the native select has no search, so it shows the `Listbox` with `searchable`, the field at the top of the panel. The package is unchanged since 0.6.0.

## 0.6.1

### Fixed

- The changelog of the docs site no longer shows the `next` rows of earlier releases beside the real versions. The package is unchanged since 0.6.0.

## 0.6.0

### New

- `DevactionUI.Listbox`: a select with a panel of the kit's own, for what the native select cannot do. Options are `%{value, label}` maps with an optional `description`, `keywords` (found by the search, not shown) and `disabled`, or `{label, options}` groups; `option_marker` draws an icon or an avatar before each. `searchable` adds a search at the top of the panel with an `empty` text; `create` and `on_create` add a row that sends the text typed to the LiveView; `multiple` keeps the panel open and sends a list (`name[]`), with `count_text` on the button and `indicator` `:check` or `:checkbox`; `prefix`, `clear_label`, `size`, `position`, `align` and `panel_class`. Keyboard as the ARIA pattern, with letters jumping to an option when there is no search. Hook `DevactionUI.Listbox`.

### Changed

- `Select` opens a styled panel on a fine pointer (mouse, trackpad) instead of the browser's popup: a card under the select with the groups as headers, 34px rows, the chosen option tinted with a check, a disabled option muted, and the up arrow and focus ring on the select while it is open. The native `<select>` stays the field (name, value, validation, `phx-change`); the `DevactionUI.Select` hook draws the panel from its options, with ↑ ↓ Home End, type-ahead, Enter or Space to choose, Esc, Tab and a press outside to close, and it opens above when there is no room below and is not clipped by an `overflow` ancestor. On a touch screen the system picker still opens, and `multiple` stays the native list box. The `:sm` and `:lg` sizes shape the panel too.

### Fixed

- `Select` follows the artboards: the arrow is 15px and sits on the 14px padding, the multiple list box has the 5px frame, 2px between 32px rows and the checked rows in the line tone with medium weight, and a disabled option inside the list no longer draws the dashed, muted frame of a disabled select.

## 0.5.0

### New

- `DevactionUI.Select`: the browser's own `<select>` in the frame of the input group, for a short list that needs no search. Options are `{label, value}` tuples, strings, `%{value, label, disabled}` maps or `{group, options}` groups (`<optgroup>`), with a `prompt`, `multiple` (a name ending in `[]`), the sizes `:sm`, `:md` and `:lg`, and `icon` and `chevron_icon` slots.
- `field={@form[:name]}` on the form components, as the core components take it: `InputGroup`, `Textarea`, `Field`, `Choice` (`checkbox`, `radio`, `choice_card`, `checkbox_group`, `radio_group`), `Switch` (`switch`, `switch_row`, `switch_card`), `DatePicker` (`date_picker` in the single mode, `date_input`), `Combobox` and `Select`. The field gives the id, the name, the value and the errors; what is passed by hand wins. Errors show once the input was used (`used_input?`), and `config :devaction_ui, :translate_error` points at the app's translator (`DevactionUI.FormField`).
  - A boolean `checkbox` with a `field` sends `unchecked_value` (`"false"`) when it is not ticked, through a hidden input; `multiple` makes it one box of a list field (`name[]`, id `<field>-<value>`), and `checkbox_group` with a `field` sends an empty list when none is ticked.
  - A radio or a choice card with a `field` takes the id `<field>-<value>` and is checked when its value is the field's.

### Changed

- `id` (and `name` where it was required: `radio`, `choice_card`, `date_input`, `combobox`) is no longer a required attribute of these components: one of `id` or `field` must be given, and a missing one raises an `ArgumentError` that says so when the component renders.

## 0.4.0

### New

- E-mail components, for the transactional and product messages of an app, built as tables with inline styles (no Tailwind, no CSS variables, no flex or grid) with the hex values of the canvas kept in one module and a dark mode through `prefers-color-scheme`:
  - `DevactionUI.Email`: `document/1` (doctype, `color-scheme` metas and the one `<style>`: 600px column, mobile padding, dark rules on the `em-*` classes), `styles/1`, `layout/1` (preheader, brand, card, footer slots and signature), `heading/1`, `paragraph/1`, `emphasis/1`, `caption/1`, `button/1`, `button_row/1`, `link_fallback/1`, `divider/1`, `byline/1`, `footer_link/1` and `to_html/1`.
  - `DevactionUI.EmailTag`: `tag/1` in the tones `:risk`, `:warn`, `:ok`, `:info` and `:neutral`, `tag_row/1` and `chip/1`.
  - `DevactionUI.EmailCallout`: `callout/1` and `highlight/1`.
  - `DevactionUI.EmailTable`: `details/1`, `finding_list/1`, `code_list/1`, `event_list/1`, `steps/1` and `stats/1`.
  - Every text is a required attribute or a slot: the components draw no words of their own.
- The documentation site has an "Email" category and an "Email" template group with eleven e-mails (magic link, confirm account, update e-mail, reset password, password changed, new device, review ready, contract expiring, amendment for signature, weekly digest, workspace invite) with a light and a dark preview.

## 0.3.3

Found by the audit of the 0.3.x components against the artboards (issues 74 to 80).

### Improved

- `Shell` `variant="centered"` follows the LayoutTemas artboard: it keeps the panel frame and, with a `sidebar`, draws it as a bar on top like `topbar`.
- `Tabs` `:line` selects with weight 500 and the `counts: :chip` count is the 20px mono chip of the artboard; `Pagination` cells have the 1px border of the artboard.
- `Breadcrumb` with `max` closes the collapsed list on Esc (focus goes back to its summary) and on a press outside; it takes an optional `id`.
- `Shell` below 1024px keeps focus inside the open drawer (Tab and Shift+Tab wrap) and gives it back to the opener when it closes.
- Light theme: `--muted-chrome` keeps the text of the shell and the sidebar at 4.5:1 on the frame, the Composer placeholder and file size are readable, and the attachment preview is allowed by the site CSP (`blob:`).

### Fixed

- The build of a host app no longer needs the `@tiptap/*` packages unless an editor is rendered: `editor_tiptap.js` loads them with `import()` and a `.catch`, so esbuild only warns, and a mounted editor without them names the missing package.
- `Shell`: below 1024px the closed drawer is out of the tab order (`visibility: hidden`) and the open one makes the page behind `inert`; in the rail the name of an item shows on keyboard focus too, and beside the item instead of over its icon.
- `Tabs`: a horizontal list scrolls on its own instead of widening the page on a narrow screen, its tabs do not wrap or shrink, and an unselected tab turns ink on hover. Tabs nested in a panel no longer answer the keys and clicks of the tabs around them.
- `Pagination`: the previous and next controls stay on the first and last page as dimmed, `aria-disabled` spans, so the row does not change width; `size={:sm}` draws the 30px cells of a table footer.
- `Composer`: a file button drawn as a `label` opens the chooser with Enter and Space, and the field says `aria-invalid` over its limit and points at the counter with `aria-describedby`.
- `DataTable`: the scrolling box is a named, focusable region (a keyboard can scroll a wide table), and the buttons of the bulk bar keep their light text on the dark bar whatever their own variant.
- `RowMenu`: the menu is the compact one of the artboard (190px, 5px of padding, 34px items; `Dropdown compact`), and a `danger` item hovers in the risk tone.
- Dark theme: `--muted-2` is lighter (#8A8AA0) so placeholders, diff line numbers and muted labels reach 4.5:1; the `:risk` count of `Badge` and the play button of `Timer` use the dark text of the finding tones; `CodeBlock` comments and punctuation are lighter; the action button of a `ProgressToast` `:bar` is drawn in the inverted colours of its card; the field marks of `PdfViewer` read at 4.5:1.

## 0.3.2

### Improved

- `DataTable` variations that add up: `variant={:minimal}` (no border, a transparent head in sentence case, for tables inside cards), `striped`, an `expanded` slot (a chevron with `aria-expanded` opens a detail row; the browser toggles it and a redraw keeps it), `group_by` with a `group` slot, a `tfoot` slot for totals, `stack` with `primary` columns (each row becomes a card under 640px, the cell captions come from the column label), an `action` slot for the `⋯` cell with no box, `sticky_actions`, and `align` and `mono` on a column. Shift+click on a row checkbox ticks the range. `action_label` and `expand_label` are required with their slots.
- `Pagination`: `total`, `per_page`, `noun` and `summary_label` (`__FROM__`, `__TO__`, `__TOTAL__`, `__NOUN__`) draw the range of the page before the links.
- The "App" template (Projects) is the new artboard: owner with avatar, hours with a bar, `updated` as relative time, a light head and the row menu in the `action` slot; the table fits the panel without a sideways scroll.
- The README states one rule for `@source` and the keyframes, explains `pdfjs-dist` and `worker_src`, lists the requirements and the fonts, and has a row for every component.

## 0.3.1

0.3.0 shipped a stylesheet with a block left open, which stops Tailwind in the host app: use 0.3.1.

### Fixed

- The stylesheet closes every block (a test now counts the braces).
- On the documentation site, an open drawer, modal or palette in an example card stays over the page rail.

### New

- The "App" template (Projects): a full app page with the shell, the page header with tabs, the toolbar and a table with pinned columns, progress cells and a row menu.

### Improved

- `Composer`: `suggest_event` with a `suggestions` slot for `/` commands and `@` mentions, `edit_last_event` for ↑ with an empty field, the mode picker as `Dropdown variant={:chip}`, file chips with `kind` and `detail`.
- `Shell`: `sidebar_search/1` and `sidebar_user/1`.
- `Tabs`: an `icon` slot, `counts={:chip}` and `size={:sm}`.
- `Breadcrumb`: `underline={false}`. `PageHeader`: `size={:md}`. `Avatar`: `initials` and the `:ink` tone.

## 0.3.0

### New components

- `DevactionUI.Shell`: the frame of an app with a sidebar that collapses to a rail (⌘B, the `dui_sidebar` cookie, a drawer on small screens), `sidebar_head/1`, `sidebar_nav/1`, `sidebar_group/1`, `sidebar_item/1`, `sidebar_foot/1`, the variants `classic`, `topbar`, `split`, `centered` and `docs`, and the `DevactionUI.Shell.SidebarCookie` plug with `DevactionUI.Shell.on_mount/4`.
- `DevactionUI.ScrollArea`: a thin scrollbar and a shadow only at the edges that still have content.
- `DevactionUI.Composer`: the message field of the AI chat, comments and notes (grows with the text, Enter sends, a stop button while it runs, pasted and dropped files), with `Composer.button/1` and `Composer.file/1`.
- `DevactionUI.RowMenu`: the "..." menu of a table row, fixed to the window so no `overflow` cuts it.

### Improved

- `DataTable`: `sticky={:start}` and `sticky={:end}` on a `:col` pin the first column and the actions.
- `Breadcrumb`: `home`, `home_label` and a `home_icon` slot; `underline={false}` for the quiet trail of a shell header.
- `PageHeader`: `toolbar` and `toolbar_end` slots; `size={:md}` for the title of a page inside an app shell.
- `Shell`: `sidebar_search/1` and `sidebar_user/1`.
- `Tabs`: an `icon` slot, `counts={:chip}`, `size={:sm}`, and a tab without content.
- `Avatar`: `initials` and the `:ink` tone.
- `Dropdown` takes `fixed`: the menu opens with `position: fixed` from the rectangle of its button.

## 0.2.6

### Improved

- The site shows the full version (v0.2.6) in the header chips and the component history, and the dedication in the footer is in English with a soft glow that passes between the letters. The package itself is unchanged since 0.2.3.

## 0.2.5

### Improved

- The install instructions (README, home, installation page and the changelog) use the Hex requirement `{:devaction_ui, "~> 0.2.0"}` instead of the GitHub repository. The package itself is unchanged since 0.2.3.

## 0.2.4

### Fixed

- The documentation's example cards no longer cut off a floating panel (combobox, dropdown, popover, date picker) that opens inside them.

### Improved

- The site's changelog lists every release of the series with what it fixed or broke, and the site footer carries the dedication.

## 0.2.3

### Breaking changes

- `toast_group`: rebuilt to the new design: toasts are pushed from the server with `put_toast`/`update_toast`/`dismiss_toast` instead of `:toast` slots; `label` and `dismiss_label` are required.

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
