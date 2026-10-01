---
name: doctor
description: Audit one GNOME Shell extension repository against the GNOME-EXTENSIONS kit's standard and bring it up to it - CLAUDE.md checked against the code and trimmed to 200 lines, area rules split out, what the kit already says removed, make check and CI, settings.json hooks and plugin, the kit pointer line, repository settings and branch protection - landed as one pull request. Use when asked to doctor, audit or onboard an extension.
argument-hint: "[path to the extension repository; default the current one]"
---

Repository: $ARGUMENTS (nothing given: the current one)

The goal is a repository whose instructions are true, short and not repeated from the kit,
and whose `main` takes changes only through a green `make check`. Work through every step;
the report at the end says what each found.

## 0. Before anything

- Read the kit: its CLAUDE.md, every file in its `.claude/rules/`, and this plugin's
  `nested-shell` skill. The kit is the folder above the repository (or the cache path
  `.claude/kit.sh` prints). What they say is what the repository must **not** repeat.
- `git status` clean, on `main`, pulled. `gh issue create` an issue: "Adopt the
  GNOME-EXTENSIONS kit: true and short instructions, make check in CI, protected main",
  and a branch `chore/kit-doctor`.
- Do not start a nested shell for this unless a claim cannot be checked any other way;
  if you must, use `--clean` and `stop` it. Never touch another repository.

## 1. Every claim checked against the code

Read the repository's CLAUDE.md, `.claude/skills/*/SKILL.md`, `.claude/commands/*.md`,
`README.md` and `docs/*.md` line by line, and check each concrete claim:

- every path, file, script, make target, `nested.sh`/`dev.sh` subcommand and flag named
  exists and does what is said (`make help`, `./scripts/dev.sh help`,
  `./scripts/nested.sh help`, `grep`);
- every settings key named exists in `src/schemas/*.gschema.xml`, with the default said;
- every function, class, constant and module named exists where it is said to be;
- version claims match `src/metadata.json` (`shell-version`, `version-name`, `uuid`);
- every private shell API reach in `src/` (an underscore member of a shell object, an
  unexported class reached through a prototype) is listed where the repository lists them.

Fix what is wrong in the same pull request; where the code and the doc disagree and it is
not clear which is right, leave both and list it for the user.

## 2. Remove what the kit says

Delete from the repository's files whatever the kit's CLAUDE.md or rules already say, or
the `gnome-ext:nested-shell` skill already covers (the generic nested-shell loop, `do`
steps, dconf sharing, St CSS limits, module caching, reload and UUID traps, check the
logs, never hardcode the path, accent and em rules, the landing loop). Keep a line only if
it adds something true of this extension alone (its own measurement, its own coordinate,
its own exception to a rule). A trap this repository learned that is true of every
extension, and that the kit lacks, goes in the report for the kit, not here.

## 3. CLAUDE.md at most 200 lines, rules split out

- The **first line after the title** is the kit pointer, copied from
  `template/CLAUDE.pointer.md` in the kit.
- CLAUDE.md keeps: what the extension is (UUID, what it does, versions), its layout, how
  its parts fit, its design rules and the traps that are its own, its `make check` and
  anything the landing loop needs that is particular to it.
- Material that matters only while one area's files are open moves to
  `.claude/rules/<area>.md` with `paths:` frontmatter naming those files (e.g. the
  scanner's `src/backend/**`, the shaders' `src/lib/layers/**`, a VLC remote's
  `src/lib/vlc*.js`). A nested `CLAUDE.md` deeper in the tree (`src/backend/CLAUDE.md`)
  may stay where it already is, under the same rules.
- `wc -l CLAUDE.md` ≤ 200.

## 4. The repository's skills and commands

- `.claude/skills/drive-extension/SKILL.md` keeps only what is this extension's: what
  it looks like on screen and where (coordinates, sizes), its own `nested.sh` commands and
  flags, its fixtures (a player, a pad, demo data), what must never be pressed, how its
  README screenshots are taken. It opens by saying to read `gnome-ext:nested-shell` first,
  and repeats nothing from it.
- `.claude/commands/*.md` stay, checked against the code in step 1.

## 5. `make check` and CI

- `make check` exists and runs everything that needs no shell: `make lint` at least;
  `glib-compile-schemas --strict --dry-run src/schemas` (add it if missing, through
  `./scripts/dev.sh`); and what the repository already has (imports, parsers, assets,
  shader compiles, Python tests). It passes locally.
- It must pass in CI's Arch container with no display and no GPU: anything that needs
  either stays out of `make check` (a separate target), not skipped silently.
- It never touches the user's own files: a check that imports or runs a scanner (or any
  module that creates `~/.cache/<name>` or reads `~/.config` at import) runs with `HOME`
  (and the `XDG_*_HOME` it would use) pointed at a scratch directory, and offline.
- Packages beyond the template's base (`./.github/ci-packages`, one Arch package per line:
  `glslang`, `python-gobject`, `libadwaita`, …) are what `make check` needs and the base
  lacks.
- The repository's `.gitignore` ignores none of the files the sync writes:
  `git check-ignore -v --no-index .claude/settings.json .claude/kit.sh .github/workflows/ci.yml`
  prints nothing (a repository that ignored all of `.claude/` would never commit them;
  ignore `.claude/worktrees/` or `.claude/settings.local.json` instead). `sync.sh` refuses
  such a repository.
- Run the kit's `scripts/sync.sh <this repository>`. It copies
  `.github/workflows/ci.yml`, `.github/pull_request_template.md`, `.claude/kit.sh` and
  `eslint.config.mjs`, and merges the kit's hook and plugin into `.claude/settings.json`,
  keeping the SessionEnd hook. Review its diff; then `sync.sh --check <repo>` is clean.
- `npm ci` works (`package-lock.json` committed and current).

## 6. Land it

`make check`, commit (subject says what is now true), push, open the pull request
"Fixes #N" with what was removed, moved and corrected, and how it was verified. Wait for
the `make check` job to go green; fix what it finds. Then
`gh pr merge --squash --delete-branch`, and check main's run.

## 7. Repository settings and protection

Only after the merge, so the `make check` check has run on `main`:

```bash
R=Jackicus/<repo>
gh api -X PATCH repos/$R -F allow_squash_merge=true -F allow_merge_commit=false \
  -F allow_rebase_merge=false -F delete_branch_on_merge=true >/dev/null
gh api -X PUT repos/$R/branches/main/protection --input - <<'EOF'
{"required_status_checks": {"strict": false, "contexts": ["make check"]},
 "enforce_admins": true, "required_pull_request_reviews": null, "restrictions": null,
 "allow_force_pushes": false, "allow_deletions": false}
EOF
gh api repos/$R/branches/main/protection --jq '.required_status_checks.contexts, .enforce_admins.enabled'
```

## 8. Report

Under 300 words: the PR and its CI, `wc -l` of CLAUDE.md before and after, the rules files
made, claims found wrong and fixed, claims left for the user to decide, shared knowledge
the kit should take (quote the line), and the protection result.
