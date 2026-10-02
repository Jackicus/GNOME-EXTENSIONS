---
name: ego-review
description: Audit a GNOME Shell extension against the current extensions.gnome.org review guidelines and best practices before it is uploaded - lifecycle, cleanup, imports, metadata, schemas, the zip, subprocesses, clipboard, telemetry, logging, licensing and trademarks, and code that reads as unexplained or generated - reporting file:line findings, fixing the clear-cut ones through the loop. Use before a release or an upload, or when asked whether an extension would pass review. gnome-ext:release runs it first.
argument-hint: "[repository; default the current one]"
---

Repository: $ARGUMENTS (nothing given: the current one)

The checklist comes from the guidelines as published, not from memory. It was built from
https://gjs.guide/extensions/review-guidelines/review-guidelines.html and
https://gjs.guide/extensions/review-guidelines/best-practices.html, read on 2026-10-01.
**Fetch both again first** (WebFetch) and add to or strike from the list below whatever
has changed; if anything did, fix this skill in a kit pull request. Read the repository's
`docs/publishing.md` too: it records how the extension already answers the review.

Work on the shipped tree: what `make pack` (Wallpaper FX: `make zip`) puts in
`dist/<uuid>.shell-extension.zip`. Every finding is `file:line`, the rule, and the fix.

## Blockers (a reviewer rejects on these)

- **Nothing before `enable()`**: module scope and the `Extension` constructor make no
  GObject (`Gio.Settings`, `St.*`), connect no signal, add no main-loop source and change
  nothing in the shell. Static data (a `Map`, a `RegExp`) is allowed; `disable()` clears
  what it accumulated.
- **`disable()` undoes all of `enable()`**: every object and widget destroyed, every
  signal disconnected, every source removed, even one whose callback would return
  `GLib.SOURCE_REMOVE`. Under `unlock-dialog` keyboard signals are disconnected, and
  `disable()` has a comment saying why the mode is used; never disable selectively.
- **Imports**: no `ByteArray`, `Lang` or `Mainloop`; no `Gdk`, `Gtk` or `Adw` in the
  shell process; no `Clutter`, `Meta`, `St` or `Shell` in `prefs.js` or anything it
  reaches (`make check`'s imports walk where the repository has one).
- **`metadata.json`**: `uuid` is `id@namespace` (letters, digits, `.`, `_`, `-`; never
  gnome.org); `shell-version` only stable releases the extension has run on, at most one
  development release, nothing future; `url` the repository; no `version` set by hand, no
  `session-modes` if it is only `user`, no unused keys; `settings-schema` present and
  used through `this.getSettings()` with no argument.
- **Schemas**: id under `org.gnome.shell.extensions`, path under
  `/org/gnome/shell/extensions/`, the XML in the zip as `<schema-id>.gschema.xml`; no
  `gschemas.compiled` (the shell compiles on install since 44).
- **Readable code**: no minified or obfuscated JavaScript.
- **Subprocesses**: no shipped binaries or libraries; spawned processes exit cleanly;
  scripts in GJS unless unavoidable; no privileged subprocess other than through `pkexec`
  on a file the user cannot write.
- **Clipboard** use, with or without input, is declared in the description, never shared
  without the user acting, and has no default shortcut.
- **No telemetry**; nothing tracks the user or sends their data anywhere unasked.
- **Not AI-generated**: AI as a tool is allowed, but the owner must be able to explain
  every line. Reviewers reject large unnecessary code, inconsistent style, APIs that do
  not exist, leftover prompts and other generated-output tells. Look for them as a
  reviewer would: defensive checks on things that cannot be missing, comments that
  narrate the next line, helpers used once, `try`/`catch` around calls that cannot throw.
  The kit's `.claude/rules/simplicity.md` is the standard to report against, and
  `./scripts/dev.sh size` the numbers to quote; a finding here is fixed with
  `gnome-ext:simplify-pass`, not in this audit.
- **Legal**: GPL-2.0-or-later compatible; code from other extensions credited; no brand
  names, logos or artwork without the owner's permission (a provider's or service's
  logo used as an icon counts); nothing against the GNOME Code of Conduct; no political
  content.
- **Functional**: it does what the description says on the claimed versions.

## Best practices (fix unless the repository records why not)

- No `try`/`catch` around `destroy()`, `connect()`, `disconnect()`, `abort()` or
  `GLib.Source.remove()`, and no `_destroyed` flags: destroy and null instead. Only a
  step that can throw for a reason outside the extension (a private API, a monkey-patch
  put back, another extension's object) is guarded (`.claude/rules/gjs-st.md`).
- No optional chaining or type checks on what the targeted versions guarantee.
- A source's removal sits next to its creation; `enable()` and `disable()` sit together;
  each class cleans up what it made; the entry point stays small.
- `St.Icon` in the shell and `Gtk.Image` in the preferences, never emoji as icons.
- No line over 200 characters; no logging beyond errors and important events.
- D-Bus over spawning commands; no unnecessary files in the zip (build scripts, `.po`,
  unused media; `check_pack` in `./scripts/dev.sh` where the repository has it).
- The description says what is sent over the network, to whom, and what is written
  outside the extension's own settings (the published repositories already do this).

## Then

1. Fix the clear-cut findings through the repository's loop: an issue, a branch, `make
   check`, a pull request, green CI, squash merge. One concern per pull request.
2. Update `docs/publishing.md`'s review section with how each guideline is met, the date
   and the guideline URLs.
3. Report: blockers left (file:line, the options), what was fixed (PRs), and what only a
   human can answer (permission for a logo, why a private API is needed).
