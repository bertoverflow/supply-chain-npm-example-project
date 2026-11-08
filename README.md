# npm Supply Chain Security Demo

Live demos for the talk. Four projects, one local registry. The steps for each demo are in that folder.

- [Attack](attack/README.md). You publish `@demo/some-library` and install it in `attack/app`.
- [pnpm build scripts](pnpm-scripts/README.md). The dependency already has a postinstall hook. You only install.
- [pnpm minimum release age](pnpm-release-age/README.md). You publish one new version, then install twice.
- [Enforce pnpm](enforce-pnpm/README.md). `npm install` is refused. `pnpm install` works.

Every command block in those READMEs starts at this repo root.

## Prerequisites

- Docker
- Node.js from `.nvmrc`, and npm
- pnpm 12.18.0, for the build-scripts, release-age, and enforce-pnpm demos

Those apps set `packageManager` to `pnpm@12.18.0`. Corepack and pnpm switch to that version. The field is already in `package.json`, so Corepack does not add it on the first command. Run `pnpm --version` in each app once before the talk, so that download is already cached.

## Setup

`prepare_demo.sh` moves `$HOME/.npmrc` to `$HOME/.npmrc.supply-chain-demo-backup` and replaces it with an empty file, so `ignore-scripts` and `min-release-age` from your user config stay out of the demo. If there was no file, it records that and still writes the empty one. Running prepare again leaves the backup untouched. It also puts the package files back to the committed baseline, wipes `node_modules` and lockfiles, starts Verdaccio with an empty registry, and publishes the three baseline versions.

Baselines:

- `@demo/some-library@1.1.3` — no postinstall. The attack starts here.
- `@demo/postinstall-library@1.0.0` — postinstall already in the package. Echo, then `exit 1`.
- `@demo/cooldown-library@1.0.0` — no postinstall. Has to be at least 10 minutes old before the release-age demo.

```bash
./prepare_demo.sh
```

The registry is at `http://localhost:4873`. Publish uses a fake token in each library's `.npmrc`. Verdaccio allows anonymous publish of `@demo/*`. Each app's `.npmrc` sends `@demo` installs to that registry. The enforce-pnpm demo does not use the registry.

The commands below do not touch `$HOME/.npmrc`. From the repo root:

```bash
docker compose up -d
cd attack/library
npm publish --registry http://localhost:4873
cd ../../pnpm-scripts/library
npm publish --registry http://localhost:4873
cd ../../pnpm-release-age/library
npm publish --registry http://localhost:4873
cd ../..
```

## Finish

`finish_demo.sh` restores `$HOME/.npmrc` from the backup, puts the package files back to the baseline, stops Verdaccio, deletes its volume, and wipes `node_modules` and lockfiles.

```bash
./finish_demo.sh
```

If the backup is missing, the script leaves `$HOME/.npmrc` as it is.
