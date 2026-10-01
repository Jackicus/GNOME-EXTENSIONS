# GJS, St and the shell: what holds in every extension

## Loading and reloading

- **GJS caches a module by URL for the life of the shell.** `extension.js` and
  `metadata.json` are read once: `reload` picks up `lib/`, the stylesheet and the compiled
  schema, never the entry point. A changed `./scripts/dev-extension.js` or
  `metadata.json` needs a logout, or a nested `stop` + `start`.
- **A new UUID needs a logout**: the shell scans for unknown UUIDs only at startup.
  "Doesn't exist" from `gnome-extensions info` means exactly that; no reload fixes it.
- **`make reload` is not optional.** The link puts edits on disk; the shell holds the old
  modules until the disable/enable cycle.
- **`./scripts/dev-extension.js` stages a fresh copy of `lib/`**, so an edit reaches the
  next enable under a URL GJS has not cached: one per running shell (by its process id),
  named for a checksum of the files, so an unchanged re-enable reuses it and no shell
  ever removes another's. The script is the kit's, the same in every repository. The
  shipped `extension.js` imports `lib/app.js` once, as an install
  should.
- **GObject type names outlive modules.** A class registered under a fixed name fails the
  second time it is registered ("already registered"); under staging, every enable loads
  `lib/` afresh. Name per-load classes apart, or register once.
- **The schema is compiled, not read.** After editing the `.gschema.xml`,
  `glib-compile-schemas src/schemas`, then a nested `stop` + `start`.
- **Never `gnome-extensions install --force` over the link**: its recursive delete follows
  the links into `src/`. `make uninstall` first.
- **Never hardcode the repo path**, and never derive one from `import.meta.url`: modules
  run from a staging copy under the link and from the install otherwise. Use `this.path`
  / `this.dir`.
- **`gjs -m -c '…'` fails for any input on gjs 1.88**: `-m` takes the `-c` text for a
  file name. A one-off module check is a script file run with `gjs -m`.
- **GObject subclasses follow their parent's constructor style.** `PanelMenu.Button` (and
  the shell classes still on `_init`) are subclassed with `_init(…)` and
  `super._init(…)`; `St.BoxLayout` and the other St/Clutter classes with
  `constructor(…)` and `super(…)`.

## Living in the compositor

- **A long synchronous block is a dropped frame for the whole desktop.** No synchronous
  I/O on a path that can be slow (a network share, an automount: the first stat after an
  idle-out blocks for the whole connect timeout); use Gio's `*_async`. Build lazily: no
  actor per item owned, nothing built on a frame that is animating.
- **Check the logs.** Exceptions in an extension go to the shell's journal, never a
  terminal: `make logs`, or `./scripts/nested.sh logs` in the nested shell. A throw in
  `enable()` leaves the old UI or nothing, which reads as "no change".
- **A freeze leaves no log.** Where a repository has `make stalls`, it catches one in the
  act. Measure the main loop with `Properties.Get` on `org.gnome.Shell`, never
  `Peer.Ping`, which GDBus answers on its worker thread.
- **`disable()` undoes everything `enable()` did**: destroy and null, disconnect, remove
  sources, in plain calls. No `try`/`catch` around `destroy()`, `disconnect()` or
  `GLib.Source.remove()`, and no `_destroyed` flags (extensions.gnome.org best practice).
  Guard only a step that can throw for a reason outside the extension (a private shell
  API reach, a monkey-patch put back, another extension's object), so one moved internal
  cannot abandon the rest and leave handlers running beside the next enable's. Screen
  lock disables and unlock enables (`session-modes` `['user']`).
- **The shell is shared with other extensions.** GObject type names, CSS classes, effect
  names, settings paths, cache and runtime directories and the log prefix are global:
  each carries the extension's prefix. A monkey-patch wraps what it found and calls it;
  it is taken back only while the current value is still its own, by putting back exactly
  what was there, since another extension may have wrapped it since.
- **Never name a method `connect`** (or `connectAfter`, `disconnect`, `emit`, …) on an
  `EventEmitter` or GObject subclass: `connectObject` builds on the signal methods it
  finds, and an own `connect` breaks every tracked connection.
- **`captured-event::key` is wider than a key press**: check
  `event.type() === Clutter.EventType.KEY_PRESS` before asking for a key symbol.
- **Arrow keys never reach the focus manager while a `pushModal` grab holds.** Under a
  grab, call `global.focus_manager.navigate_from_event(event)` from the grab actor's
  `key-press-event`, as the shell's popup menus and dialogs do.
- **`Main.panel.addToStatusArea(role, …)` holds the role until the indicator is
  destroyed**: a second add under the same role throws. Moving an indicator is a reparent
  between the panel's boxes; destroying it releases the role.
- **`Main.layoutManager.addChrome()` takes `trackFullscreen` and `affectsStruts` only** on
  50 (`affectsInputRegion` is gone): anything else throws `Unrecognized parameter`.
- **Activating an item in a `PopupMenuSection` closes the whole menu**: the menu that
  added the item calls `itemActivated`, which closes the top menu, after every
  `activate` emission. An item that must leave it open overrides `activate()` and does
  not emit, as the shell's switch item does for Space.
- **"Is the app grid up?" is `Main.overview.dash.showAppsButton.checked`**, never
  `appDisplay.visible`: the shell holds the app display visible for the whole slide down
  to the window picker and does not update it once the transition is dropped. The
  button is checked as the grid opens and cleared on every way out.
- **A scroll view's `St.Adjustment` is already disposed when the view's `destroy`
  fires**: disconnecting from it there throws. Its handlers die with it; take back only
  what is not the adjustment's (an idle source).
- **Hover on many tiles is crossing events, not `track_hover`**: the `hover` pseudo-class
  restyles the widget and every child under it, on every enter and leave. Only a widget
  that paints from `:hover` tracks it, and no rule keys a descendant off a parent's
  `:hover`.
- **Two writes at once on a GIO stream fail** ("Stream has outstanding operation"): queue
  them, one `write_bytes_async` after the last finishes.
- **A dconf database name is a D-Bus object-path element**: letters, digits and
  underscores only. With a hyphen every write fails and `gsettings set` hangs.

## St is not the web

- **St CSS is paint, not layout.** No flexbox, grid, `calc()`, variables, `opacity`,
  percentage widths, negative margins, `:first-child`/`:last-child` or
  `linear-gradient()` (`background-gradient-direction/start/end` instead). Layout is
  `St.BoxLayout`, `Clutter.BinLayout` and JS. A negative preferred width allocates
  -2147483648 and the actor vanishes.
- **`St.Bin` centres its one child and ignores its `x_align`**; `St.BoxLayout` hands an
  `x_expand` child the slack.
- **JS sizes are physical pixels, CSS is logical.** A number that meets an allocation is
  multiplied by `St.ThemeContext.get_for_stage(global.stage).scale_factor`; a number
  written into a `set_style()` string is not (St scales CSS itself). `St.Icon.icon_size` is
  logical. A length read back from a theme node is already physical.
- **A fresh actor has no style until something asks**, and no allocation until the next
  frame. `ensure_style()` covers only the widget it is called on: walk the subtree before
  measuring anything just built.
- **A rounded background image carries its radius inline**, in the same `set_style()` as
  `background-image`; an image-backed widget never gets a `box-shadow` (drawn square).
- **An icon file must start with `<svg`**: gdk-pixbuf sniffs the opening bytes, so a
  comment before the tag makes it silently not an image. Comments go inside.
- **An icon's size comes from its own `icon_size` or the theme's, never an ancestor's
  `font-size`**: text scaled through a font size leaves the icons beside it at the
  theme's size until each icon's `icon_size` is scaled too.

## Looking like GNOME

- **A modification of GNOME, not a second one.** Use the shell's own widget first
  (`PopupMenu`, the quick settings' `Slider`, `icon-button`, `overview-tile`,
  `app-folder-dialog`, the OSD's placement); draw only what GNOME has no equivalent for.
- **Type is in em** (1em is the shell's UI font), so Large Text and scaling follow. A px
  font size, or any px but a hairline border or a shadow, is a bug, unless the
  repository's CLAUDE.md or rules state the exception and what it was measured against
  (a padding matched to the shell theme's own px).
- **Colour comes from the accent and the shell's neutrals**: `-st-accent-color`,
  `-st-accent-fg-color`, `st-lighten()`, `st-mix()`, `st-transparentize()`. Never a
  hard-coded hue; menus follow the light/dark preference.
- **Motion sits beside the shell's**: 100–250 ms, ease-out-quad, through `actor.ease()`,
  which honours the animations switch and the slow-down factor. One module (`anim.js`)
  holds an extension's durations. A duration outside the range is stated, with its
  reason, in the repository's CLAUDE.md.
