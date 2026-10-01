# GNOME Extensions kit

Shared Claude Code rules, skills and templates for Jackicus's GNOME Shell extensions. Each
extension is a git repository of its own, checked out **inside** this folder; the kit
ignores them (`.gitignore`) and holds only what they share, so a rule is written once and
cannot drift between five copies.

```
GNOME-EXTENSIONS/                  this repository: Jackicus/GNOME-EXTENSIONS
├── CLAUDE.md                      rules for every extension session (loaded automatically)
├── .claude/rules/                 the same, by topic: live-session.md, gjs-st.md
├── .claude/skills/rollout/        the kit's own skill: land a template change everywhere
├── .claude-plugin/marketplace.json
├── plugin/                        the gnome-ext plugin: fix-bug, review-pass,
│                                  nested-shell, release, doctor, screenshots,
│                                  ego-review, port-shell-version, hig-polish, readme
├── template/                      files every extension carries (CI, the kit hook, ESLint,
│                                  the pull request template, the issue forms,
│                                  CONTRIBUTING.md, settings to merge)
├── scripts/setup.sh               once per machine: install the plugin
├── scripts/sync.sh                copy template/ into the extensions
├── scripts/check.sh               the kit's own check (CI runs it)
├── GNOME-AI-Usage/                an extension, its own repository (ignored here)
├── GNOME-Games-Library/           …
├── GNOME-Media-Controls/
├── GNOME-Video-Library/
└── GNOME-Wallpaper-FX/
```

## How a session gets the kit

Claude Code reads every `CLAUDE.md` from the working directory up to `/`, and the
`.claude/rules/` beside them, so a session started in `GNOME-Media-Controls/` loads this
folder's `CLAUDE.md` and rules first and the extension's own after them. Skills in a
parent folder are not loaded that way, which is why they ship as a plugin: each
extension's `.claude/settings.json` declares this folder as a plugin marketplace
(`"path": ".."`) and enables `gnome-ext` there. The plugin is read from this folder, so a
`git pull` here is all an update takes.

Each extension's SessionStart hook, `.claude/kit.sh`:

- **beside the kit**: pulls it (`--ff-only`, 15 s at most) when it is on `main`, and if
  that brought anything new, says so and tells the session to re-read the rules, which
  were loaded before the pull;
- **without a kit beside it** (a cloud session, a fresh clone elsewhere): clones the kit
  into `~/.cache/gnome-extensions-kit` (or updates it) and prints its `CLAUDE.md` and
  rules into the session, with the path of the skills to read as playbooks;
- offline, it says in one line what it could not do. It never fails the session.

Every extension's own `CLAUDE.md` opens with one line saying where the shared rules come
from (`template/CLAUDE.pointer.md`).

## Setting up a machine

```bash
git clone https://github.com/Jackicus/GNOME-EXTENSIONS ~/Projects/GNOME-EXTENSIONS
cd ~/Projects/GNOME-EXTENSIONS
for r in AI-Usage Games-Library Media-Controls Video-Library Wallpaper-FX; do
    git clone https://github.com/Jackicus/GNOME-$r
done
scripts/setup.sh
```

`setup.sh` registers this folder as the `gnome-extensions` marketplace, installs
`gnome-ext`, and leaves it off at user level, so it is on in the extensions (their
settings enable it) and nowhere else. Run it again any time; it changes nothing the
second time.

## Changing the kit

The kit takes changes the way the extensions do: an issue, a branch, `scripts/check.sh`,
a pull request, a green `kit check`, a squash merge. Then:

- **`CLAUDE.md`, `.claude/rules/`, `plugin/`**: nothing more. The next session in any
  extension sees it.
- **`template/`**: `scripts/sync.sh` copies it into every extension (or name some:
  `scripts/sync.sh GNOME-Media-Controls`), merging `.claude/settings.json` rather than
  replacing it; each extension lands the result through its own pull request.
  `scripts/sync.sh --check` changes nothing and lists what differs. In a Claude Code
  session started in this folder, the `rollout` skill does all of that.

## A new extension

Create its repository inside this folder, then `scripts/sync.sh <name>`, add the pointer
line to the top of its `CLAUDE.md`, give it a `make check`, and run the
`gnome-ext:doctor` skill in it: that walks the rest (CI, settings, protection).

## Not done yet

The extensions' development scripts began as one and have drifted apart: five copies of
`./scripts/nested.sh`, `./scripts/nested_driver.py`, `./scripts/dev-extension.js` and
`./scripts/dev.sh`, each with its own fixes. Converging them into `template/`, with what
really differs per extension moved into a small configuration file, is the next step,
after each extension's instructions have been audited.
