# GNOME Extensions kit

Shared Claude Code rules, skills and templates for Jackicus's GNOME Shell extensions. Each
extension is a git repository of its own, checked out **inside** this folder; the kit
ignores them (`.gitignore`) and holds only what they share, so a rule is written once and
cannot drift between five copies.

```
GNOME-EXTENSIONS/                  this repository: Jackicus/GNOME-EXTENSIONS
├── CLAUDE.md                      rules for every extension session (loaded automatically)
├── extensions.json                the extensions: directory, GitHub repository, alias
├── .claude/rules/                 the same, by topic: live-session.md, gjs-st.md
├── .claude/skills/rollout/        the kit's own skill: land a template change everywhere
├── .claude-plugin/marketplace.json
├── plugin/                        the gnome-ext plugin: fix-bug, review-pass,
│                                  nested-shell, release, doctor, screenshots,
│                                  ego-review, port-shell-version, hig-polish, readme,
│                                  pull, releases
├── template/                      files every extension carries (CI, the release workflow,
│                                  the kit hook, ESLint,
│                                  the pull request template, the issue forms,
│                                  CONTRIBUTING.md, settings to merge)
├── scripts/pull.sh                the kit and the extensions up to date (clones what is missing)
├── scripts/setup.sh               once per machine: install the plugin
├── scripts/sync.sh                copy template/ into the extensions
├── scripts/releases.sh            every extension's release state, read-only
├── scripts/protect-tags.sh        make an extension's v* tags permanent
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
  were loaded before the pull; fast-forwards the extension itself when it is on a clean
  `main` (or says in one line why it left it); then starts `scripts/pull.sh` for the
  other extensions in the background, and reports what the previous background pull
  found;
- **without a kit beside it** (a cloud session, a fresh clone elsewhere): clones the kit
  into `~/.cache/gnome-extensions-kit` (or updates it) and prints its `CLAUDE.md` and
  rules into the session, with the path of the skills to read as playbooks;
- offline, it says in one line what it could not do. It never fails the session.

A session started in this folder runs `scripts/pull.sh --quiet` itself (the kit's own
`.claude/settings.json`), so kit work starts with every extension current.

Every extension's own `CLAUDE.md` opens with one line saying where the shared rules come
from (`template/CLAUDE.pointer.md`).

## A new machine

```bash
git clone https://github.com/Jackicus/GNOME-EXTENSIONS.git && cd GNOME-EXTENSIONS && scripts/pull.sh && scripts/setup.sh
```

`pull.sh` clones every extension `extensions.json` lists beside the kit.

`setup.sh` registers this folder as the `gnome-extensions` marketplace, installs
`gnome-ext`, and leaves it off at user level, so it is on in the extensions (their
settings enable it) and nowhere else. Run it again any time; it changes nothing the
second time.

## Keeping up to date

`scripts/pull.sh` pulls the kit, then every extension in parallel (or those named, by
directory or alias: `scripts/pull.sh games video`). A missing one is cloned; one on a
clean `main` is fast-forwarded; anything else (another branch, uncommitted changes,
unpushed or diverged commits on `main`) is fetched and left alone, with the reason in its
summary line. A local branch whose remote is gone, because its pull request was merged,
is named, never deleted. `--quiet` prints only what changed and what was left. The
`gnome-ext:pull` skill runs it from any session and offers the fix for each repository it
left alone.

## Releases

A release is a pushed tag. In an extension, `git tag -a v1.1 -m "Name 1.1"` on the merged
`main` and `git push origin v1.1`: its `Release` workflow (`template/.github/workflows/release.yml`)
checks the tag against `version-name` in `src/metadata.json`, runs `make check`, packs the
zip with `./scripts/dev.sh pack`, and publishes the GitHub release with the zip and notes
listing the pull requests merged since the last release (`feat/` as Added, `fix/` as
Fixed). A tag with a suffix (`v1.1-beta.1`) is a prerelease. The GitHub releases are the
changelog. Uploading the zip to extensions.gnome.org is the owner's.

Tags are permanent: `scripts/protect-tags.sh` gives each extension a ruleset that refuses
moving or deleting a `v*` tag, for everyone. A wrong release is followed by the next
version, never retagged. `scripts/releases.sh` (the `gnome-ext:releases` skill) shows every
extension's version, last tag, unreleased pull requests, CI, last release run and
extensions.gnome.org version, and proposes the next version; `gnome-ext:release` cuts one,
only when the owner says so.

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

Add it to `extensions.json` (a kit pull request), create its repository inside this
folder, then `scripts/sync.sh <name>`, add the pointer
line to the top of its `CLAUDE.md`, give it a `make check`, and run the
`gnome-ext:doctor` skill in it: that walks the rest (CI, settings, protection).

## Not done yet

The extensions' development scripts began as one and have drifted apart: five copies of
`./scripts/nested.sh`, `./scripts/nested_driver.py`, `./scripts/dev-extension.js` and
`./scripts/dev.sh`, each with its own fixes. Converging them into `template/`, with what
really differs per extension moved into a small configuration file, is the next step,
after each extension's instructions have been audited.
