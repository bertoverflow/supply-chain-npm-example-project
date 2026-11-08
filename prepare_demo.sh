#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

# Back to the committed baseline, once these files are tracked.
# Attack: some-library 1.1.3, victim pinned to 1.1.3.
# pnpm scripts: postinstall-library 1.0.0, hook already in package.json.
# Release age: cooldown-library 1.0.0, victim gate set to 0.
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
docker compose up -d

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
(cd pnpm-scripts/library && npm publish --registry http://localhost:4873)
(cd pnpm-release-age/library && npm publish --registry http://localhost:4873)
