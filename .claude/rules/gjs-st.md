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
- **`./scripts/dev-extension.js` stages `lib/` under a checksum of its files**, so an edit
  makes a new stage and a lock/unlock re-enables into the same module graph. The shipped
  `extension.js` imports `lib/app.js` once, as an install should.
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
- **`disable()` undoes everything `enable()` did**, each step on its own and guarded: a
  step that throws must not abandon the rest, or handlers keep running beside the next
  enable's. Screen lock disables and unlock enables (`session-modes` `['user']`).
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

## Looking like GNOME

- **A modification of GNOME, not a second one.** Use the shell's own widget first
  (`PopupMenu`, the quick settings' `Slider`, `icon-button`, `overview-tile`,
  `app-folder-dialog`, the OSD's placement); draw only what GNOME has no equivalent for.
- **Type is in em** (1em is the shell's UI font), so Large Text and scaling follow. A px
  font size, or any px but a hairline border or a shadow, is a bug.
- **Colour comes from the accent and the shell's neutrals**: `-st-accent-color`,
  `-st-accent-fg-color`, `st-lighten()`, `st-mix()`, `st-transparentize()`. Never a
  hard-coded hue; menus follow the light/dark preference.
- **Motion sits beside the shell's**: 100–250 ms, ease-out-quad, through `actor.ease()`,
  which honours the animations switch and the slow-down factor. One module (`anim.js`)
  holds an extension's durations.
