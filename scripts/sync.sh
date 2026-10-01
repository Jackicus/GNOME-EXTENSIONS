#!/usr/bin/env bash
# Copies the kit's per-repository files into the extensions beside it.
#
#   scripts/sync.sh [--check] [REPO...]
#
# REPO is a directory beside the kit (GNOME-Media-Controls) or a path; by default every
# directory beside the kit that is a git repository with a src/metadata.json. For each:
#
#   template/.github/workflows/ci.yml          copied
#   template/.github/pull_request_template.md  copied
#   template/.claude/kit.sh                    copied, executable
#   template/eslint.config.mjs                 copied
#   template/.claude/settings.json             merged into the repository's own: the
#                                              SessionStart hook added once, the
#                                              marketplace and plugin set, everything
#                                              else (the SessionEnd hook) kept
#
# and its CLAUDE.md is checked for the kit pointer line (template/CLAUDE.pointer.md),
# which is written by hand. Nothing is committed: each repository lands the result
# through its own pull request. A repository whose .gitignore ignores any of these files
# is refused, since the synced copy would never be committed.
#
# --check changes nothing, lists what differs, and exits 1 if anything does.

set -euo pipefail

kit=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
template=$kit/template
check=0
repos=()

for arg in "$@"; do
    case $arg in
        --check) check=1 ;;
        -h | --help) sed -n '2,24p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
        -*) echo "sync.sh: unknown option $arg" >&2; exit 2 ;;
        *) repos+=("$arg") ;;
    esac
done

if [ ${#repos[@]} -eq 0 ]; then
    for d in "$kit"/*/; do
        d=${d%/}
        [ -d "$d/.git" ] && [ -f "$d/src/metadata.json" ] && repos+=("$d")
    done
fi

copies=(
    .github/workflows/ci.yml
    .github/pull_request_template.md
    .claude/kit.sh
    eslint.config.mjs
)
pointer=$(cat "$template/CLAUDE.pointer.md")
status=0

# Prints the repository's settings.json with the template merged in.
merged_settings() {
    python3 - "$1" "$template/.claude/settings.json" <<'EOF'
import json, os, sys

path, template_path = sys.argv[1], sys.argv[2]
settings = {}
if os.path.exists(path):
    with open(path) as f:
        settings = json.load(f)
with open(template_path) as f:
    template = json.load(f)

hooks = settings.setdefault('hooks', {})
for event, groups in template.get('hooks', {}).items():
    have = hooks.setdefault(event, [])
    commands = {h.get('command') for g in have for h in g.get('hooks', [])}
    for group in groups:
        if not any(h.get('command') in commands for h in group.get('hooks', [])):
            have.append(group)
for key in ('extraKnownMarketplaces', 'enabledPlugins'):
    settings.setdefault(key, {}).update(template.get(key, {}))

print(json.dumps(settings, indent=2, ensure_ascii=False))
EOF
}

for repo in "${repos[@]}"; do
    [ -d "$repo" ] || repo=$kit/$repo
    if [ ! -d "$repo/.git" ]; then
        echo "sync.sh: $repo is not a git repository" >&2
        status=1
        continue
    fi
    name=$(basename "$repo")
    changed=()

    # A synced file the repository's .gitignore ignores would never be committed.
    ignored=()
    for f in "${copies[@]}" .claude/settings.json; do
        git -C "$repo" check-ignore -q --no-index "$f" && ignored+=("$f")
    done
    if [ ${#ignored[@]} -ne 0 ]; then
        echo "$name: .gitignore ignores ${ignored[*]}: un-ignore them (ignore .claude/worktrees/ or .claude/settings.local.json instead); not synced" >&2
        status=1
        continue
    fi

    for f in "${copies[@]}"; do
        if ! cmp -s "$template/$f" "$repo/$f"; then
            changed+=("$f")
            if [ $check -eq 0 ]; then
                mkdir -p "$(dirname "$repo/$f")"
                cp "$template/$f" "$repo/$f"
            fi
        fi
    done
    if [ -f "$repo/.claude/kit.sh" ] && [ ! -x "$repo/.claude/kit.sh" ]; then
        changed+=(".claude/kit.sh (mode)")
    fi
    [ $check -eq 0 ] && [ -f "$repo/.claude/kit.sh" ] && chmod +x "$repo/.claude/kit.sh"

    want=$(merged_settings "$repo/.claude/settings.json")
    have=$(cat "$repo/.claude/settings.json" 2>/dev/null || true)
    if [ "$want" != "$have" ]; then
        changed+=(.claude/settings.json)
        if [ $check -eq 0 ]; then
            mkdir -p "$repo/.claude"
            printf '%s\n' "$want" > "$repo/.claude/settings.json"
        fi
    fi

    missing_pointer=0
    grep -qF -- "$pointer" "$repo/CLAUDE.md" 2>/dev/null || missing_pointer=1

    if [ $missing_pointer -eq 1 ]; then
        echo "$name: CLAUDE.md lacks the kit pointer line (template/CLAUDE.pointer.md): add it by hand"
        [ $check -eq 1 ] && status=1
    fi
    if [ ${#changed[@]} -eq 0 ]; then
        echo "$name: up to date"
    else
        [ $check -eq 1 ] && verb=differs || verb=updated
        for c in "${changed[@]}"; do
            echo "$name: $verb: $c"
        done
        [ $check -eq 1 ] && status=1
    fi
done

exit $status
