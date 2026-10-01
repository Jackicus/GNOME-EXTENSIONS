---
name: release
description: Release a GNOME Shell extension - set version-name in metadata.json, check, pack the extensions.gnome.org zip, tag, and publish a GitHub release with the zip attached, then hand the zip to the owner for the extensions.gnome.org upload. Only when the owner has said to release.
disable-model-invocation: true
argument-hint: "[version-name, e.g. 1.1; or nothing to propose one]"
---

Release: $ARGUMENTS

An agent carries a release out end to end once the owner has said to release, including
the tag and the GitHub release. The upload to extensions.gnome.org is the owner's: it needs
their account there, and its review can take days. The tag is the irreversible step: once
it is pushed and anyone has installed the zip, it is never moved or deleted; cut a new
version instead.

1. `main` is green in CI, the working tree is clean and on `main`, pulled.
   **Run `gnome-ext:ego-review` first** and stop on any blocker it leaves: a release that
   extensions.gnome.org would reject is not cut. Report its findings with the hand-over.
2. **The version.** extensions.gnome.org numbers uploads itself (`version`, an integer);
   never set `version` in `metadata.json`. What is set is `version-name`, the one people
   read: **patch** (1.0 → 1.0.1) for fixes alone, **minor** (→ 1.1) when a feature was
   added, **major** (→ 2.0) for a break. List the commits since the last tag
   (`git log --oneline $(git describe --tags --abbrev=0 2>/dev/null)..` or all of them for
   the first release) and propose the number if none was given.
3. **Shell versions.** `shell-version` lists only versions the extension has been booted
   on. Do not add one here that has not been.
4. On a branch `release/<version-name>`: set `version-name` in `src/metadata.json`; update
   the README or `docs/` where they name the version or show screenshots that changed
   (retake those with `gnome-ext:nested-shell` under `--clean`). `make check`.
5. Pack: `./scripts/dev.sh pack` (Wallpaper FX: `make zip`). It writes
   `dist/<uuid>.shell-extension.zip`, after `glib-compile-schemas --strict --dry-run`.
   List the zip (`unzip -l`) and check it holds `src/`'s files and `LICENSE` and nothing
   else: no `node_modules`, no `.claude`, no compiled schema the shell would compile itself,
   no development entry point.
6. Pull request "Release <version-name>", CI green, squash merge, then on the merged `main`:
   `git tag -a v<version-name> -m "<Name> <version-name>"` and `git push origin
   v<version-name>`.
7. Pack again from the tagged `main` and `gh release create v<version-name>
   dist/<uuid>.shell-extension.zip --title "<Name> <version-name>" --notes "…"`: a short
   paragraph and a list of what changed for users, from the commits. **This is the
   release.**
8. Hand over: the absolute path of the zip, the GitHub release URL, and the upload step
   for the owner (https://extensions.gnome.org/upload/, signed in as the extension's
   owner). If `docs/publishing.md` lists review-guideline checks, say which were walked.
