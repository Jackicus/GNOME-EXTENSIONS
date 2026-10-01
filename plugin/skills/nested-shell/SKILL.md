---
name: nested-shell
description: Drive a GNOME Shell extension in a throwaway nested GNOME Shell, mirrored live on the user's desktop - start it, reload into it, click, press keys, screenshot regions, read the PNGs, read its logs, then stop it. Use whenever a change to an extension must be SEEN (layout, colour, spacing, motion end-states, the preferences window) or needs a fresh shell start (extension.js, metadata.json, the schema, a new UUID). Read the repository's own drive-extension skill too, for its coordinates and commands.
argument-hint: "[what to show or check]"
---

What to check: $ARGUMENTS

The extension draws into the shell, not into a window, so a visual change is verified only
by looking at it. This is the generic loop; the repository's
`.claude/skills/drive-extension/SKILL.md` adds where things are on its screen, its own
commands (a player, a virtual pad, demo data) and what must never be pressed. Read both
before the first `start`. The rules in the kit's `live-session.md` hold throughout.

AI Usage drives its shell differently (`./scripts/dev.sh nested [--window|--keep]` and
`./scripts/dev.sh shots [--light]`, keyfile settings under a scratch directory); its
CLAUDE.md says how. Everything below is `./scripts/nested.sh`, which the other extensions
share in shape (`./scripts/nested.sh help` for this repository's exact list).

## The loop

```bash
S=<your scratchpad>                       # shots go there, never into the repository
./scripts/nested.sh start --clean         # ~2 s; the extension is ACTIVE when it returns
./scripts/nested.sh do "say Baseline" "shot $S/before.png"
# … edit src/ …
./scripts/nested.sh reload
./scripts/nested.sh do "say After the change" "shot $S/after.png"
./scripts/nested.sh stop                  # closes the mirror; read its last line
```

Then **Read the PNGs** and say what actually differs. If nothing visibly changed, say so;
never assume an edit worked.

- **`start`** reuses a running shell. `--clean` (where the repository has it) gives it a
  settings database of its own; use it unless the task is about sitting beside the user's
  other extensions, which only a plain `start` loads. `--headless` skips the mirror;
  `start WxH` sets the monitor (default 1600x900).
- **`reload`** disables and enables the extension inside the nested shell. It does not
  recompile the schema or re-read `extension.js` or `metadata.json`: those need
  `stop` + `start`.
- **`stop` + `start` at least once before calling a change done.** Only a fresh start runs
  the enable path and the first frame as a login does.

## One call per interaction: `do`

`do` runs its steps over one connection and input session and stops at the first that
fails, so a whole walkthrough is one tool call.

| Step | Does |
|---|---|
| `say TEXT` | A banner in the nested shell (≤ ~40 characters, no apostrophes: steps are shell-split). One before every step the user should follow. |
| `click X Y` / `move X Y` | Click or hover at desktop coordinates. |
| `key KEYSYM` | `Escape`, `Return`, arrows, `F1`–`F12`, one character, or a chord (`Super+Page_Down`). |
| `wait SECS` | Let something land: ~1 s after the overview opens or closes, ~0.6 s after a pop-up. |
| `shot [FILE [X Y W H]]` | A screenshot, or only a region: crop to what is being judged. |
| `window FILE` | The focused window alone (the preferences), where the repository has it. |
| `overview on\|off` | Show or hide the overview; a `shot` or `click` outside `overview on` dismisses it. |

The same steps exist as single commands for a one-off. Also: `status`, `logs [N] [--all]`,
`mirror on|off`, `run CMD…` (against the nested bus and displays, never the real ones).

- **Keep a keyboard walk in one `do`**: each `do` makes a fresh virtual keyboard.
- **Never click or hover at the top-left**: the Activities hot corner.
- **A screen-sharing indicator in the top bar** is the input session's screencast, not a
  bug. Crop it off shots that are kept.
- **The preferences**: `./scripts/nested.sh run gnome-extensions prefs <uuid>` opens them
  inside the nested session. The Extensions app keeps the `prefs.js` it first imported;
  after an edit, kill the nested one (the process whose environment names this
  repository's nested Wayland display) before reopening, never a bare `pkill -f`.
- **Settings**: under `--clean`, `./scripts/nested.sh run timeout 5 gsettings --schemadir
  src/schemas set org.gnome.shell.extensions.<name> KEY VALUE` changes its own database at
  once. Without `--clean`, see the dconf rule in `live-session.md`.

## When it looks wrong

`./scripts/nested.sh logs` first: a JS exception in `enable()` leaves the previous UI up
and reads as "no change". `logs 200 --all` shows the D-Bus and portal chatter too. Lines
with the extension's `[Name]` prefix are its own; without `--clean`, other extensions load
and log alongside.

If the mirror will not open (it needs GStreamer's PipeWire plugin), use `--headless` and
screenshots, and tell the user.

## Screenshots that are kept

`docs/screenshots/` images are taken under `--clean` (and `--demo` where the repository has
invented data), never of the user's own collection, accounts or files, at the size and
format the repository's drive skill names. Read every one before committing it.

## Finishing

`./scripts/nested.sh stop` when the task is done or abandoned. Report what was checked,
which shots show it (paths in the scratchpad), and anything that looked wrong.
