# GNOME Extensions

This folder is the **kit**: shared rules, skills and templates for the GNOME Shell extensions
checked out beside it, one git repository each (`GNOME-AI-Usage`, `GNOME-Games-Library`,
`GNOME-Media-Controls`, `GNOME-Video-Library`, `GNOME-Wallpaper-FX`). The kit is a repository
of its own (Jackicus/GNOME-EXTENSIONS) that ignores them. A session started in an extension
loads this file and `.claude/rules/` from here, then the extension's own CLAUDE.md, which
says what that extension is and what is true only of it. When the two disagree, the
extension's file is the more specific and wins; fix whichever is wrong.

## The stack

- GJS with ES modules, GNOME Shell 50. Every `metadata.json` claims `["50"]`, the version
  each has been run on; some are audited against 48 and 49's sources and say so in their
  own CLAUDE.md. A version is claimed only once it has been booted.
- Two processes, two toolkits. `extension.js` and everything it imports run **inside the
  compositor**: St, Clutter, Meta, Shell, `resource:///org/gnome/shell/…`. `prefs.js` runs
  in the Extensions app's process: Gtk 4 and libadwaita, never St, Clutter, Meta, Shell
  or `ui/`. A module both sides import imports neither (Gio, GLib and its own pure code
  only). A shell import reached from `prefs.js` fails only when the preferences open.
- `src/` is exactly what ships: `make pack` (Wallpaper FX: `make zip`) zips it into
  `dist/<uuid>.shell-extension.zip`, `make install` copies it, and a file added there
  ships. `make link` installs a directory of links into `src/` whose entry point is
  `./scripts/dev-extension.js`, which stages `lib/` afresh so `reload` picks up edits.
- `make` is a thin front door: `./scripts/dev.sh` for the extension (link, install,
  reload, logs, pack, status) and `./scripts/nested.sh` for the nested shell. New logic
  goes in those, not in the Makefile.
- Settings are a GSettings schema in `src/schemas/`, `org.gnome.shell.extensions.<name>`.
  `glib-compile-schemas --strict` must pass: an install compiles it that way.

## Two machines

The user works on two, and a session may be on either: the main desktop (NVIDIA GTX 1080,
GNOME Shell 50.5) and an Intel HP all-in-one (Mesa, GNOME Shell 50.4). A shell version,
GPU, driver or measurement in a doc names the machine it was taken on; a claim of support
is machine-independent ("GNOME Shell 50"). An audit never "corrects" one machine's
numbers to the other's. Which one this is: `gnome-shell --version`, `lspci | grep -i vga`
or `glxinfo -B | grep renderer` (NVIDIA or Mesa Intel).

## Never the user's session

The user's desktop is the one they are working in. Everything is tried in a **nested
shell**: a second, headless GNOME Shell with its own session bus, mirrored live on the
desktop (`.claude/rules/live-session.md`; the `gnome-ext:nested-shell` skill to drive it).
Never reload, restart or enable anything in the real session to test a change, never write
the user's dconf for a test, and never touch another repository's nested shell. A nested
shell that outlives its command (`./scripts/nested.sh start`) is stopped by the
repository's SessionEnd hook if the session ends first; stop it yourself when the work is
done. AI Usage's lives only while its command runs, and it has no such hook.

## Style

- `make lint` is ESLint with gjs.guide's configuration (`eslint.config.mjs`, the same in
  every repo: `template/eslint.config.mjs`). No errors, and no new warnings.
- 4-space indents, `const` and `let`, `console.*` for logging behind the extension's own
  `[Name]` prefix, which `make logs` filters on. The shipped code logs failures only.
  `make logs` takes no time: a Makefile rule drops arguments (`make logs '5 min ago'`
  makes a second goal), so a window goes to `./scripts/dev.sh logs '5 min ago'`.
- Comments describe the code as it is: no phase numbers, review IDs, plans or history.
  History is git's.
- GObject type names, CSS classes, settings paths, cache and runtime directories are
  global to the shell: each extension prefixes its own (`.claude/rules/gjs-st.md`).
- Private shell API (an underscore field, an unexported class) is listed where the repo
  keeps that list (`docs/private-api.md` or its CLAUDE.md), with what breaks when it moves.

## Landing a change

`main` is protected on every extension and on the kit: no direct push, from anyone. The
required check is the `make check` job in `.github/workflows/ci.yml`.

1. **An issue first**, for anything but a trivial fix (a typo, a comment). Separate
   problems are separate issues and separate pull requests.
2. **A branch per issue**, named for it (`fix/…`, `feat/…`, `docs/…`).
3. **`make check`** passes on the branch: ESLint, plus whatever the repo checks without a
   shell (schemas, imports, parsers, shaders). A visible change is also seen in the nested
   shell, before and after, and an enable-path change survives a nested `stop` + `start`.
4. **Push, open the pull request** with "Fixes #N" and how it was verified
   (`.github/pull_request_template.md`).
5. **Wait for CI to go green**, fix what it finds, then
   `gh pr merge --squash --delete-branch`. No approving review is required, so a session
   merges its own.
6. **Check main's CI run** after the merge, and pull main locally.

"Fix this" or "implement this" authorises the whole loop: carry it through to the merge
without stopping to ask. Ask first only for what reaches outside the repo and the nested
shell: the user's real session or settings, a real launch, an online scan with real keys,
a release (`gnome-ext:release`).

A change that makes a line in a CLAUDE.md, a `.claude/rules/` file, a skill or `docs/`
wrong fixes that line in the same pull request. A rule that turns out to be true of every
extension moves here, in a kit pull request, and leaves the extensions' files.

## Where an extension keeps its own

- `CLAUDE.md`, at most 200 lines: what the extension is, its layout, how its parts fit,
  its design rules and the traps that are its alone. It starts with the kit pointer line
  (`template/CLAUDE.pointer.md`).
- `.claude/rules/<area>.md` with `paths:` frontmatter, for an area's detail that only
  matters while its files are open (the scanner, the shaders, a VLC socket).
- `.claude/skills/drive-extension/SKILL.md`: what this extension looks like in the nested
  shell (coordinates, its own commands and fixtures, what must never be pressed). The
  generic driving is the kit's `gnome-ext:nested-shell` skill; the drive skill does not
  repeat it.
- `.claude/commands/` (`/logs`, `/reload`, `/status`, `/preview`, …): per repo, since each
  names its own log line, its own healthy state and its own data.
- `.claude/settings.json`: the SessionEnd hook that stops the nested shell (where the
  nested shell outlives its command), plus the kit's SessionStart hook and plugin, merged
  in by `scripts/sync.sh`.

## Skills from the kit

The `gnome-ext` plugin (`plugin/`) is enabled in each extension's settings and installed
once per machine by `scripts/setup.sh`: `gnome-ext:fix-bug`, `gnome-ext:review-pass`,
`gnome-ext:nested-shell`, `gnome-ext:release`, `gnome-ext:doctor`. Outside this
workspace (a cloud session, a fresh clone) the plugin is not there; `.claude/kit.sh`
prints this file and the rules into the session and says where the skills are on disk,
to be read as playbooks.

## Working on the kit

The kit goes through the same loop: issue, branch, `scripts/check.sh` (what the kit's CI
runs), pull request, green CI, squash merge. Then:

- after a change under `template/`, run `scripts/sync.sh` and land the result in each
  extension through its own pull request; `scripts/sync.sh --check` lists what differs;
- after a change under `plugin/`, nothing: the plugin is read from this folder, so the
  next session sees it. Bump `plugin/.claude-plugin/plugin.json`'s version when a skill's
  meaning changes.

`scripts/check.sh` checks that every backticked path in this file, the rules and the
skills that starts `template/`, `plugin/`, `.claude-plugin/`, `.claude/rules/`, `scripts/`
or `.github/` exists in the kit (a `.github/` path in `template/` counts). An extension's
own scripts are therefore written `./scripts/…`.
