#!/usr/bin/env bash
# Once per machine: makes the kit's gnome-ext plugin available to Claude Code.
#
#   scripts/setup.sh
#
# Registers this folder as the `gnome-extensions` plugin marketplace (a directory source,
# so skills are read from here live and a pull is all an update takes), installs the
# `gnome-ext` plugin, and leaves it switched off at user level: each extension's
# .claude/settings.json switches it on (`enabledPlugins`), so it is there in the
# extensions and nowhere else. Safe to run again.

set -euo pipefail

kit=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
claude=$(type -P claude || true)
[ -n "$claude" ] || claude=$HOME/.local/bin/claude
if [ ! -x "$claude" ]; then
    echo "setup.sh: Claude Code (claude) is not installed" >&2
    exit 1
fi

if "$claude" plugin marketplace list 2>/dev/null | grep -q 'gnome-extensions'; then
    echo "Marketplace gnome-extensions: already registered"
else
    "$claude" plugin marketplace add "$kit"
fi

if "$claude" plugin list 2>/dev/null | grep -q 'gnome-ext@gnome-extensions'; then
    echo "Plugin gnome-ext: already installed"
else
    "$claude" plugin install gnome-ext@gnome-extensions --scope user
fi

# Off at user level; the extensions' project settings turn it on.
"$claude" plugin disable gnome-ext@gnome-extensions --scope user >/dev/null 2>&1 || true

echo "Done. The gnome-ext skills load in sessions started in an extension beside the kit."
