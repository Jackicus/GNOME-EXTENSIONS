#!/usr/bin/env bash
# What the kit's CI runs, and what to run before a kit pull request:
#
#   scripts/check.sh
#
# - shellcheck over the kit's scripts and the hook each extension gets;
# - every .json file parses;
# - every backticked kit path in CLAUDE.md, .claude/rules/, the kit's own skills and the
#   plugin's skills exists (one starting template/, plugin/, .claude-plugin/,
#   .claude/rules/, scripts/ or .github/; a .github/ path may be the template's).
#
# Prints `check: ok` when all pass.

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

fail=0

shellcheck_cmd=()
if command -v shellcheck >/dev/null; then
    shellcheck_cmd=(shellcheck)
elif command -v uvx >/dev/null; then
    shellcheck_cmd=(uvx --quiet --from shellcheck-py shellcheck)
else
    echo "check: shellcheck is not installed (pacman -S shellcheck, or uv for uvx)" >&2
    exit 1
fi
"${shellcheck_cmd[@]}" scripts/*.sh template/.claude/kit.sh || fail=1

while IFS= read -r -d '' f; do
    python3 -m json.tool "$f" >/dev/null || { echo "check: $f is not valid JSON" >&2; fail=1; }
done < <(find . -name '*.json' -not -path './.git/*' -not -path './GNOME-*' -print0)

python3 - <<'EOF' || fail=1
import glob, os, re, sys

docs = ['CLAUDE.md', *glob.glob('.claude/rules/*.md'), *glob.glob('.claude/skills/*/SKILL.md'),
        *glob.glob('plugin/skills/*/SKILL.md')]
prefixes = ('template/', 'plugin/', '.claude-plugin/', '.claude/rules/', 'scripts/', '.github/')
missing = []
for doc in docs:
    with open(doc) as f:
        text = f.read()
    for token in re.findall(r'`([^`\s]+)`', text):
        if not token.startswith(prefixes) or re.search(r'[<>*{}…$]', token):
            continue
        path = token.rstrip('/')
        candidates = [path]
        if path.startswith('.github/'):
            candidates.append(os.path.join('template', path))
        if not any(os.path.exists(c) for c in candidates):
            missing.append(f'{doc}: `{token}` does not exist')
for line in missing:
    print('check:', line, file=sys.stderr)
sys.exit(1 if missing else 0)
EOF

if [ $fail -ne 0 ]; then
    echo "check: FAILED" >&2
    exit 1
fi
echo "check: ok"
