# DevactionUI

The component library of DevAction: Phoenix function components, LiveView hooks and a token stylesheet.
It depends on Phoenix and LiveView only, so every DevAction project (and any other) takes the same pieces.

## Repository layout

    devaction_ui/        the package: lib/ (components), assets/js (hooks), assets/css (tokens), test/
    devaction_ui/site/   the documentation site: a Phoenix app that depends on the package by path

The package is what goes to Hex and into every project; it needs Phoenix and LiveView only. The site is a
consumer of the package like any other, with its own `mix.exs`, release and Dockerfile, so it deploys on its
own and nothing of it ships with the package.

## Running the documentation

    cd site
    mix setup
    mix phx.server    # http://localhost:4100

`mix setup` fetches the deps, installs the npm packages the editor hook needs, and builds the CSS and JS.
Every component has a page with live examples (each with its source), and the API tables are read off the
modules themselves, so they cannot drift from the code. `⌘K` searches; the sun/moon button flips the theme.

## Deploying the documentation

The `Dockerfile` at the root builds an Alpine release of the site (the context is the whole repo, because the
site depends on the package by path):

    docker build -t devaction-ui-site .
    docker run -p 4000:4000 -e SECRET_KEY_BASE=$(mix phx.gen.secret) -e PHX_HOST=ui.example.com devaction-ui-site

`PORT`, `PHX_HOST` and `SECRET_KEY_BASE` are the only variables; `/up` answers 200 for the proxy's health check.

## Templates

Whole screens built only from the library live under `site/lib/devaction_ui_site/screens/<group>_<slug>.html.heex`
and are listed in `site/lib/devaction_ui_site/templates.ex`. Each is a page of its own at `/screens/<group>/<slug>`;
the documentation embeds it scaled down, next to its source (`/templates/<group>`). Every example and every screen
runs in a LiveView of its own, so what you type or click in one never reaches another.

## Tests

    mix test && mix js.test            # the package
    cd site && mix test                # the site

## Using it in a project

    {:devaction_ui, github: "devaction-labs/devaction_ui"}

1. CSS: `@import "../../deps/devaction_ui/assets/css/devaction_ui.css";` in the app's Tailwind entry. The
   stylesheet itself tells Tailwind to read the components and the hooks (some classes live in the JS),
   so there is no `@source` to add.
2. JS: `import {hooks as devactionUI} from "../../deps/devaction_ui/assets/js/devaction_ui"` and merge into
   the LiveSocket `hooks`.
3. Editor only: `DevactionUI.Editor` needs TipTap. Copy the `dependencies` of `deps/devaction_ui/assets/package.json`
   (the `@tiptap/*` packages, pinned to 3.32.0) into the app's `package.json` and `npm install`. The hook loads
   TipTap with a dynamic `import()` when an editor is mounted, so an app that renders none can skip this.
4. Fonts: Geist and Geist Mono are named in the tokens; the host app serves them. The minimum is the
   canvas's own link: `https://fonts.googleapis.com/css2?family=Geist:wght@400;500;600;700&family=Geist+Mono:wght@400;500&display=swap`.
   The typed name of `SignatureField` uses Caveat (weight 500), which the host app serves too.
5. Theme: the stylesheet sets `:root { color-scheme: light dark }`, so the page follows the system theme.
   To pin one, set `data-theme="light"` or `data-theme="dark"` (or the `.light` / `.dark` class) on `<html>`.

## The rules that keep it extractable

- **It knows nothing about any app.** No app module, no Gettext backend: text comes in as attributes and
  slots. `test/devaction_ui/no_hand_made_ui_test.exs` fails if a file here reaches out.
- **100% independent: no Fluxon, no daisyUI, no Heroicons.** Everything here is `Phoenix.Component` plus
  Tailwind. Icons come in as slots; the documentation site fills them with Hugeicons.
- **Classes live in the components, not in a stylesheet.** A component carries its Tailwind utilities in its
  template; `@apply` in `@layer components` is allowed for the classes the canvas names. The only CSS the
  library needs is the tokens (`:root` variables and `@theme`) and the `shimmer`, `aura-spin`, `aura-glow` and `toast-out` keyframes, in `assets/css/app.css`
  today. A host app makes Tailwind read the components with `@source "../../deps/devaction_ui/lib"`.
- **Tokens, never a hex in a template.** `bg-card`, `text-muted`, `border-tag-risk-line`. The tokens flip
  with the theme through `light-dark()`, so a component never has a `dark:` variant of its own. The theme is
  `data-theme="dark"` or the `.dark` class on `<html>`.
- **Color is never alone.** A tag has text, a callout has a title or an icon, a progress bar has a label.
- **Motion respects `prefers-reduced-motion`.**
- **Text in a `pre` is an attribute, not a slot.** A slot carries the template's line breaks and indentation
  into the code. `code_block` takes `code`.

## What is here

| Module | What it is |
| --- | --- |
| `DevactionUI.Tone` | the five tones (`risk`, `warn`, `ok`, `info`, `neutral`) as class strings, and the canvas's kinds (`note`, `ai`, `tip`, `warning`, `decision`) mapped to them |
| `DevactionUI.Tag` | the mono label; `variant`, `size: :md \| :sm`, `surface: :tinted \| :plain` |
| `DevactionUI.Callout` | a tinted block with title, icon, body and actions |
| `DevactionUI.CodeBlock` | code in mono: the dark suggestion block and the tinted "your code" / "idiomatic" ones; a `label` makes it a focusable region, `copy_label` adds a copy button; `lang: :heex` or `:elixir` colours it; `line_numbers`, `highlight_lines` and `diff` work on its lines |
| `DevactionUI.Kbd` | a key cap |
| `DevactionUI.Panel` | the canvas card (a soft wrap around a bordered panel), `eyebrow/1` and `empty/1` |
| `DevactionUI.Button` | button or link, `variant` (primary, secondary, ghost, ai, danger, info, link), `size` sm/md/lg, `loading` |
| `DevactionUI.Alert` | a short message with an icon and a title |
| `DevactionUI.Breadcrumb` | where the page is |
| `DevactionUI.Pagination` | page links with a window and gaps |
| `DevactionUI.Stat` | a number with its caption, a trend and an inverted `highlight` |
| `DevactionUI.Badge` | `count/1` bubble and `dot/1` status dot, optionally pulsing |
| `DevactionUI.Steps` | steps with connectors: done, current, pending |
| `DevactionUI.Timeline` | things that happened, in order, on a thin line |
| `DevactionUI.Tabs` | boxed or underlined tabs, switched on the client with ← → Home End |
| `DevactionUI.Accordion` | `<details>` sections, exclusive through a shared `name`, no JavaScript |
| `DevactionUI.Tooltip` | a hint on hover and focus, CSS only |
| `DevactionUI.Pillbox` | removable pills in a field; Enter or comma adds, Backspace removes; `empty_sentinel` makes an emptied list still reach the server |
| `DevactionUI.FilterPill` | the round pills of a filter bar: on or off (ink), amber, with a ×, and the dashed `add_pill/1` |
| `DevactionUI.ColorPicker` | a hex field with a panel: saturation and brightness square, hue and opacity strips, presets, the eyedropper where the browser has one |
| `DevactionUI.Slider` | a native range input and a two-thumb range slider whose thumbs never cross, with the fill and the value following the drag; a value `bubble` over the thumb and a `:vertical` orientation |
| `DevactionUI.SignatureField` | draw or type a signature; the pad stays mounted when the mode changes, and the SVG of the stroke is safe to keep. The typed name is set in the Caveat font (weight 500), which you load yourself |
| `DevactionUI.Combobox` | a select with a search field, accent-insensitive filtering and the ARIA combobox keys |
| `DevactionUI.DataTable` | sticky header, sortable columns (`aria-sort`, the server sorts), row selection with a tri-state header checkbox and a bulk bar that shows while something is ticked, two densities; `toolbar` and `footer` slots, a density toggle, `loading` (skeleton rows) and `error` states, and a default empty text through an attr |
| `DevactionUI.Kanban` | columns with WIP limits and cards that move by drag or Alt + arrows, announced to screen readers; the LiveView gets one `move_card` event; dragging works with mouse, pen and touch (pointer events); the keyboard keeps Alt + arrows |
| `DevactionUI.Editor` | a TipTap toolbar and surface that sends HTML and Markdown in hidden inputs; `/` blocks, `@` mentions, image upload, an AI tool, a compact comment form, visible label, error and disabled; `toolbar_position` for a compact editor with the toolbar at the bottom, and attrs for the CSRF header and the event names of uploads |
| `DevactionUI.Autocomplete` | a field with grouped suggestions (the server searches), the match in bold, ↑ ↓ Enter, ⌘↵ for an "ask the AI" row |
| `DevactionUI.DatePicker` | a month calendar for one day or a range, keyboard grid, shortcuts, dates as ISO in hidden inputs; plus `due_chip/1` (late, today, later); `date_input/1` (a masked field with the calendar in a popover) and `date_range/1` (two linked fields) |
| `DevactionUI.Calendar` | a month or a week of days with coloured event chips, a keyboard grid (arrows, Home, End, Page keys); `title` and `cell_label` come from the caller; the week view has an hours grid (`hours` range, `weekend`, events with `starts_at`/`ends_at`), a `legend` slot and the `:chart_1` to `:chart_4` kinds |
| `DevactionUI.Popover` | a panel with an arrow anchored to a button; Esc and outside click close it, focus goes in and comes back |
| `DevactionUI.ToastGroup` | notices stacked into layers with a count, opened into a list, auto-dismissing and pausing on hover |
| `DevactionUI.EmptyState` | the dashed card of a list with nothing in it: icon chip, title, one line, optional action |
| `DevactionUI.Avatar` | two letters in a circle (`initials/1`) and a stack that overlaps by 8px, named once as a group |
| `DevactionUI.ChatBubble` | one message with the AI (left, with its mark) or the person (right, in ink); amber when the AI did something |
| `DevactionUI.AiPrompt` | the ink pill that talks to the AI: amber dot, required field, round send button; `loading`, `disabled`, `streaming` with a stop button, an `attachments` slot and a `target`; a form, so Enter sends |
| `DevactionUI.Sidebar` | the app's side menu, 236 px or 64 px collapsed with tooltips; `aria-current`, a toned `count` per item, collapsible `group`s, `responsive` to keep it on small screens; `Sidebar.search` (with the key hint) and `Sidebar.user` (avatar, name, menu trigger) for its header and footer |
| `DevactionUI.AuthCard` | the card of a sign-in screen: grid and glow header, icon tile (`brand` or amber), `h1`/`h2` title, form, quiet footer strip |
| `DevactionUI.AuthLayout` | the framed page around it: product column with reasons to sign in, the card, a footer `nav` (named by `nav_label`); `AuthLayout.auth_brand` draws the mark tile and the name |
| `DevactionUI.Highlight` | `heex/1` and `elixir/1`: split source into `{kind, text}` tokens (tags, components, slots, attributes, `:if`/`:for`/`phx-*` directives, strings, the Elixir inside expressions, comments) for `CodeBlock`; `lines/1` cuts them at the line breaks |
| `DevactionUI.MoneyInput` | a field masked as `R$ 1.234,56` (`DevactionUI.MoneyMask` hook); `parse/1` returns the cents |
| `DevactionUI.Dropdown` | a button with a menu of actions or choices (radio items with a check), ↑ ↓ Home End Esc |
| `DevactionUI.ConfirmDialog` | the modal that asks before something that cannot be taken back; focus trapped, Esc closes |
| `DevactionUI.Dropzone` | the dashed area over a LiveView upload; lights up (and announces it) while a file is over it, writes the limits from the upload config, lists each file with a progress bar and a remove button |
| `DevactionUI.Choice` | checkbox (with the partial state and a task style), radio, choice card, and the `checkbox_group/1` and `radio_group/1` fieldsets with help and error |
| `DevactionUI.Switch` | a `role="switch"` button for what takes effect at once; `name` makes it a form field through a hidden input; row, card and the `saved_note/1` live region |
| `DevactionUI.Segmented` | a pill of toggle buttons (`aria-pressed`) with a roving tabindex and arrow keys, counts, disabled options and `patch`/`navigate` |
| `DevactionUI.NotificationCenter` | `panel/1`: the notification panel (tabs with unread counts, day groups, tone-coloured icon tiles, warm unread tint and dot, "mark all as read", footer); ↑ ↓ between rows, ← → between tabs; events by attr, the `icon` slot receives the item |
| `DevactionUI.Pricing` | `table/1`: a billing toggle built on `Segmented` and a card per plan (price, period and features all by attr, never invented), a highlighted plan with a ribbon, a text-only plan, a `check` slot |
| `DevactionUI.CookieConsent` | `banner/1`: a non-modal `role="dialog"` anchored to the bottom, three actions and the category list with a switch each (the first locked on); Esc closes only the preferences |
| `DevactionUI.Aura` | a turning ring of light (or a breathing halo) around the AI at work; `variant`, `size`, `shape`, `speed`; still under reduced motion |
| `DevactionUI.Chart` | SVG charts drawn on the server: a line chart (with a table view), bars, columns, a ring and a sparkline; the four `chart-*` colours, hover and focus dim the others |
| `DevactionUI.Progress` | a linear progress bar |
| `DevactionUI.ProgressToast` | a notice that fills as a job advances, with an aura, and leaves by itself when it is done |
| `DevactionUI.Skeleton` | a shimmering placeholder |
| `DevactionUI.Timer` | hours on a task in large mono digits (`HH:MM:SS`), start or pause and stop and log; the server owns the seconds, the browser only draws them between updates; `timer_mini/1` (a dot and `HH:MM` for the app bar) and `time_log/1` (the list of what was logged today) |
| `DevactionUI.Spinner` | a spinning ring |

Where an app also has its own `alert`, `badge`, `button` or `pagination`, call these qualified
(`<DevactionUI.Alert.alert>`) instead of importing them, so the two never collide.

The documentation site shows all of them in every variant; flip the theme there to check the dark side.

## Adding a component

1. Put it in `lib/devaction_ui/`, with `attr`s and `slot`s documented, a `@moduledoc` that says what it means and
   when to use it, and a test in `test/devaction_ui/`.
2. Show it in the site: list the module in a category of `site/lib/devaction_ui_site/catalog.ex` (it gets its page, its title and
   its summary from the module itself) and add its sections as `site/lib/devaction_ui_site/examples/<slug>_<nn>.html.heex`,
   each starting with `<%!-- title: Title | text: One line --%>`.
3. Replace any copy of it in a screen. A screen that needs a variant adds it here; it does not write its own.

## Hooks

The hooks are plain ES modules in `assets/js/devaction_ui/` (one file per component, `index.js` exports
them as `DevactionUI.Tabs` and so on); no component carries a `<script>`. A host app merges them in its
`app.js`: `hooks: {...devactionUI}`. The logic that needs no DOM sits in its own module with a test beside
it (`mix js.test`). Their DOM
is changed by the hook, so the server must not undo it: tabs and accordion tell LiveView to ignore the
attributes the hook owns (`JS.ignore_attributes`), the pillbox and the combobox use `phx-update="ignore"`,
the table puts the ticks back after a redraw (`beforeUpdate`/`updated`) and the board gives the focus back to the
moved card.
To check the keys and the focus by hand, open the documentation site.

## Time zones and languages

The library never reads the clock or a locale. The date picker takes `today` (an ISO date the caller computed in the
workspace's time zone) and a `locale` for the month and weekday names (browser `Intl`); every text, from a shortcut
to "Collapse", is given by the caller. The date picker and the pillbox are `phx-update="ignore"`: to reset them from
the server, give them a new `id`.
