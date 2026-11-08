#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

# Back to the committed baseline: some-library 1.1.3, some-other-library 2.0.1,
# example-project pinned to @demo/some-library@1.1.3.
git checkout -- \
  example-project/package.json \
  some-library/package.json \
  some-other-library/package.json

docker compose down -v
docker compose up -d

for dir in example-project some-library some-other-library enforce-pnpm; do
  rm -rf "$dir/node_modules" "$dir/package-lock.json" "$dir/pnpm-lock.yaml"
done
rm -f example-project/pnpm-workspace.yaml

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

(cd some-library && npm publish --registry http://localhost:4873)
(cd some-other-library && npm publish --registry http://localhost:4873)
