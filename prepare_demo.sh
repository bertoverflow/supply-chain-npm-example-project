#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

# The demo must not inherit ignore-scripts, min-release-age, or anything else
# from the user config. The original file is moved aside, never copied into
# this repo. finish_demo.sh puts it back. A second prepare leaves the backup
# where it is.
npmrc="${HOME}/.npmrc"
backup="${HOME}/.npmrc.supply-chain-demo-backup"
absent="${HOME}/.npmrc.supply-chain-demo-was-absent"

if [[ -e "$backup" || -e "$absent" ]]; then
  if [[ -s "$npmrc" ]]; then
    echo "Refusing to replace ${npmrc}: a demo backup already exists and the current file is not empty." >&2
    echo "Run ./finish_demo.sh to restore it, or remove the backup if you restored the file yourself." >&2
    exit 1
  fi
  : >"$npmrc"
  echo "Demo ${npmrc} is already in place. Backup left untouched."
else
  if [[ -e "$npmrc" ]]; then
    mv "$npmrc" "$backup"
    echo "Backed up ${npmrc} to ${backup}."
  else
    : >"$absent"
    echo "No ${npmrc} to back up. ${absent} records that."
  fi
  : >"$npmrc"
  echo "Replaced ${npmrc} with an empty file."
fi

# Back to the committed baseline, once these files are tracked.
# Attack: some-library 1.1.3, victim pinned to 1.1.3.
# Attack, victim only: text-utils 1.1.3 and 1.1.4, victim pinned to 1.1.3.
# pnpm scripts: postinstall-library 1.0.0, hook already in package.json.
# Release age: cooldown-library 1.0.0, victim gate set to 0.
restore_paths=(
  attack/app/package.json
  attack/library/package.json
  attack-victim/app/package.json
  pnpm-scripts/app/package.json
  pnpm-scripts/app/pnpm-workspace.yaml
  pnpm-scripts/library/package.json
  pnpm-release-age/app/package.json
  pnpm-release-age/app/pnpm-workspace.yaml
  pnpm-release-age/library/package.json
)
tracked=()
for path in "${restore_paths[@]}"; do
  if git ls-files --error-unmatch "$path" >/dev/null 2>&1; then
    tracked+=("$path")
  fi
done
if ((${#tracked[@]} > 0)); then
  git checkout -- "${tracked[@]}"
fi

docker compose down -v
docker compose up -d

for dir in \
  attack/app \
  attack/library \
  attack-victim/app \
  pnpm-scripts/app \
  pnpm-scripts/library \
  pnpm-release-age/app \
  pnpm-release-age/library \
  enforce-pnpm/app
do
  rm -rf "$dir/node_modules" "$dir/package-lock.json" "$dir/pnpm-lock.yaml"
done
rm -f attack/app/pnpm-workspace.yaml
rm -f /tmp/you-were-here.txt

ready=0
for _ in $(seq 1 30); do
  if curl -fsS http://localhost:4873/-/ping >/dev/null; then
    ready=1
    break
  fi
  sleep 1
done
if [[ "$ready" -ne 1 ]]; then
  echo "Verdaccio did not answer on http://localhost:4873" >&2
  exit 1
fi

(cd attack/library && npm publish --registry http://localhost:4873)
(cd attack-victim/library-1.1.3 && npm publish --registry http://localhost:4873)
(cd attack-victim/library-1.1.4 && npm publish --registry http://localhost:4873)
(cd pnpm-scripts/library && npm publish --registry http://localhost:4873)
(cd pnpm-release-age/library && npm publish --registry http://localhost:4873)
