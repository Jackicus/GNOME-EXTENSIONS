---
name: screenshots
description: Take, check and commit the screenshots a GNOME Shell extension publishes - the README's docs/screenshots/ and the images for extensions.gnome.org - in the nested shell over stand-in data only, in both colour schemes, shrunk, stripped and checked for anything personal before they go into a public repository. Use whenever published screenshots are retaken, added or asked for, or a visible change makes the existing ones out of date.
argument-hint: "[which shots: all, or names such as pop-up, preferences]"
---

Shots: $ARGUMENTS (nothing given: every image the README and docs link)

The repositories are public and a screenshot is the easiest place to leak: AI Usage's
first shots carried the owner's live account figures and home path, because its shot
script used the real `HOME`, `PATH` and logins. A published shot shows **stand-in data
only**: no real home path, user name, e-mail, account, token, live figure, library,
wallpaper or file of the user's, and nothing fetched from the network.

## 1. Where the stand-ins come from

Read the repository's drive-extension skill (its "Screenshots" section) and CLAUDE.md
first. They name the stand-ins and the formats; what the repositories use today:

- **Games and Video Library**: `./scripts/nested.sh start --clean --demo`, the invented
  library `./scripts/demo_library.py` draws. Full-screen shots as JPEG, windows as PNG.
- **Media Controls**: `--clean` over the Big Buck Bunny demo clip (`make demo-clip`,
  credited in the README), played with `./scripts/nested.sh player`.
- **Wallpaper FX**: `--clean`, whose base is GNOME's default wallpaper; JPEG patterns at
  the sizes its drive skill gives, `prefs.png` for the preferences.
- **AI Usage**: `./scripts/dev.sh shots [--light]`, a private user and mount namespace
  with stand-in CLIs on `/usr/bin`, stand-in logins in a scratch `HOME` and invented
  figures from `./scripts/stand-in-http.js`.

If the repository has no stand-in for what a shot needs, make one (invented data,
committed beside the others) before shooting; never shoot the real thing and blur it.

## 2. Shoot

With `gnome-ext:nested-shell`, `--clean` always: the stock look, the default wallpaper,
the repository's own size (1600x900 unless its drive skill says otherwise), no other
extensions. Dark first, then light where the README shows both. Work in progress goes to
the scratchpad; only the final files go to `docs/screenshots/`, under the names the README
already links (renaming one breaks the links on extensions.gnome.org's copy of the README
too). Crop the screencast indicator out of every kept shot.

## 3. Check every file before it is committed

1. **Look at it** with the Read tool: the change is there, nothing clipped, overlapping
   or ellipsized, covers and icons rather than placeholders, both schemes right.
2. **Personal data in the picture**: no path under `/home/`, no user or host name, no
   e-mail, no account or plan name that is the owner's, no real titles, figures or
   files. Read every line of text in the shot.
3. **Shrink and strip**: `oxipng --opt 4 --strip safe docs/screenshots/*.png`; a JPEG is
   written from the PNG with `magick in.png -strip -quality 90 out.jpg`.
4. **Metadata and bytes**: `grep -c -a -E 'tEXt|iTXt|zTXt|Exif' docs/screenshots/*` prints
   0 for each, and `grep -l -a -E "/home/|$(id -un)|$(git config user.email)"
   docs/screenshots/*` prints nothing.
5. **Alt text and captions**: the README's alt text says what the shot shows, with the
   same stand-in values (a path in the shot is the path in the alt text), and no personal
   detail. If what a shot shows changed, its caption changes with it.

## 4. Fix the tooling, not just the picture

A leak found in a shot is a bug in how shots are taken: fix the script or the stand-ins
so the next retake cannot repeat it, and say how in the drive skill. Old shots stay in
git history; tell the owner, who decides whether to rewrite it.

## 5. Land

Through the repository's loop (issue, branch, `make check`, pull request with the shots
listed, green CI, squash merge). Never commit a shot of the real session, and never a
work-in-progress shot.
