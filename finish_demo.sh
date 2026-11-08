#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

# Undo prepare_demo.sh: put the user config back first, so a later failure
# does not leave the empty demo file in place.
npmrc="${HOME}/.npmrc"
backup="${HOME}/.npmrc.supply-chain-demo-backup"
absent="${HOME}/.npmrc.supply-chain-demo-was-absent"

if [[ -e "$backup" ]]; then
  mv "$backup" "$npmrc"
  rm -f "$absent"
  echo "Restored ${npmrc} from the demo backup."
elif [[ -e "$absent" ]]; then
  rm -f "$npmrc" "$absent"
  echo "Removed the empty demo ${npmrc}. There was no file to restore."
else
  echo "No demo backup at ${backup}. Leaving ${npmrc} untouched."
fi

restore_paths=(
  attack/app/package.json
  attack/library/package.json
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

for dir in \
  attack/app \
  attack/library \
  pnpm-scripts/app \
  pnpm-scripts/library \
  pnpm-release-age/app \
  pnpm-release-age/library \
  enforce-pnpm/app
do
  rm -rf "$dir/node_modules" "$dir/package-lock.json" "$dir/pnpm-lock.yaml"
done
rm -f attack/app/pnpm-workspace.yaml
